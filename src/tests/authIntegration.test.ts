import request from 'supertest';
import app from '../app';

describe('Integration Test Example', () => {
  it('should return ok for health check', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});
