import * as authService from '../services/authService';
import * as userRepo from '../repositories/userRepository';
jest.mock('../repositories/userRepository');

describe('authService', () => {
  it('registers new user', async () => {
    (userRepo.getUserByEmail as jest.Mock).mockResolvedValue(null);
    (userRepo.createUser as jest.Mock).mockResolvedValue({ id: 123, username: 'john', email: 'a@bunuasi.com' });
    const result = await authService.register('john', 'a@bunuasi.com', 'Pass123!');
    expect(result.id).toBe(123);
  });

  it('prevents duplicate email registration', async () => {
    (userRepo.getUserByEmail as jest.Mock).mockResolvedValue({ username: 'john', email: 'a@bunuasi.com', password: '8723p' });
    await expect(authService.register('john', 'a@bunuasi.com', 'Pass123!')).rejects.toThrow('Email already in use');
  });

  it('logs in existing user', async () => {
  (userRepo.getUserByEmail as jest.Mock).mockResolvedValue({ id: 123, username: 'john', email: 'a@bunuasi.com', password_hash: await require('bcrypt').hash('Pass123!', 10) });
  const result = await authService.login('a@bunuasi.com', 'Pass123!');
  expect(result.user.id).toBe(123);
});

  it('prevents login with invalid credentials', async () => {
    (userRepo.getUserByEmail as jest.Mock).mockResolvedValue(null);
    await expect(authService.login('john', 'wrongpass')).rejects.toThrow('Invalid credentials');
  });
});