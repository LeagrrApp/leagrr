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

export const SeasonFormSchema = z.object({
  name: z
    .string()
    .min(2, { message: "Name must be at least 2 characters long." })
    .trim(),
  description: z.string().trim().optional(),
  league_id: z.number(),
  start_date: z.string().date(),
  end_date: z.string().date(),
  status: z.enum(["draft", "public", "archived"]).optional(),
});

export interface SeasonErrorProps {
  name?: string[] | undefined;
  description?: string[] | undefined;
  league_id?: string[] | undefined;
  start_date?: string[] | undefined;
  end_date?: string[] | undefined;
  status?: string[] | undefined;
}

export type SeasonFormState =
  | {
      errors?: SeasonErrorProps;
      message?: string;
      status?: number;
    }
  | undefined;

export const sports_options: readonly [string, ...string[]] = [
  "hockey",
  "soccer",
  "basketball",
  "pickleball",
  "badminton",
];

export const status_options: readonly [string, ...string[]] = [
  "draft",
  "public",
  "archived",
];

export const game_status_options: readonly [string, ...string[]] = [
  "draft",
  "public",
  "archived",
  "completed",
  "cancelled",
  "postponed",
];

export const gender_options: readonly [string, ...string[]] = [
  "all",
  "men",
  "women",
];

export const color_options: readonly [string, ...string[]] = [
  "black",
  "blue",
  "brown",
  "cyan",
  "green",
  "grey",
  "indigo",
  "magenta",
  "orange",
  "pink",
  "purple",
  "red",
  "violet",
  "white",
  "yellow",
];

export const league_roles = new Map<number, RoleData>();

league_roles.set(1, { role: 1, title: "Commissioner" });
league_roles.set(2, { role: 2, title: "Manager" });

export const team_roles = new Map<number, RoleData>();

team_roles.set(1, { role: 1, title: "Manager" });
team_roles.set(2, { role: 2, title: "Member" });

export const roster_roles = new Map<number, RoleData>();

roster_roles.set(1, { role: 1, title: "Coach" });
roster_roles.set(2, { role: 2, title: "Captain" });
roster_roles.set(3, { role: 3, title: "Alternate" });
roster_roles.set(4, { role: 4, title: "Player" });
roster_roles.set(5, { role: 5, title: "Spare" });
