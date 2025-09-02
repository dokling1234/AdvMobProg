// index.js
require('dotenv').config();

const express = require('express');

const cors = require('cors');

const path = require('path');

const bodyParser = require('body-parser');
const jsonParser = bodyParser.json();

const mongoose = require('mongoose');

const connectDB = require('./config/db');

const userRoutes = require('./routes/userRoutes');

const articleRoutes = require('./routes/articleRoutes');
 
const app = express();
 
// Database Connection

connectDB();
 
app.use(express.json());
 
// Middleware

app.use(jsonParser);

app.use(bodyParser.urlencoded({ extended: true }));

app.use(cors());
 
const corsOptions = {

  origin: '*', // Allow all origins

  credentials: true, // Allow credentials

  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],

  methods: ['GET', 'HEAD', 'PUT', 'PATCH', 'POST', 'DELETE'],

  preflightContinue: false,

  optionsSuccessStatus: 204, // For legacy browser support

};
 
app.options(/.*/, cors(corsOptions));

app.use(cors(corsOptions));
 
// Curb CORS Error by adding a header here

app.use((req, res, next) => {

  res.setHeader('Access-Control-Allow-Origin', '*');

  res.setHeader(

    'Access-Control-Allow-Headers',

    'Origin, X-Requested-With, Content, Accept, Content-Type, Authorization'

  );

  res.setHeader(

    'Access-Control-Allow-Methods',

    'GET, POST, PUT, DELETE, PATCH, OPTIONS'

  );

  next();

});
 
// Routes

app.use('/api/users', userRoutes);

app.use('/api/articles', articleRoutes);
 
// Error Handling

app.use((err, req, res, next) => {

  console.error(err.stack);

  res.status(500).json({ message: 'Server Error' });

});
 
const PORT = process.env.PORT || 5000;

app.listen(PORT, () => console.log(`Server running on port ${PORT}`));

 