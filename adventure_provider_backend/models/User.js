const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    // Personal Info
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      lowercase: true,
      trim: true,
    },
    password: {
      type: String,
      required: [true, 'Password is required'],
      minlength: [6, 'Password must be at least 6 characters'],
      select: false,
    },
    phone: {
      type: String,
      trim: true,
      default: null,
    },
    profileImage: {
      type: String,
      default: null,
    },
    bio: {
      type: String,
      default: '',
      maxlength: [200, 'Bio cannot exceed 200 characters'],
    },
    dateOfBirth: {
      type: Date,
      default: null,
    },

    // Emergency Contact
    emergencyContact: {
      name: { type: String, default: '' },
      phone: { type: String, default: '' },
      relation: { type: String, default: '' },
    },

    // Adventure Stats (auto-managed)
    totalTracks: { type: Number, default: 0 },
    totalDistance: { type: Number, default: 0 },
    totalSteps: { type: Number, default: 0 },
    totalAdventures: { type: Number, default: 0 },

    // Account
    isActive: { type: Boolean, default: true },
    isEmailVerified: { type: Boolean, default: false },
    fcmToken: { type: String, default: null },

    // OTP (reset password)
    resetOtp: { type: String, default: null, select: false },
    resetOtpExpiry: { type: Date, default: null, select: false },
  },
  { timestamps: true }
);

// Pre-save: hash password if modified (async: do not call next in Mongoose 6+)
userSchema.pre('save', async function () {
  if (!this.isModified('password')) return;
  this.password = await bcrypt.hash(this.password, 12);
});

// Instance method: compare password with candidate
userSchema.methods.comparePassword = async function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

// Instance method: toJSON — remove sensitive fields
userSchema.methods.toJSON = function () {
  const obj = this.toObject();
  delete obj.password;
  delete obj.resetOtp;
  delete obj.resetOtpExpiry;
  return obj;
};

module.exports = mongoose.model('User', userSchema);
