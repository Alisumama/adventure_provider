const express = require('express');
const authController = require('../controllers/authController');
const protect = require('../middleware/protect');
const {
  uploadProfileImage,
  uploadCoverImage,
} = require('../middleware/upload.middleware');

const router = express.Router();

router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/forgot-password', authController.forgotPassword);
router.post('/verify-otp', authController.verifyOtp);
router.post('/reset-password', authController.resetPassword);
router.post('/refresh', authController.refreshAccessToken);
router.get('/me', protect, authController.getMe);

// Profile
router.get('/profile', protect, authController.getProfile);
router.put('/profile', protect, authController.updateProfile);
router.put(
  '/profile/image',
  protect,
  uploadProfileImage.single('profileImage'),
  authController.updateProfileImage
);
router.put(
  '/profile/cover',
  protect,
  uploadCoverImage.single('coverImage'),
  authController.updateCoverImage
);
router.put('/change-password', protect, authController.changePassword);
router.delete('/account', protect, authController.deleteAccount);

module.exports = router;
