const path = require('path');
// .env lives at trackit_app/.env (one level up from server/), not inside
// server/ itself -- dotenv's default lookup is relative to the current
// working directory, which breaks when you `cd server && npm start`.
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

module.exports = pool;
