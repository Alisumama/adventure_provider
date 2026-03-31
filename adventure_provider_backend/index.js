const mongoose = require('mongoose');
require('dotenv').config();

const app = require('./app');

const PORT = process.env.PORT || 5000;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/adventure_provider_db';

mongoose
  .connect(MONGODB_URI)
  .then(() => {
    console.log('Successfully connected to MongoDB locally.');
  })
  .catch((error) => {
    console.error('Error connecting to MongoDB:', error);
  });

app.listen(PORT, () => {
  console.log(`Server is running on port: ${PORT}`);
});
