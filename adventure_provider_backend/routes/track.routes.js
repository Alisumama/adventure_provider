const express = require('express');
const trackController = require('../controllers/track.controller');
const authMiddleware = require('../middleware/protect');

const router = express.Router();

router.post('/', authMiddleware, trackController.createTrack);
router.get('/my', authMiddleware, trackController.getMyTracks);
router.get('/nearby', authMiddleware, trackController.getNearbyTracks);
router.get('/:id', authMiddleware, trackController.getTrackById);
router.put('/:id', authMiddleware, trackController.updateTrack);
router.delete('/:id', authMiddleware, trackController.deleteTrack);
router.post('/:id/like', authMiddleware, trackController.likeTrack);
router.post('/:id/save', authMiddleware, trackController.saveTrack);
router.post('/:id/flag', authMiddleware, trackController.addFlag);
router.post('/:id/photo', authMiddleware, trackController.addPhoto);

module.exports = router;
