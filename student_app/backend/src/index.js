// Import tracing setup before anything else
import './tracing.js';

import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { createPool } from 'mysql2/promise';
import { createClient } from 'redis';

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

// MySQL connection pool
let pool;
try {
  pool = createPool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
  });
  console.log('✅ MySQL pool initialized successfully');
} catch (error) {
  console.error('❌ Failed to initialize MySQL pool:', error);
  process.exit(1);
}

// Redis client
const redisClient = createClient({ url: process.env.REDIS_URL });

redisClient.on('error', (err) => console.error('❌ Redis Client Error:', err));

(async () => {
  try {
    await redisClient.connect();
    console.log('✅ Redis client connected successfully');
  } catch (error) {
    console.error('❌ Failed to connect to Redis:', error);
    process.exit(1);
  }
})();

app.use(cors({ origin: '*', credentials: true }));
app.use(express.json());

// Create student
app.post('/api/students', async (req, res) => {
  try {
    const { name, age, class: className } = req.body;
    const [result] = await pool.execute(
      'INSERT INTO students (name, age, class) VALUES (?, ?, ?)',
      [name, age, className]
    );

    await redisClient.del('students');
    res.status(201).json({ id: result.insertId });
  } catch (error) {
    console.error('❌ Error creating student:', error);
    res.status(500).json({ error: 'Failed to create student' });
  }
});

// Get all students
app.get('/api/students', async (req, res) => {
  try {
    const cachedStudents = await redisClient.get('students');
    if (cachedStudents) {
      return res.json(JSON.parse(cachedStudents));
    }

    const [rows] = await pool.execute('SELECT * FROM students ORDER BY created_at DESC');
    await redisClient.set('students', JSON.stringify(rows), { EX: 300 });

    res.json(rows);
  } catch (error) {
    console.error('❌ Error fetching students:', error);
    res.status(500).json({ error: 'Failed to fetch students' });
  }
});

// Delete student
app.delete('/api/students/:id', async (req, res) => {
  try {
    await pool.execute('DELETE FROM students WHERE id = ?', [req.params.id]);
    await redisClient.del('students');
    res.status(204).send();
  } catch (error) {
    console.error('❌ Error deleting student:', error);
    res.status(500).json({ error: 'Failed to delete student' });
  }
});

// Graceful Shutdown
const shutdown = async () => {
  console.log('🛑 Gracefully shutting down...');
  try {
    await redisClient.quit();
    console.log('✅ Redis disconnected');
  } catch (error) {
    console.error('❌ Error shutting down Redis:', error);
  }

  try {
    await pool.end();
    console.log('✅ MySQL pool closed');
  } catch (error) {
    console.error('❌ Error shutting down MySQL pool:', error);
  }

  process.exit(0);
};

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

app.listen(port, () => {
  console.log(`🚀 Server running on port ${port}`);
});
