const express = require('express');
const authMiddleware = require('../middleware/protect');
const trackFollowController = require('../controllers/track_follow.controller');

const router = express.Router();

router.post('/start', authMiddleware, trackFollowController.startFollowing);
router.post('/:followId/sync', authMiddleware, trackFollowController.syncFollowPoints);
router.post('/:followId/deviation', authMiddleware, trackFollowController.recordDeviation);
router.post('/:followId/complete', authMiddleware, trackFollowController.completeFollowing);
router.get('/track/:trackId', authMiddleware, trackFollowController.getTrackFollowers);
router.get('/my', authMiddleware, trackFollowController.getMyFollowHistory);

module.exports = router;
