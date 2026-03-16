const express = require('express');
const authController = require('../controllers/authController');
const protect = require('../middleware/protect');

const router = express.Router();

router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/forgot-password', authController.forgotPassword);
router.post('/verify-otp', authController.verifyOtp);
router.post('/reset-password', authController.resetPassword);
router.post('/refresh', authController.refreshToken);
router.get('/me', protect, authController.getMe);

module.exports = router;
