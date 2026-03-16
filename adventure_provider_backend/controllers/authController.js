const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const transporter = require('../config/transporter');

const JWT_SECRET = process.env.JWT_SECRET || 'jwt-secret-change-in-production';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'jwt-refresh-secret-change-in-production';

/**
 * Returns accessToken (7d) and refreshToken (30d) for the given userId.
 */
function generateTokens(userId) {
  const accessToken = jwt.sign(
    { id: userId },
    JWT_SECRET,
    { expiresIn: '7d' }
  );
  const refreshToken = jwt.sign(
    { id: userId },
    JWT_REFRESH_SECRET,
    { expiresIn: '30d' }
  );
  return { accessToken, refreshToken };
}

/**
 * POST /register
 */
async function register(req, res) {
  try {
    const { name, email, password, phone, emergencyContact } = req.body;

    const existing = await User.findOne({ email: email?.toLowerCase?.() || email });
    if (existing) {
      return res.status(400).json({ message: 'Email already registered' });
    }

    const user = await User.create({
      name,
      email,
      password,
      phone: phone ?? null,
      emergencyContact: emergencyContact || { name: '', phone: '', relation: '' },
    });

    const { accessToken, refreshToken } = generateTokens(user._id);
    const userObj = user.toJSON ? user.toJSON() : user.toObject();

    return res.status(201).json({
      user: userObj,
      accessToken,
      refreshToken,
    });
  } catch (err) {
    console.error('Register error:', err);
    const message = err.message || 'Registration failed';
    return res.status(500).json({ message });
  }
}

/**
 * POST /login
 */
async function login(req, res) {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email: email?.toLowerCase?.() || email })
      .select('+password +resetOtp +resetOtpExpiry');
    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }
    if (user.isActive === false) {
      return res.status(403).json({ message: 'Account deactivated' });
    }

    const { accessToken, refreshToken } = generateTokens(user._id);
    const userObj = user.toJSON ? user.toJSON() : user.toObject();

    return res.status(200).json({
      user: userObj,
      accessToken,
      refreshToken,
    });
  } catch (err) {
    return res.status(500).json({ message: err.message || 'Login failed' });
  }
}

/**
 * POST /resetPassword
 * Body: email, otp, newPassword
 */
async function resetPassword(req, res) {
  try {
    const { email, otp, newPassword } = req.body;

    const user = await User.findOne({ email: email?.toLowerCase?.() || email })
      .select('+resetOtp +resetOtpExpiry +password');
    if (!user) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }
    if (!user.resetOtp || user.resetOtp !== otp) {
      return res.status(400).json({ message: 'Invalid or expired OTP' });
    }
    if (!user.resetOtpExpiry || new Date() > user.resetOtpExpiry) {
      return res.status(400).json({ message: 'Invalid or expired OTP' });
    }

    user.password = newPassword;
    user.resetOtp = null;
    user.resetOtpExpiry = null;
    await user.save();

    return res.status(200).json({ message: 'Password reset successful' });
  } catch (err) {
    return res.status(500).json({ message: err.message || 'Reset failed' });
  }
}

/**
 * POST /forgot-password
 * Body: email. Generates OTP, saves to user, sends email.
 */
async function forgotPassword(req, res) {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email: email?.toLowerCase?.() || email })
      .select('+resetOtp +resetOtpExpiry');
    if (!user) {
      return res.status(404).json({ message: 'No account with this email' });
    }
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    user.resetOtp = otp;
    user.resetOtpExpiry = new Date(Date.now() + 10 * 60 * 1000);
    await user.save({ validateBeforeSave: false });

    const from = process.env.EMAIL_FROM || 'Adventure Providers <noreply@example.com>';
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 24px; background: #f8f9fa; border-radius: 12px;">
        <h2 style="color: #1B4332; margin-bottom: 16px;">Adventure Providers</h2>
        <p style="color: #1A1A2E; margin-bottom: 24px;">Use this code to reset your password:</p>
        <p style="font-size: 28px; font-weight: bold; letter-spacing: 6px; color: #2D6A4F; background: #fff; padding: 16px; border-radius: 8px; text-align: center; margin-bottom: 24px;">${otp}</p>
        <p style="color: #6B7280; font-size: 14px;">This code expires in <strong>10 minutes</strong>. Do not share it with anyone.</p>
      </div>
    `;
    try {
      await transporter.sendMail({
        from,
        to: user.email,
        subject: 'Adventure Providers - Password Reset OTP',
        html,
      });
    } catch (emailErr) {
      user.resetOtp = null;
      user.resetOtpExpiry = null;
      await user.save({ validateBeforeSave: false });
      return res.status(500).json({ message: 'Failed to send email. Please try again.' });
    }
    return res.status(200).json({ message: 'OTP sent to your email' });
  } catch (err) {
    return res.status(500).json({ message: err.message || 'Request failed' });
  }
}

/**
 * POST /verify-otp
 * Body: email, otp. Validates OTP and expiry. Does not clear OTP (cleared on reset).
 */
async function verifyOtp(req, res) {
  try {
    const { email, otp } = req.body;
    const user = await User.findOne({ email: email?.toLowerCase?.() || email })
      .select('+resetOtp +resetOtpExpiry');
    if (!user) {
      return res.status(404).json({ message: 'No account with this email' });
    }
    if (user.resetOtp !== otp) {
      return res.status(400).json({ message: 'Invalid OTP' });
    }
    if (user.resetOtpExpiry < new Date()) {
      return res.status(400).json({ message: 'OTP expired' });
    }
    return res.status(200).json({ message: 'OTP verified' });
  } catch (err) {
    return res.status(500).json({ message: err.message || 'Verification failed' });
  }
}

/**
 * POST /refresh
 * Body: refreshToken. Returns new accessToken and refreshToken.
 */
async function refreshToken(req, res) {
  try {
    const { refreshToken: token } = req.body;
    if (!token) {
      return res.status(401).json({ message: 'Refresh token required' });
    }
    const decoded = jwt.verify(token, JWT_REFRESH_SECRET);
    const user = await User.findById(decoded.id);
    if (!user || user.isActive === false) {
      return res.status(401).json({ message: 'Invalid refresh token' });
    }
    const { accessToken, refreshToken } = generateTokens(user._id);
    return res.status(200).json({ accessToken, refreshToken });
  } catch (err) {
    return res.status(401).json({ message: 'Invalid refresh token' });
  }
}

/**
 * GET /me
 * Requires protect middleware to set req.user.
 */
function getMe(req, res) {
  const user = req.user.toJSON ? req.user.toJSON() : req.user.toObject();
  return res.status(200).json({ user });
}

module.exports = {
  register,
  login,
  forgotPassword,
  verifyOtp,
  resetPassword,
  refreshToken,
  getMe,
};
