"use server";
import { verifySession } from "@/lib/session";
import { check_string_is_color_hex } from "@/utils/helpers/validators";
import { z } from "zod";

const TeamFormSchema = z.object({
  user_id: z.number().min(1),
  name: z
    .string()
    .min(2, { message: "Name must be at least 2 characters long." })
    .trim(),
  description: z.string().trim().optional(),
  color: z.string().optional(),
  custom_color: z.string().refine(check_string_is_color_hex, {
    message: "Invalid color format.",
  }),
  join_code: z.string().trim().optional(),
});

type TeamErrorProps = {
  user_id?: string[] | undefined;
  name?: string[] | undefined;
  description?: string[] | undefined;
  color?: string[] | undefined;
  custom_color?: string[] | undefined;
  join_code?: string[] | undefined;
};

type TeamFormState =
  | {
      errors?: TeamErrorProps;
      message?: string;
      status?: number;
      data?: Partial<TeamData>;
    }
  | undefined;

export async function createTeam(
  state: TeamFormState,
  formData: FormData,
): Promise<TeamFormState> {
  // Confirmed logged in
  await verifySession();

  // get data from form
  const teamData = {
    user_id: parseInt(formData.get("user_id") as string),
    name: formData.get("name") as string,
    description: formData.get("description") as string,
    color: formData.get("color") as string,
    custom_color: (formData.get("custom_color") as string) || "#000",
    join_code: formData.get("join_code") as string,
  };

  const validatedFields = TeamFormSchema.safeParse(teamData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      data: teamData,
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  const sql = `
    INSERT INTO league_management.teams
      (name, description, color, join_code)
    VALUES
      ($1, $2, $3, $4)
    RETURNING
      slug, team_id
  `;

  return {
    data: teamData,
    message: "Testing!",
    status: 200,
  };
}
