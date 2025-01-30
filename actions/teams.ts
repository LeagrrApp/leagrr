"use server";
import { db } from "@/db/pg";
import { verifySession } from "@/lib/session";
import { check_string_is_color_hex } from "@/utils/helpers/validators";
import { redirect } from "next/navigation";
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

  // create insert statement
  const teamInsertSql = `
    INSERT INTO league_management.teams
      (name, description, color, join_code)
    VALUES
      ($1, $2, $3, $4)
    RETURNING
      slug, team_id
  `;

  // Value clean up to insure they are null in database not empty strings
  let color: string | null =
    teamData.color !== "custom" ? teamData.color : teamData.custom_color;
  if (color === "") color = null;

  const join_code = teamData.join_code !== "" ? teamData.join_code : null;

  // query database
  const teamInsertResult: ResultProps<{ slug: string; team_id: number }> =
    await db
      .query(teamInsertSql, [
        teamData.name,
        teamData.description,
        color,
        join_code,
      ])
      .then((res) => {
        return {
          message: `${teamData.name} successfully created!`,
          status: 200,
          data: res.rows[0],
        };
      })
      .catch((err) => {
        return {
          message: err.message,
          status: 400,
        };
      });

  if (!teamInsertResult.data) {
    return teamInsertResult;
  }
  // add user to team as manager (1)
  const teamMembershipSql = `
    INSERT INTO league_management.team_memberships
      (user_id, team_id, team_role)
    VALUES
      ($1, $2, 1)
  `;

  const teamMembershipInsertResult = await db
    .query(teamMembershipSql, [teamData.user_id, teamInsertResult.data.team_id])
    .then((res) => {
      return {
        message: `Team member added!`,
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  // Failed to add user as team admin, delete the team and return error
  if (teamMembershipInsertResult.status === 400) {
    // TODO: delete the league on this error

    return teamMembershipInsertResult;
  }

  // Success route, redirect to the new league page
  redirect(`/dashboard/t/${teamInsertResult.data}`);
}

export async function getTeam(
  slug: string,
): Promise<ResultProps<TeamPageData>> {
  // verify logged in
  await verifySession();

  const teamSql = `
    SELECT
      team_id,
      slug,
      name,
      description,
      join_code,
      status,
      color
    FROM
      league_management.teams
    WHERE slug = $1
  `;

  const teamResult = await db
    .query(teamSql, [slug])
    .then((res) => {
      if (res.rowCount === 0) {
        throw new Error("Team not found!");
      }

      return {
        message: `Team data found!`,
        status: 200,
        data: res.rows[0],
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  return teamResult;
}
