import sql from 'mssql';
import { getDbPool } from '../utils/db';
export interface UserCreate {
  username: string;
  email: string;
  password_hash: string;
}
export async function createUser(newUser: UserCreate) {
  const pool = await getDbPool();
  const result = await pool.request()
    .input('username', newUser.username) 
    .input('email', newUser.email)
    .input('password_hash', newUser.password_hash)
    .query(`
      INSERT INTO Users (username, email, password_hash)
      VALUES (@username, @email, @password_hash);
    `);
  return { message: 'User created successfully' }
}

export async function getUserByEmail( email: string) {
  const pool = await getDbPool();
  const result = await pool.request()
    .input('email', sql.VarChar(255), email)
    .query('SELECT id, username, email, password_hash, role FROM Users WHERE email = @email');
  return result.recordset[0];
}

export async function getUserById(id: number) {
  
  const pool = await getDbPool();

  const result = await pool.request()
    .input('id', sql.Int, id)
    .query('SELECT id, username, email, role FROM Users WHERE id = @id');
  return result.recordset[0];
}
