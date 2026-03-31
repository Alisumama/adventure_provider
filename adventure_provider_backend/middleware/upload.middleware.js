const path = require('path');
const multer = require('multer');

const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB

const ALLOWED_EXT = new Set(['.jpg', '.jpeg', '.png', '.webp']);

function fileFilter(req, file, cb) {
  const ext = path.extname(file.originalname).toLowerCase();
  if (ALLOWED_EXT.has(ext)) {
    cb(null, true);
    return;
  }
  cb(new Error('Only image files are allowed'));
}

const profileStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/profiles/');
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`);
  },
});

const coverStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/covers/');
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`);
  },
});

const uploadProfileImage = multer({
  storage: profileStorage,
  limits: { fileSize: MAX_FILE_SIZE },
  fileFilter,
});

const uploadCoverImage = multer({
  storage: coverStorage,
  limits: { fileSize: MAX_FILE_SIZE },
  fileFilter,
});

module.exports = { uploadProfileImage, uploadCoverImage };
