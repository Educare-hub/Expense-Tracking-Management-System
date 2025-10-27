// backend/src/routes/expenses.ts
import express, { Request, Response } from 'express';

export const router = express.Router(); // ✅ named export for TypeScript

// Example GET endpoint
router.get('/', async (req: Request, res: Response) => {
  try {
    const pool = (req as any).db;
    const result = await pool.request().query(`
      SELECT TOP 10 id, amount, vendor, description, incurred_at 
      FROM dbo.expenses 
      ORDER BY created_at DESC
    `);
    res.json({ success: true, data: result.recordset });
  } catch (err: any) {
    console.error('❌ Query failed:', err.message);
    res.status(500).json({ success: false, message: 'Query failed', error: err.message });
  }
});
