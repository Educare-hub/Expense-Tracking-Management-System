import { hashPassword, checkPassword, createToken, register, login } from '../../src/services/authService';
import * as userRepo from '../../src/repositories/userRepository';

jest.mock('../../src/repositories/userRepository'); // Mock database

test('hashPassword creates a different string', async () => {
  const password = '1234';
  const hash = await hashPassword(password);
  expect(hash).not.toBe(password);
});

test('checkPassword returns true for correct password', async () => {
  const password = '1234';
  const hash = await hashPassword(password);
  const result = await checkPassword(password, hash);
  expect(result).toBe(true);
});

test('createToken returns a string', () => {
  const token = createToken(1, 'user');
  expect(typeof token).toBe('string');
});

test('register calls createUser', async () => {
  const user = { email: 'test@test.com', password_hash: '1234' };
  (userRepo.getUserByEmail as jest.Mock).mockResolvedValue(null);
  await register(user as any);
  expect(userRepo.createUser).toHaveBeenCalled();
});

test('login returns token and user', async () => {
  const fakeUser = { id: 1, username: 'test', email: 'test@test.com', role: 'user', password_hash: await hashPassword('1234') };
  (userRepo.getUserByEmail as jest.Mock).mockResolvedValue(fakeUser);
  const result = await login('test@test.com', '1234');
  expect(result.user.email).toBe('test@test.com');
  expect(typeof result.token).toBe('string');
});
