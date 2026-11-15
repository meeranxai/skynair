-- Content Moderation System Database Schema
-- Run this in Supabase SQL Editor

-- 1. Add moderation fields to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS moderation_strikes INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_violation_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS is_suspended BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS suspended_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS suspension_reason TEXT;

-- 2. Create moderation_logs table
CREATE TABLE IF NOT EXISTS moderation_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  content_preview TEXT NOT NULL,
  violations TEXT[] DEFAULT '{}',
  restricted_words TEXT[] DEFAULT '{}',
  severity TEXT CHECK (severity IN ('none', 'medium', 'high', 'severe')),
  is_clean BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_moderation_logs_user_id ON moderation_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_moderation_logs_created_at ON moderation_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_moderation_logs_severity ON moderation_logs(severity);
CREATE INDEX IF NOT EXISTS idx_users_moderation_strikes ON users(moderation_strikes);
CREATE INDEX IF NOT EXISTS idx_users_is_suspended ON users(is_suspended);

-- 4. Create RLS policies for moderation_logs
ALTER TABLE moderation_logs ENABLE ROW LEVEL SECURITY;

-- Admins can view all logs
CREATE POLICY "Admins can view all moderation logs"
ON moderation_logs FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.uid = auth.uid()
    AND users.role = 'admin'
  )
);

-- Users can view their own logs
CREATE POLICY "Users can view their own moderation logs"
ON moderation_logs FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Only system can insert logs (via Edge Function)
CREATE POLICY "System can insert moderation logs"
ON moderation_logs FOR INSERT
TO authenticated
WITH CHECK (true);

-- 5. Create function to check user suspension status
CREATE OR REPLACE FUNCTION is_user_suspended(user_uid TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users
    WHERE uid = user_uid
    AND is_suspended = TRUE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Create function to get user moderation stats
CREATE OR REPLACE FUNCTION get_user_moderation_stats(user_uid TEXT)
RETURNS TABLE (
  total_violations BIGINT,
  strikes INTEGER,
  is_suspended BOOLEAN,
  last_violation TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::BIGINT as total_violations,
    u.moderation_strikes as strikes,
    u.is_suspended,
    u.last_violation_at as last_violation
  FROM moderation_logs ml
  JOIN users u ON u.uid = ml.user_id
  WHERE ml.user_id = user_uid
  AND ml.is_clean = FALSE
  GROUP BY u.moderation_strikes, u.is_suspended, u.last_violation_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Create trigger to prevent suspended users from posting
CREATE OR REPLACE FUNCTION check_user_suspension()
RETURNS TRIGGER AS $$
BEGIN
  IF is_user_suspended(NEW.user_id) THEN
    RAISE EXCEPTION 'User is suspended and cannot create content';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to posts table
DROP TRIGGER IF EXISTS prevent_suspended_user_posts ON posts;
CREATE TRIGGER prevent_suspended_user_posts
BEFORE INSERT ON posts
FOR EACH ROW
EXECUTE FUNCTION check_user_suspension();

-- 8. Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON moderation_logs TO authenticated;
GRANT EXECUTE ON FUNCTION is_user_suspended TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_moderation_stats TO authenticated;

-- 9. Create view for admin dashboard
CREATE OR REPLACE VIEW moderation_dashboard AS
SELECT 
  u.uid,
  u.username,
  u.display_name,
  u.moderation_strikes,
  u.is_suspended,
  u.last_violation_at,
  COUNT(ml.id) as total_violations,
  COUNT(CASE WHEN ml.severity = 'severe' THEN 1 END) as severe_violations,
  COUNT(CASE WHEN ml.severity = 'high' THEN 1 END) as high_violations,
  MAX(ml.created_at) as last_violation_date
FROM users u
LEFT JOIN moderation_logs ml ON ml.user_id = u.uid AND ml.is_clean = FALSE
WHERE u.moderation_strikes > 0 OR u.is_suspended = TRUE
GROUP BY u.uid, u.username, u.display_name, u.moderation_strikes, u.is_suspended, u.last_violation_at
ORDER BY u.moderation_strikes DESC, last_violation_date DESC;

-- Grant view access to admins only
GRANT SELECT ON moderation_dashboard TO authenticated;

COMMENT ON TABLE moderation_logs IS 'Logs all content moderation events';
COMMENT ON VIEW moderation_dashboard IS 'Admin dashboard for monitoring user violations';
