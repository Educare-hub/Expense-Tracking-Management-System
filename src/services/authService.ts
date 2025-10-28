import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import * as userRepo from '../repositories/userRepository';
import { getDbPool } from '../utils/db';

const SALT_ROUNDS = 10;
const JWT_SECRET = process.env.JWT_SECRET || 'change_me';

export async function register(username: string, email: string, password: string) {
  const pool = await getDbPool();
  const existing = await userRepo.getUserByEmail(pool, email);
  if (existing) throw new Error('User already exists');
  const password_hash = await bcrypt.hash(password, SALT_ROUNDS);
  const newUser = await userRepo.createUser(pool, username, email, password_hash);
  return newUser;
}

export async function login(email: string, password: string) {
  const pool = await getDbPool();
  const user = await userRepo.getUserByEmail(pool, email);
  if (!user) throw new Error('Invalid credentials');
  const ok = await bcrypt.compare(password, user.password_hash);
  if (!ok) throw new Error('Invalid credentials');
  const token = jwt.sign({ userId: user.id, role: user.role }, JWT_SECRET, { expiresIn: '7d' });
  return { token, user: { id: user.id, username: user.username, email: user.email, role: user.role } };
}
