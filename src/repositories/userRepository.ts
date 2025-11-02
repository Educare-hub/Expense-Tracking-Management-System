// src/repositories/userRepository.ts
import sql from 'mssql';
import { getDbPool } from '../utils/db';

export interface UserCreate {
  username: string;
  email: string;
  password_hash: string;
}

// -----------------------------
// Create a new user
// -----------------------------
export async function createUser(newUser: UserCreate) {
  try {
    const pool = await getDbPool();
    const result = await pool.request()
      .input('username', sql.VarChar(100), newUser.username)
      .input('email', sql.VarChar(255), newUser.email)
      .input('password_hash', sql.VarChar(255), newUser.password_hash)
      .query(`
        INSERT INTO Users (username, email, password_hash)
        OUTPUT INSERTED.id
        VALUES (@username, @email, @password_hash);
      `);

    // Return the new user ID
    return result.recordset[0].id;
  } catch (err: any) {
    if (err?.number === 2627) { // Unique constraint violation (duplicate email)
      throw new Error('Email already exists');
    }
    console.error('Error creating user:', err);
    throw new Error('Failed to create user');
  }
}

// -----------------------------
// Get user by email
// -----------------------------
export async function getUserByEmail(email: string) {
  try {
    const pool = await getDbPool();
    const result = await pool.request()
      .input('email', sql.VarChar(255), email)
      .query(`
        SELECT id, username, email, password_hash, role, created_at, updated_at
        FROM Users
        WHERE email = @email
      `);

    return result.recordset[0]; // undefined if not found
  } catch (err) {
    console.error('Error fetching user by email:', err);
    throw new Error('Failed to fetch user');
  }
}

// -----------------------------
// Get user by ID
// -----------------------------
export async function getUserById(id: number) {
  try {
    const pool = await getDbPool();
    const result = await pool.request()
      .input('id', sql.Int, id)
      .query(`
        SELECT id, username, email, role, created_at, updated_at
        FROM Users
        WHERE id = @id
      `);

    return result.recordset[0]; // undefined if not found
  } catch (err) {
    console.error('Error fetching user by ID:', err);
    throw new Error('Failed to fetch user');
  }
}

// -----------------------------
// Optional: Get all users (useful for admin)
// -----------------------------
export async function getAllUsers() {
  try {
    const pool = await getDbPool();
    const result = await pool.request()
      .query(`
        SELECT id, username, email, role, created_at, updated_at
        FROM Users
        ORDER BY id
      `);

    return result.recordset;
  } catch (err) {
    console.error('Error fetching all users:', err);
    throw new Error('Failed to fetch users');
  }
}
