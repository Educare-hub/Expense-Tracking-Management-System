import { Request, Response } from 'express';
import * as authService from '../services/authService';

export async function register(req: Request, res: Response) {
  try {

   const newUser = req.body;
   console.log(newUser)
    const user = await authService.register(newUser);
    res.status(201).json({ message: 'User registered', user });
  } catch (err:any) {
    res.status(400).json({ error: err.message });
  }
}

export async function login(req: Request, res: Response) {
  try {
    const { email, password } = req.body;
    const result = await authService.login(email, password);
    res.json(result);
  } catch (err:any) {
    res.status(401).json({ error: err.message });
  }
}
