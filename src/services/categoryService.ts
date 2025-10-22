import { getDbPool } from '../utils/db';
import * as catRepo from '../repositories/categoryRepository';

export async function createCategory(name: string, userId?: number) {
  const pool = await getDbPool();
  return catRepo.createCategory(pool, name, userId);
}

export async function listCategories(userId?: number) {
  const pool = await getDbPool();
  return catRepo.getCategories(pool, userId);
}

export async function updateCategory(id: number, name: string) {
  const pool = await getDbPool();
  return catRepo.updateCategory(pool, id, name);
}

export async function deleteCategory(id: number) {
  const pool = await getDbPool();
  return catRepo.deleteCategory(pool, id);
}
