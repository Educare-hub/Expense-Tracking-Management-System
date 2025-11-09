// src/tests/authIntegration.test.ts
import request from 'supertest';
import app from '../../src/app';
import * as userRepo from '../../src/repositories/userRepository';
import { hashPassword } from '../../src/services/authService';

jest.mock('../../src/repositories/userRepository');

describe('Auth Integration Tests', () => {
  const testUser = {
    id: 1,
    username: 'testuser',
    email: 'test@example.com',
    password_hash: '',
    role: 'user',
    created_at: new Date(),
  };

  beforeAll(async () => {
    testUser.password_hash = await hashPassword('1234'); // hash once for login test
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('should register a new user successfully', async () => {
    // Mock DB responses
    (userRepo.getUserByEmail as jest.Mock)
      .mockResolvedValueOnce(undefined) // check email exists → not found
      .mockResolvedValueOnce(testUser); // after creation, return created user
    (userRepo.createUser as jest.Mock).mockResolvedValue(1);

    const newUser = {
      username: testUser.username,
      email: testUser.email,
      password_hash: '1234',
      role: testUser.role,
    };

    const res = await request(app).post('/api/auth/register').send(newUser);

    expect(res.status).toBe(201);
    expect(res.body.message).toBe('User registered successfully');
    expect(res.body.user).toMatchObject({
      id: 1,
      username: 'testuser',
      email: 'test@example.com',
      role: 'user',
    });
  });

  test('should login successfully', async () => {
    (userRepo.getUserByEmail as jest.Mock).mockResolvedValue(testUser);

    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: testUser.email, password: '1234' });

    expect(res.status).toBe(200);
    expect(res.body.user.email).toBe(testUser.email);
    expect(typeof res.body.token).toBe('string');
  });

  test('should not login with wrong password', async () => {
    (userRepo.getUserByEmail as jest.Mock).mockResolvedValue(testUser);

    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: testUser.email, password: 'wrongpassword' });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('Invalid credentials');
  });
});
