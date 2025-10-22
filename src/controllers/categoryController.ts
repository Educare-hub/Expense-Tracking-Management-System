import { Request, Response } from 'express';
import * as catService from '../services/categoryService';
import { AuthRequest } from '../middleware/authMiddleware';

export async function createCategory(req: AuthRequest, res: Response) {
  try {
    const { name, userId } = req.body;
    const created = await catService.createCategory(name, userId ?? req.user?.userId);
    res.status(201).json(created);
  } catch (err:any) {
    res.status(400).json({ error: err.message });
  }
}

export async function listCategories(req: AuthRequest, res: Response) {
  try {
    const categories = await catService.listCategories(req.user?.userId);
    res.json(categories);
  } catch (err:any) {
    res.status(500).json({ error: err.message });
  }
}

export async function updateCategory(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const { name } = req.body;
    const updated = await catService.updateCategory(Number(id), name);
    res.json(updated);
  } catch (err:any) {
    res.status(400).json({ error: err.message });
  }
}

export async function deleteCategory(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const deleted = await catService.deleteCategory(Number(id));
    res.json(deleted);
  } catch (err:any) {
    res.status(400).json({ error: err.message });
  }
}
