const path = require('path');
const express = require('express');
const cors = require('cors');

const app = express();

app.use(cors());
app.use(express.json());

/** Log every `/api` HTTP call to the console when the response finishes. */
app.use((req, res, next) => {
  if (!req.originalUrl.startsWith('/api')) {
    return next();
  }
  const started = Date.now();
  res.on('finish', () => {
    const ms = Date.now() - started;
    const ip = req.ip || req.socket?.remoteAddress || '-';
    console.log(
      `[${new Date().toISOString()}] ${req.method} ${req.originalUrl} → ${res.statusCode} ${ms}ms [${ip}]`,
    );
  });
  next();
});

app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

app.get('/', (req, res) => {
  res.send('Adventure Provider Backend Server is running han g');
});

const authRoutes = require('./routes/auth.routes');
app.use('/api/auth', authRoutes);

const trackRoutes = require('./routes/track.routes');
app.use('/api/tracks', trackRoutes);

const communityRoutes = require('./routes/community.routes');
app.use('/api/community', communityRoutes);

module.exports = app;
