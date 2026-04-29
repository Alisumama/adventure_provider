const mongoose = require('mongoose');

const pointSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point',
    },
    coordinates: {
      type: [Number],
      // GeoJSON Point: [longitude, latitude]
    },
  },
  { _id: false }
);

const memberSessionSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    joinedAt: {
      type: Date,
    },
    leftAt: {
      type: Date,
    },
    lastLocation: pointSchema,
    lastSeenAt: {
      type: Date,
    },
    isOnline: {
      type: Boolean,
      default: false,
    },
    locationPath: {
      type: [[Number]],
      default: [],
      // GeoJSON LineString coordinates: [[lng, lat], ...]
    },
    totalDistance: {
      type: Number,
      default: 0,
    },
  },
  { _id: false }
);

const liveSessionSchema = new mongoose.Schema(
  {
    groupId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Group',
      required: true,
    },
    startedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    trackId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Track',
      default: null,
    },
    startedAt: {
      type: Date,
      default: Date.now,
    },
    endedAt: {
      type: Date,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    memberSessions: [memberSessionSchema],
  },
  { timestamps: true }
);

liveSessionSchema.index({ groupId: 1, isActive: 1 });

module.exports = mongoose.model('LiveSession', liveSessionSchema);
