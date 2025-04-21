/*
=======================================================================================================================================
Utility: email_utils.js
=======================================================================================================================================
Purpose: Utility functions for sending emails and generating email templates
=======================================================================================================================================
*/

const { Resend } = require('resend');
require('dotenv').config();

// Initialize Resend with API key
const resend = new Resend(process.env.RESEND_API_KEY);

// Function to send verification email
async function sendVerificationEmail(email, name, verificationToken) {
  try {
    // Debug logs
    console.log('Attempting to send verification email to:', email);
    console.log('Using API key:', process.env.RESEND_API_KEY ? 'Present' : 'Missing');

    const verificationLink = `${process.env.FRONTEND_URL}/verify-email?token=${verificationToken}`;
    console.log('Verification link:', verificationLink);

    const data = await resend.emails.send({
      from: process.env.FROM_EMAIL || 'onboarding@resend.dev',  // Use the configured FROM_EMAIL or fallback to Resend's testing address
      to: email,
      subject: 'Verify Your SplitLeague Account',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 5px;">
          <h2 style="color: #1976d2;">Welcome to SplitLeague!</h2>
          <p>Hello ${name},</p>
          <p>Thank you for registering with SplitLeague. To complete your registration, please verify your email address by clicking the button below:</p>
          <div style="text-align: center; margin: 30px 0;">
            <a href="${verificationLink}" style="background-color: #1976d2; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; display: inline-block;">Verify Email Address</a>
          </div>
          <p>If the button doesn't work, you can also copy and paste the following link into your browser:</p>
          <p style="word-break: break-all; color: #1976d2;">${verificationLink}</p>
          <p>This link will expire in 24 hours.</p>
          <p>If you did not create an account with SplitLeague, please ignore this email.</p>
          <p>Best regards,<br>The SplitLeague Team</p>
        </div>
      `,
    });

    console.log('Resend API response:', data);
    return { success: true, data };
  } catch (error) {
    console.error('Detailed error sending verification email:', error);
    return { success: false, error: error.message };
  }
}

// Function to send password reset email
async function sendPasswordResetEmail(email, name, resetToken) {
  try {
    // Debug logs
    console.log('Attempting to send password reset email to:', email);
    console.log('Using API key:', process.env.RESEND_API_KEY ? 'Present' : 'Missing');

    // Create the reset link
    const resetLink = `${process.env.FRONTEND_URL}/reset-password?token=${resetToken}`;
    console.log('Reset link:', resetLink);

    // Send the email
    const data = await resend.emails.send({
      from: process.env.FROM_EMAIL || 'onboarding@resend.dev',  // Use the configured FROM_EMAIL or fallback to Resend's testing address
      to: email,
      subject: 'Reset Your SplitLeague Password',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 5px;">
          <h2 style="color: #1976d2;">Reset Your Password</h2>
          <p>Hello ${name},</p>
          <p>We received a request to reset your password for your SplitLeague account. Click the button below to reset your password:</p>
          <div style="text-align: center; margin: 30px 0;">
            <a href="${resetLink}" style="background-color: #1976d2; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; display: inline-block;">Reset Password</a>
          </div>
          <p>If the button doesn't work, you can also copy and paste the following link into your browser:</p>
          <p style="word-break: break-all; color: #1976d2;">${resetLink}</p>
          <p>This link will expire in 1 hour.</p>
          <p>If you did not request a password reset, please ignore this email or contact support if you have concerns.</p>
          <p>Best regards,<br>The SplitLeague Team</p>
        </div>
      `,
    });

    return { success: true, data };
  } catch (error) {
    console.error('Error sending password reset email:', error);
    return { success: false, error: error.message };
  }
}

// Function to send password change confirmation email
async function sendPasswordChangeConfirmationEmail(email, name) {
  try {
    // Send the email
    const data = await resend.emails.send({
      from: process.env.FROM_EMAIL || 'onboarding@resend.dev',  // Use the configured FROM_EMAIL or fallback to Resend's testing address
      to: email,
      subject: 'Your SplitLeague Password Has Been Changed',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 5px;">
          <h2 style="color: #1976d2;">Password Changed Successfully</h2>
          <p>Hello ${name},</p>
          <p>Your SplitLeague account password has been successfully changed.</p>
          <p>If you did not make this change, please contact our support team immediately.</p>
          <p>Best regards,<br>The SplitLeague Team</p>
        </div>
      `,
    });

    return { success: true, data };
  } catch (error) {
    console.error('Error sending password change confirmation email:', error);
    return { success: false, error: error.message };
  }
}

// Function to send email verification success email
async function sendVerificationSuccessEmail(email, name) {
  try {
    // Send the email
    const data = await resend.emails.send({
      from: process.env.FROM_EMAIL || 'onboarding@resend.dev',  // Use the configured FROM_EMAIL or fallback to Resend's testing address
      to: email,
      subject: 'Your SplitLeague Email Has Been Verified',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 5px;">
          <h2 style="color: #1976d2;">Email Verification Successful</h2>
          <p>Hello ${name},</p>
          <p>Your email address has been successfully verified. Thank you for completing this important step!</p>
          <p>You now have full access to all SplitLeague features.</p>
          <p>Best regards,<br>The SplitLeague Team</p>
        </div>
      `,
    });

    return { success: true, data };
  } catch (error) {
    console.error('Error sending verification success email:', error);
    return { success: false, error: error.message };
  }
}

// Generate a random token
function generateToken(length = 32) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let token = '';

  for (let i = 0; i < length; i++) {
    token += chars.charAt(Math.floor(Math.random() * chars.length));
  }

  return token;
}

module.exports = {
  sendVerificationEmail,
  sendPasswordResetEmail,
  sendPasswordChangeConfirmationEmail,
  sendVerificationSuccessEmail,
  generateToken
};

