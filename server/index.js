const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

const pool = process.env.DATABASE_URL
  ? new Pool({ connectionString: process.env.DATABASE_URL })
  : new Pool({
      host: process.env.PGHOST || 'localhost',
      user: process.env.PGUSER || 'postgres',
      password: process.env.PGPASSWORD || 'postgres',
      database: process.env.PGDATABASE || 'imageapp',
      port: process.env.PGPORT ? Number(process.env.PGPORT) : 5432,
    });

async function initDatabase() {
  const client = await pool.connect();
  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS favorites (
        id INTEGER PRIMARY KEY
      )
    `);
  } finally {
    client.release();
  }
}

function normalizeFavorites(payload) {
  if (!payload || !Array.isArray(payload.favorites)) return null;
  const ids = payload.favorites
    .map((value) => Number(value))
    .filter((n) => Number.isFinite(n) && Number.isInteger(n) && n >= 0);
  return Array.from(new Set(ids));
}

app.use(cors());
app.use(express.json());

app.get('/api/favorites', async (req, res) => {
  try {
    const result = await pool.query('SELECT id FROM favorites ORDER BY id');
    res.json({ favorites: result.rows.map((row) => row.id) });
  } catch (error) {
    console.error('GET /api/favorites error', error);
    res.status(500).json({ error: 'Unable to load favorites' });
  }
});

app.post('/api/favorites', async (req, res) => {
  const favorites = normalizeFavorites(req.body);
  if (favorites === null) {
    return res.status(400).json({ error: 'Expected { favorites: [1,2,3] }' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query('DELETE FROM favorites');

    if (favorites.length > 0) {
      const valuesSql = favorites.map((_, index) => `($${index + 1})`).join(', ');
      await client.query(`INSERT INTO favorites(id) VALUES ${valuesSql}`, favorites);
    }

    await client.query('COMMIT');
    res.json({ favorites });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('POST /api/favorites error', error);
    res.status(500).json({ error: 'Unable to save favorites' });
  } finally {
    client.release();
  }
});

app.listen(PORT, async () => {
  try {
    await initDatabase();
    console.log(`Imageapp server running on port ${PORT}`);
  } catch (error) {
    console.error('Failed to initialize database', error);
    process.exit(1);
  }
});
