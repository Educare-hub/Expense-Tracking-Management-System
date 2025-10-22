import { getDbPool } from '../utils/db';
import * as expRepo from '../repositories/expenseRepository';

export async function createExpense(payload: any) {
  const pool = await getDbPool();
  return expRepo.createExpense(pool, payload);
}

export async function listExpenses(userId: number, filters?: any) {
  const pool = await getDbPool();
  return expRepo.getExpenses(pool, userId, filters);
}

export async function getExpense(userId: number, id: number) {
  const pool = await getDbPool();
  return expRepo.getExpenseById(pool, id, userId);
}

export async function updateExpense(userId: number, id: number, updates: any) {
  const pool = await getDbPool();
  return expRepo.updateExpense(pool, id, userId, updates);
}

export async function deleteExpense(userId: number, id: number) {
  const pool = await getDbPool();
  return expRepo.deleteExpense(pool, id, userId);
}
