const express = require('express');
const trackController = require('../controllers/track.controller');
const authMiddleware = require('../middleware/protect');
const { uploadTrackFlagImage, uploadTrackPhoto } = require('../middleware/upload.middleware');

const router = express.Router();

router.post('/', authMiddleware, trackController.createTrack);
router.post('/draft', authMiddleware, trackController.createDraftTrack);
router.get('/my', authMiddleware, trackController.getMyTracks);
router.get('/nearby', authMiddleware, trackController.getNearbyTracks);

function handleTrackPhotoUpload(req, res, next) {
  uploadTrackPhoto.single('photo')(req, res, (err) => {
    if (err) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({ message: 'Photo is too large. Maximum size is 5MB.' });
      }
      return res.status(400).json({
        message: 'Could not upload photo. Please use a valid image file (JPG, PNG, or WebP).',
      });
    }
    next();
  });
}

router.post(
  '/:id/photos',
  authMiddleware,
  handleTrackPhotoUpload,
  trackController.postTrackPhoto,
);
router.delete('/:id/photos/:photoIndex', authMiddleware, trackController.deleteTrackPhoto);
router.post('/:id/flags', authMiddleware, trackController.postTrackFlag);
router.put('/:id/flags/:flagId', authMiddleware, trackController.putTrackFlag);
router.delete('/:id/flags/:flagId', authMiddleware, trackController.deleteTrackFlag);

router.get('/:id', authMiddleware, trackController.getTrackById);
router.put('/:id', authMiddleware, trackController.updateTrack);
router.delete('/:id', authMiddleware, trackController.deleteTrack);
router.post('/:id/like', authMiddleware, trackController.likeTrack);
router.post('/:id/save', authMiddleware, trackController.saveTrack);
router.post('/:id/flag', authMiddleware, trackController.addFlag);
router.post(
  '/:id/flag-image',
  authMiddleware,
  uploadTrackFlagImage.single('image'),
  trackController.uploadTrackFlagImage,
);
router.post('/:id/photo', authMiddleware, trackController.addPhoto);

module.exports = router;
