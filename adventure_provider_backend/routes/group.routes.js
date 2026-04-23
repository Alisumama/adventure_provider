const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/protect');
const groupController = require('../controllers/group.controller');

router.post('/', authMiddleware, groupController.createGroup);
router.post('/join', authMiddleware, groupController.joinGroup);
router.get('/my', authMiddleware, groupController.getMyGroups);
router.get('/:id', authMiddleware, groupController.getGroupById);
router.get('/:id/live-sessions', authMiddleware, groupController.getGroupLiveSessions);
router.post('/:id/start-tracking', authMiddleware, groupController.startGroupTracking);
router.post('/:id/stop-tracking', authMiddleware, groupController.stopGroupTracking);
router.delete('/:id/leave', authMiddleware, groupController.leaveGroup);
router.post('/:id/location', authMiddleware, groupController.updateMemberLocation);

module.exports = router;
