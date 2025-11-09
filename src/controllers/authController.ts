import { Request, Response } from 'express';
import * as authService from '../services/authService';
import * as userRepo from '../repositories/userRepository';

export async function register(req: Request, res: Response) {
  try {
<<<<<<< HEAD

   const newUser = req.body;
   console.log(newUser)
    const user = await authService.register(newUser);
    res.status(201).json({ message: 'User registered', user });
  } catch (err:any) {
=======
    const newUser = req.body;

    // Register the user (authService.register returns void)
    await authService.register(newUser);

    // Fetch the newly created user from the database to get all fields
    const createdUser = await userRepo.getUserByEmail(newUser.email);

    if (!createdUser) {
      return res.status(500).json({ error: 'User registration failed' });
    }

    // Respond with user details
    res.status(201).json({
      message: 'User registered successfully',
      user: {
        id: createdUser.id,
        username: createdUser.username,
        email: createdUser.email,
        role: createdUser.role,
        created_at: createdUser.created_at,
      },
    });
  } catch (err: any) {
>>>>>>> 2483db4 (Add .gitattributes to standardize line endings)
    res.status(400).json({ error: err.message });
  }
}

export async function login(req: Request, res: Response) {
  try {
    const { email, password } = req.body;
    const result = await authService.login(email, password);
    res.json(result);
  } catch (err: any) {
    res.status(400).json({ error: err.message });
  }
}
