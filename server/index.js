require('dotenv').config();
const express = require('express');
const { Pool } = require('pg');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// Neon database connection pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

// Basic health check route
app.get('/', (req, res) => {
  res.json({ message: 'TRACKIT server is running' });
});

// Test database connection route
app.get('/api/test-db', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW()');
    res.json({
      success: true,
      message: 'Database connected successfully',
      timestamp: result.rows[0].now
    });
  } catch (error) {
    console.error('Database connection error:', error);
    res.status(500).json({
      success: false,
      message: 'Database connection failed',
      error: error.message
    });
  }
});

app.listen(PORT, () => {
  console.log(`TRACKIT server running on http://localhost:${PORT}`);
});