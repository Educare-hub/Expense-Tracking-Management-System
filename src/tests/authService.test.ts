import * as authService from '../services/authService';
import * as userRepo from '../repositories/userRepository';
jest.mock('../src/repositories/userRepository');

describe('authService', () => {
  it('registers new user', async () => {
    (userRepo.getUserByEmail as jest.Mock).mockResolvedValue(null);
    (userRepo.createUser as jest.Mock).mockResolvedValue({ id: 123, username: 'john', email: 'a@b.com' });
    const result = await authService.register('john', 'a@b.com', 'Pass123!');
    expect(result.id).toBe(123);
  });
});
