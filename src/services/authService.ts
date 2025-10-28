import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import * as userRepo from '../repositories/userRepository';
import { getDbPool } from '../utils/db';


const JWT_SECRET = process.env.JWT_SECRET || 'change_me';

export async function register(user: userRepo.UserCreate) {
  const existing = await userRepo.getUserByEmail(user.email);
  if (existing) throw new Error('Email already in use');
  if(user.password_hash){
    console.log(user.password_hash)
    const password_hash = await bcrypt.hash(user.password_hash, 10);
    console.log("hashedpss:", password_hash)
    user.password_hash = password_hash;
  }
  await userRepo.createUser(user);

}

export async function login(email: string, password: string) {
  const pool = await getDbPool();
  const user = await userRepo.getUserByEmail(email);
  if (!user) throw new Error('Invalid credentials');
  const ok = await bcrypt.compare(password, user.password_hash);
  if (!ok) throw new Error('Invalid credentials');
  const token = jwt.sign({ userId: user.id, role: user.role }, JWT_SECRET, { expiresIn: '7d' });
  return { token, user: { id: user.id, username: user.username, email: user.email, role: user.role } };
}
