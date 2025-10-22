import sql from 'mssql';

export async function createUser(pool: sql.ConnectionPool, username: string, email: string, password_hash: string, role = 'User') {
  const result = await pool.request()
    .input('username', sql.VarChar(100), username)
    .input('email', sql.VarChar(255), email)
    .input('password_hash', sql.VarChar(255), password_hash)
    .input('role', sql.VarChar(20), role)
    .query(`
      INSERT INTO Users (username, email, password_hash, role)
      VALUES (@username, @email, @password_hash, @role);
      SELECT SCOPE_IDENTITY() AS id, username, email, role;
    `);
  return result.recordset[0];
}

export async function getUserByEmail(pool: sql.ConnectionPool, email: string) {
  const result = await pool.request()
    .input('email', sql.VarChar(255), email)
    .query('SELECT id, username, email, password_hash, role FROM Users WHERE email = @email');
  return result.recordset[0];
}

export async function getUserById(pool: sql.ConnectionPool, id: number) {
  const result = await pool.request()
    .input('id', sql.Int, id)
    .query('SELECT id, username, email, role FROM Users WHERE id = @id');
  return result.recordset[0];
}
