const http = require('http');
const mongoose = require('mongoose');
require('dotenv').config();

const app = require('./app');
const initLiveTrackSocket = require('./sockets');

const PORT = process.env.PORT || 9090;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/adventure_provider_db';

const server = http.createServer(app);
initLiveTrackSocket(server);

mongoose
  .connect(MONGODB_URI)
  .then(() => {
    console.log('Successfully connected to MongoDB remotely.');
  })
  .catch((error) => {
    console.error('Error connecting to MongoDB:', error);
  });

server.listen(PORT, () => {
  console.log(`Server is running on port: ${PORT} — http://localhost:${PORT}/`);
});
