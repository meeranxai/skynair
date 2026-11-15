# Customize Firebase Email Templates

## Current Email Template

You're seeing the default Firebase email verification template with placeholders:
- `%APP_NAME%` - Will be replaced with your app name
- `%DISPLAY_NAME%` - Will be replaced with user's name

## How to Customize Email Templates

### Step 1: Go to Firebase Console
1. Open: https://console.firebase.google.com/
2. Select project: **studio-2145172646-5b4a0**
3. Go to: **Authentication** → **Templates** tab

### Step 2: Select Email Type
You'll see different email templates:
- **Email address verification**
- **Password reset**
- **Email address change**
- **SMS verification**

### Step 3: Customize Email Verification Template

Click on **Email address verification** and customize:

#### Sender Name
Change from: `not provided`
To: `G-Network Team` or `G-Network`

#### Subject
Change from: `Verify your email for %APP_NAME%`
To: `Verify your G-Network account`

#### Email Body
Change from default to something like:

```
Hello %DISPLAY_NAME%,

Welcome to G-Network! 🎉

Please verify your email address to activate your account and start connecting with others.

Click the link below to verify:
%LINK%

This link will expire in 24 hours.

If you didn't create a G-Network account, you can safely ignore this email.

Thanks,
The G-Network Team

---
Need help? Contact us at support@gnetwork.com
```

### Step 4: Customize Action URL (Optional)

By default, Firebase uses:
```
https://studio-2145172646-5b4a0.firebaseapp.com/__/auth/action
```

You can change this to your custom domain if you have one.

### Step 5: Save Changes

Click **Save** button.

## Recommended Email Templates

### Email Verification Template

**Sender Name**: `G-Network`

**Subject**: `Verify your G-Network account`

**Body**:
```
Hi %DISPLAY_NAME%,

Welcome to G-Network! 🚀

To complete your registration, please verify your email address by clicking the link below:

%LINK%

This verification link will expire in 24 hours.

If you didn't sign up for G-Network, please ignore this email.

Best regards,
The G-Network Team

---
Questions? Visit our help center or contact support.
```

### Password Reset Template

**Sender Name**: `G-Network`

**Subject**: `Reset your G-Network password`

**Body**:
```
Hi %DISPLAY_NAME%,

We received a request to reset your G-Network password.

Click the link below to create a new password:

%LINK%

This link will expire in 1 hour.

If you didn't request a password reset, please ignore this email. Your password will remain unchanged.

Best regards,
The G-Network Team

---
For security tips, visit our help center.
```

## Variables You Can Use

Firebase provides these variables:
- `%DISPLAY_NAME%` - User's display name
- `%EMAIL%` - User's email address
- `%LINK%` - Verification/reset link
- `%APP_NAME%` - Your app name (set in Firebase Console)

## Set App Name

To replace `%APP_NAME%` with "G-Network":

1. Go to: **Project Settings** (gear icon)
2. Under **General** tab
3. Find **Public-facing name**
4. Change to: `G-Network`
5. Click **Save**

## Email Styling (Advanced)

You can add HTML styling to make emails look better:

```html
<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
  <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center;">
    <h1 style="color: white; margin: 0;">G-Network</h1>
  </div>
  
  <div style="padding: 30px; background: #f9f9f9;">
    <h2>Hi %DISPLAY_NAME%,</h2>
    
    <p>Welcome to G-Network! 🎉</p>
    
    <p>Please verify your email address to activate your account:</p>
    
    <div style="text-align: center; margin: 30px 0;">
      <a href="%LINK%" style="background: #667eea; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">
        Verify Email
      </a>
    </div>
    
    <p style="color: #666; font-size: 14px;">
      This link will expire in 24 hours.
    </p>
    
    <p style="color: #666; font-size: 14px;">
      If you didn't create an account, you can ignore this email.
    </p>
  </div>
  
  <div style="padding: 20px; text-align: center; color: #999; font-size: 12px;">
    <p>© 2026 G-Network. All rights reserved.</p>
  </div>
</div>
```

## Testing Email Templates

After customizing:

1. Run your app
2. Try to signup with a new email
3. Check your inbox
4. Verify the email looks good
5. Click the verification link
6. Should redirect to app and verify email

## Common Issues

### Emails Going to Spam
- Add SPF/DKIM records (requires custom domain)
- Use a verified sender email
- Keep content professional

### Links Not Working
- Make sure Action URL is correct
- Check if link expired (24 hours)
- Try generating a new link

### Variables Not Replaced
- Make sure you saved the template
- Check spelling of variables
- Use exact variable names: `%DISPLAY_NAME%` not `%DISPLAYNAME%`

## Custom Domain (Optional)

For professional emails like `noreply@gnetwork.com`:

1. Buy a domain (e.g., gnetwork.com)
2. Go to Firebase Console → Authentication → Templates
3. Click **Customize domain**
4. Follow instructions to verify domain
5. Update email templates to use custom domain

## Summary

**Quick Fix:**
1. Firebase Console → Authentication → Templates
2. Edit "Email address verification"
3. Change sender name to "G-Network"
4. Customize subject and body
5. Save

**Result:**
- Professional looking emails
- Your branding
- Better user experience

---

**Current Status**: Default template (works fine)
**Recommended**: Customize for better branding
**Time**: 5-10 minutes to customize
