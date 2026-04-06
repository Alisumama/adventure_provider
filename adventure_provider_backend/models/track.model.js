const mongoose = require('mongoose');

const TRACK_TYPES = ['hiking', 'offroad', 'cycling', 'running'];
const DIFFICULTIES = ['easy', 'moderate', 'hard'];

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

const flagSchema = new mongoose.Schema(
  {
    type: { type: String, trim: true },
    title: { type: String, trim: true },
    description: { type: String, trim: true },
    photo: { type: String, trim: true },
    images: [{ type: String, trim: true }],
    location: pointSchema,
  },
  { _id: true }
);

const trackSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User is required'],
    },
    title: {
      type: String,
      required: [true, 'Title is required'],
      trim: true,
      maxlength: [100, 'Title cannot exceed 100 characters'],
    },
    description: {
      type: String,
      trim: true,
      maxlength: [500, 'Description cannot exceed 500 characters'],
    },
    type: {
      type: String,
      required: [true, 'Track type is required'],
      enum: {
        values: TRACK_TYPES,
        message: `Type must be one of: ${TRACK_TYPES.join(', ')}`,
      },
    },
    difficulty: {
      type: String,
      required: [true, 'Difficulty is required'],
      enum: {
        values: DIFFICULTIES,
        message: `Difficulty must be one of: ${DIFFICULTIES.join(', ')}`,
      },
    },
    distance: { type: Number, default: 0 },
    duration: { type: Number, default: 0 },
    steps: { type: Number, default: 0 },
    calories: { type: Number, default: 0 },
    isPublic: { type: Boolean, default: true },
    isTesting: { type: Boolean, default: false },
    status: {
      type: String,
      enum: ['recording', 'completed', 'draft'],
      default: 'recording',
    },
    coverImage: { type: String, trim: true },
    geoPath: lineStringSchema,
    startPoint: pointSchema,
    endPoint: pointSchema,
    flags: [flagSchema],
    photos: [{ type: String, trim: true }],
    likes: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    saves: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    isComplete: { type: Boolean, default: false },
  },
  { timestamps: true }
);

trackSchema.index({ startPoint: '2dsphere' });

module.exports = mongoose.model('Track', trackSchema);
