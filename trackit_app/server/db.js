const path = require('path');
// .env lives at trackit_app/.env (one level up from server/), not inside
// server/ itself -- dotenv's default lookup is relative to the current
// working directory, which breaks when you `cd server && npm start`.
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
  // Philippine Standard Time is this app's system timezone (see
  // utils/manilaTime.js for the JS-side half of this). Setting it via a
  // libpq startup option -- rather than a "SET TIME ZONE" query fired
  // from a pool 'connect' listener -- applies it before a connection can
  // ever be checked out and used, so there's no race where a query slips
  // through on a fresh connection still on the DB server's default (UTC)
  // session timezone. It's what makes CURRENT_DATE/CURRENT_TIMESTAMP
  // (e.g. the attendance progress query's "last 7 days" window) agree
  // with the app's own "today".
  options: '-c timezone=Asia/Manila',
});

module.exports = pool;
