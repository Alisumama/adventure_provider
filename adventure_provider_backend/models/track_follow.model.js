const mongoose = require('mongoose');

const lineStringSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      enum: ['LineString'],
      default: 'LineString',
    },
    coordinates: {
      type: [[Number]],
      default: [],
      // GeoJSON LineString: [[lng, lat], ...]
    },
  },
  { _id: false }
);

const deviationPointSchema = new mongoose.Schema(
  {
    coordinates: {
      type: [Number],
      // [lng, lat]
    },
    timestamp: { type: Date },
    distanceFromTrack: { type: Number },
  },
  { _id: false }
);

const trackFollowSchema = new mongoose.Schema(
  {
    trackId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Track',
      required: [true, 'Track is required'],
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User is required'],
    },
    startedAt: { type: Date, default: Date.now },
    completedAt: { type: Date, default: null },
    isCompleted: { type: Boolean, default: false },
    totalDistance: { type: Number, default: 0 },
    duration: { type: Number, default: 0 },
    steps: { type: Number, default: 0 },
    calories: { type: Number, default: 0 },
    maxDeviation: { type: Number },
    deviationCount: { type: Number, default: 0 },
    followPath: lineStringSchema,
    deviationPoints: [deviationPointSchema],
    completionPercentage: {
      type: Number,
      default: 0,
      min: [0, 'completionPercentage must be at least 0'],
      max: [100, 'completionPercentage cannot exceed 100'],
    },
  },
  { timestamps: true }
);

trackFollowSchema.index({ trackId: 1, userId: 1 });

module.exports = mongoose.model('TrackFollow', trackFollowSchema);
