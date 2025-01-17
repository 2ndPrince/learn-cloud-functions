import { Request, Response } from "express";

export const helloHttp = (req: Request, res: Response) => {
    const n: number = 10;
    res.send(`Hello, World! YSLE ${n}`);
};
