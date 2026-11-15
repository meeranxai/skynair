// Supabase Edge Function for Content Moderation
// Deploy: supabase functions deploy moderate-content

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Restricted Keywords Database (sync with Flutter app)
const RESTRICTED_KEYWORDS = {
    scams: [
        'free money',
        'paisa double',
        'investment scam',
        'get rich quick',
        'easy money',
        'guaranteed profit',
        'no risk investment',
        'double your money',
        'paisa kamao',
        'ghar baithe kamao',
        'lottery winner',
        'prize money',
        'bank account hack',
        'credit card free',
        'loan without documents',
        'instant loan',
        'bitcoin scam',
        'crypto fraud',
    ],
    platform_integrity: [
        'follow for follow',
        'f4f',
        'follow back',
        'buy followers',
        'buy likes',
        'fake followers',
        'followers kharido',
        'likes kharido',
        'engagement pod',
        'sub4sub',
        'like4like',
        'comment4comment',
        'spam',
        'bot followers',
        'auto followers',
    ],
    hate_speech: [
        'hate',
        'kill',
        'terrorist',
        'bomb',
        'attack',
        'violence',
        'abuse',
        'harass',
        'bully',
        'threat',
        'racist',
        'sexist',
    ],
    adult_content: [
        'porn',
        'xxx',
        'adult content',
        'explicit',
        'nsfw',
        '18+',
        'sex',
        'nude',
    ],
    misinformation: [
        'fake news',
        'conspiracy',
        'hoax',
        'false information',
        'misleading',
        'propaganda',
        'jhooti khabar',
        'galat khabar',
    ],
    personal_info: [
        'phone number',
        'email address',
        'home address',
        'credit card',
        'password',
        'social security',
        'bank account number',
        'aadhar number',
        'cnic number',
    ],
}

interface ModerationResult {
    isClean: boolean
    violations: string[]
    restrictedWords: string[]
    severity: 'none' | 'medium' | 'high' | 'severe'
    message?: string
}

// Check content for violations
function moderateContent(content: string): ModerationResult {
    if (!content || content.trim().length === 0) {
        return {
            isClean: true,
            violations: [],
            restrictedWords: [],
            severity: 'none',
        }
    }

    const lowerContent = content.toLowerCase()
    const foundWords: string[] = []
    const categories: string[] = []

    // Check each category
    Object.entries(RESTRICTED_KEYWORDS).forEach(([category, keywords]) => {
        keywords.forEach((keyword) => {
            // Word boundary regex for accurate matching
            const pattern = new RegExp(`\\b${keyword}\\b`, 'i')
            if (pattern.test(lowerContent)) {
                foundWords.push(keyword)
                if (!categories.includes(category)) {
                    categories.push(category)
                }
            }
        })
    })

    // Determine severity
    let severity: 'none' | 'medium' | 'high' | 'severe' = 'none'
    if (foundWords.length > 0) {
        if (categories.includes('hate_speech') || categories.includes('adult_content')) {
            severity = 'severe'
        } else if (categories.includes('scams') || categories.includes('misinformation')) {
            severity = 'high'
        } else {
            severity = 'medium'
        }
    }

    return {
        isClean: foundWords.length === 0,
        violations: categories,
        restrictedWords: foundWords,
        severity,
        message: foundWords.length > 0
            ? 'Content contains restricted words and cannot be published.'
            : undefined,
    }
}

// Log moderation event to database
async function logModerationEvent(
    supabase: any,
    userId: string,
    content: string,
    result: ModerationResult
) {
    try {
        await supabase.from('moderation_logs').insert({
            user_id: userId,
            content_preview: content.substring(0, 200),
            violations: result.violations,
            restricted_words: result.restrictedWords,
            severity: result.severity,
            is_clean: result.isClean,
            created_at: new Date().toISOString(),
        })
    } catch (error) {
        console.error('Failed to log moderation event:', error)
    }
}

// Apply user strikes for severe violations
async function applyUserStrike(supabase: any, userId: string, severity: string) {
    if (severity === 'severe' || severity === 'high') {
        try {
            // Increment user strikes
            const { data: user } = await supabase
                .from('users')
                .select('moderation_strikes')
                .eq('uid', userId)
                .single()

            const currentStrikes = user?.moderation_strikes || 0
            const newStrikes = currentStrikes + (severity === 'severe' ? 2 : 1)

            await supabase
                .from('users')
                .update({
                    moderation_strikes: newStrikes,
                    last_violation_at: new Date().toISOString(),
                })
                .eq('uid', userId)

            // Auto-suspend if strikes >= 5
            if (newStrikes >= 5) {
                await supabase
                    .from('users')
                    .update({
                        is_suspended: true,
                        suspended_at: new Date().toISOString(),
                        suspension_reason: 'Multiple community guideline violations',
                    })
                    .eq('uid', userId)
            }
        } catch (error) {
            console.error('Failed to apply user strike:', error)
        }
    }
}

serve(async (req) => {
    try {
        // CORS headers
        if (req.method === 'OPTIONS') {
            return new Response('ok', {
                headers: {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'POST',
                    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
                },
            })
        }

        // Get request body
        const { content, userId, postType } = await req.json()

        if (!content) {
            return new Response(
                JSON.stringify({ error: 'Content is required' }),
                { status: 400, headers: { 'Content-Type': 'application/json' } }
            )
        }

        // Initialize Supabase client
        const supabaseClient = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_ANON_KEY') ?? '',
            {
                global: {
                    headers: { Authorization: req.headers.get('Authorization')! },
                },
            }
        )

        // Moderate content
        const result = moderateContent(content)

        // Log event if user ID provided
        if (userId) {
            await logModerationEvent(supabaseClient, userId, content, result)

            // Apply strikes for violations
            if (!result.isClean) {
                await applyUserStrike(supabaseClient, userId, result.severity)
            }
        }

        // Return result
        return new Response(
            JSON.stringify(result),
            {
                status: 200,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                },
            }
        )
    } catch (error) {
        console.error('Error in moderate-content function:', error)
        return new Response(
            JSON.stringify({ error: error.message }),
            {
                status: 500,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                },
            }
        )
    }
})
