const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB Connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/adventure_provider_db';

mongoose.connect(MONGODB_URI)
  .then(() => {
    console.log('Successfully connected to MongoDB locally.');
  })
  .catch((error) => {
    console.error('Error connecting to MongoDB:', error);
  });

// Basic Route
app.get('/', (req, res) => {
  res.send('Adventure Provider Backend Server is running han g');
});

// Start Server
app.listen(PORT, () => {
  console.log(`Server is running on port: ${PORT}`);
});
