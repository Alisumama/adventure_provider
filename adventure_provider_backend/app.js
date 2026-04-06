const path = require('path');
const express = require('express');
const cors = require('cors');

const app = express();

app.use(cors());
app.use(express.json());
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
