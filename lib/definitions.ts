import { JWTPayload } from "jose";
import { z } from "zod";

export interface SessionPayload extends JWTPayload {
  userData: UserData;
  expiresAt: Date;
}

export const SignupFormSchema = z.object({
  username: z
    .string()
    .min(2, { message: "Name must be at least 2 characters long." })
    .trim(),
  email: z.string().email({ message: "Please enter a valid email." }).trim(),
  first_name: z
    .string()
    .min(2, { message: "Name must be at least 2 characters long." })
    .trim(),
  last_name: z
    .string()
    .min(2, { message: "Name must be at least 2 characters long." })
    .trim(),
  password: z
    .string()
    .min(8, { message: "Be at least 8 characters long" })
    .regex(/[a-zA-Z]/, { message: "Contain at least one letter." })
    .regex(/[0-9]/, { message: "Contain at least one number." })
    .regex(/[^a-zA-Z0-9]/, {
      message: "Contain at least one special character.",
    })
    .trim(),
});

export type SignInUpFormState =
  | {
      errors?: {
        username?: string[];
        email?: string[];
        first_name?: string[];
        last_name?: string[];
        password?: string[];
        password_confirm?: string[];
      };
      message?: string;
    }
  | undefined;

export const LeagueFormSchema = z.object({
  name: z
    .string()
    .min(2, { message: "Name must be at least 2 characters long." })
    .trim(),
  description: z
    .string()
    .min(2, { message: "Description must be at least 2 characters long." })
    .trim()
    .optional(),
  sport_id: z.number(),
  status: z.enum(["draft", "public", "archived"]).optional(),
});

interface ErrorProps {
  name?: string[] | undefined;
  description?: string[] | undefined;
  sport_id?: string[] | undefined;
  status?: string[] | undefined;
}

export type LeagueFormState =
  | {
      errors?: ErrorProps;
      message?: string;
      status?: number;
    }
  | undefined;
