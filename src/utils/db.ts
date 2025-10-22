import sql from 'mssql';
import dotenv from 'dotenv';
dotenv.config();

let pool: sql.ConnectionPool | null = null;

export async function getDbPool(): Promise<sql.ConnectionPool> {
  if (pool && pool.connected) return pool;
  const config: sql.config = {
    user: process.env.DB_USER,
    password: process.env.DB_PASS||'Kenya!1234',
    server: process.env.DB_HOST|| 'localhost',
    database: process.env.DB_NAME||'ExpenseTrackerDB',
    options: {
      encrypt: false,
      trustServerCertificate: true
    },
    pool: {
      max: 10,
      min: 0,
      idleTimeoutMillis: 30000
    }
  };
  pool = await sql.connect(config);
  return pool;
}
