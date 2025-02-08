"use server";

import { db } from "@/db/pg";
import {
  league_roles,
  sports_options,
  status_options,
} from "@/lib/definitions";
import { verifySession } from "@/lib/session";
import { redirect } from "next/navigation";
import { z } from "zod";
import { verifyUserRole } from "./users";
import { createDashboardUrl } from "@/utils/helpers/formatting";

const LeagueFormSchema = z.object({
  name: z
    .string()
    .min(2, { message: "Name must be at least 2 characters long." })
    .trim(),
  description: z.string().trim().optional(),
  sport: z.enum(sports_options),
  status: z.enum(status_options).optional(),
});

interface LeagueErrorProps {
  name?: string[] | undefined;
  description?: string[] | undefined;
  sport?: string[] | undefined;
  status?: string[] | undefined;
}

export type LeagueFormState =
  | {
      errors?: LeagueErrorProps;
      message?: string;
      status?: number;
    }
  | undefined;

export async function createLeague(
  state: LeagueFormState,
  formData: FormData,
): Promise<LeagueFormState> {
  // Verify user session
  const { user_id } = await verifySession();

  // insert data from form into object that can be checked for errors
  const leagueData = {
    name: formData.get("name"),
    description: formData.get("description"),
    sport: formData.get("sport"),
  };

  // let errors: ErrorProps = {};

  // Validate form fields
  const validatedFields = LeagueFormSchema.safeParse(leagueData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  // Build insert sql statement
  const leagueInsertSql = `
    INSERT INTO league_management.leagues
      (name, description, sport)
    VALUES
      ($1, $2, $3)
    RETURNING league_id, slug
  `;

  // Insert new league into the database
  const leagueInsertResult: ResultProps<LeagueData> = await db
    .query(leagueInsertSql, [
      leagueData.name,
      leagueData.description,
      leagueData.sport,
    ])
    .then((res) => {
      return {
        message: "League created!",
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

  // if no data was returned, there was an error, return the error
  if (!leagueInsertResult.data) {
    return leagueInsertResult;
  }

  // get league_id and slug generated and returned by the database
  const { league_id, slug } = leagueInsertResult.data;

  // Insert user and league into the league_admins table as Commissioner (league_role_id = 1)
  const leagueAdminSql = `
    INSERT INTO league_management.league_admins (league_role, league_id, user_id)
    VALUES (1, $1, $2)
  `;

  const leagueAdminInsertResult = await db
    .query(leagueAdminSql, [league_id, user_id])
    .then(() => {
      return {
        message: "User added as league admin",
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  // Failed to add user as league admin, delete the league and return error
  if (leagueAdminInsertResult.status === 400) {
    // TODO: delete the league on this error

    return leagueAdminInsertResult;
  }

  // Success route, redirect to the new league page
  redirect(createDashboardUrl({ l: slug }));
}

export async function getLeagueAdminRole(
  league: number | string,
): Promise<number | undefined> {
  // Verify user session
  const { user_id } = await verifySession();

  let league_id = league;

  // league slug was provided, but need league_id to check role
  if (typeof league === "string") {
    // get league_id
    const leagueIdSql = `
      SELECT
        league_id
      FROM
        league_management.leagues
      WHERE
        slug = $1
    `;

    const leagueIdResult: ResultProps<{ league_id: number }> = await db
      .query(leagueIdSql, [league])
      .then((res) => {
        return {
          message: "League ID retrieved",
          status: 200,
          data: res.rows[0],
        };
      });

    // no matching league was found or there was an error
    if (!leagueIdResult.data) {
      // return no role
      return undefined;
    }

    league_id = leagueIdResult.data.league_id;
  }

  if (typeof league_id === "string") return undefined;

  // build sql select statement
  const adminsSql = `
    SELECT
      league_role
    FROM
      league_management.league_admins
    WHERE
      league_id = $1 AND user_id = $2
  `;

  // query database for any matching both league and user
  const adminsResult: ResultProps<AdminRole> = await db
    .query(adminsSql, [league_id, user_id])
    .then((res) => {
      if (res.rowCount) {
        return {
          message: "User has league admin role",
          data: {
            league_role: res.rows[0].league_role,
          },
          status: 200,
        };
      }

      return {
        message: "User doest not have league admin role",
        data: {
          league_role: undefined,
        },
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: `There was a problem verifying the user's admin status: ${err.message}`,
        status: 400,
        data: {
          league_role: undefined,
        },
      };
    });

  if (adminsResult.data?.league_role) return adminsResult.data?.league_role;

  return undefined;
}

export async function verifyLeagueAdminRole(
  league: number | string,
  roleType: number,
): Promise<boolean> {
  const league_role = await getLeagueAdminRole(league);

  return league_role === roleType;
}

export async function canEditLeague(
  league: number | string,
  commissionerOnly?: boolean,
): Promise<{ canEdit: boolean; role: RoleData | undefined }> {
  // check if they are a site wide admin
  const isAdmin = await verifyUserRole(1);

  // set the role data if site wide admin
  let role: RoleData | undefined = isAdmin
    ? {
        role: 1,
        title: "Site Admin",
      }
    : undefined;

  // set initial canEdit to whether or not user is site wide admin
  let canEdit = isAdmin;

  // skip additional database query if we already know user has permission
  if (!canEdit) {
    // check for league admin privileges
    const leagueAdminResult: number | undefined =
      await getLeagueAdminRole(league);

    // verify which role the user has
    if (leagueAdminResult) {
      // set canEdit based on whether it is a commissionerOnly check or not
      canEdit = commissionerOnly
        ? leagueAdminResult === 1
        : leagueAdminResult === 1 || leagueAdminResult === 2;
      // set name of role
      role = league_roles.get(leagueAdminResult);
    }
  }

  return {
    canEdit,
    role,
  };
}

export async function getLeagueData(
  slug: string,
): Promise<ResultProps<LeagueData>> {
  // Verify user session
  await verifySession();

  // build league select statement
  const leagueSql = `
    SELECT
      league_id,
      slug,
      name,
      description,
      sport,
      status
    FROM
      league_management.leagues as l
    WHERE
      l.slug = $1
  `;

  // make request to database for leagues
  const leagueResult: ResultProps<LeagueData> = await db
    .query(leagueSql, [slug])
    .then((res) => {
      if (!res.rowCount) {
        throw new Error("League not found in database!");
      }
      return {
        message: "League data retrieved",
        data: res.rows[0],
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 404,
      };
    });

  // if the league was not found, return error
  if (!leagueResult.data) return leagueResult;

  // build select statement to get all seasons for associated league
  const seasonsSql = `
    SELECT
      slug,
      name,
      status,
      start_date,
      end_date
    FROM
      league_management.seasons
    WHERE
      league_id = $1
    ORDER BY end_date DESC
  `;

  // make request to database for seasons
  const seasonsResult: ResultProps<{ seasons: SeasonData[] }> = await db
    .query(seasonsSql, [leagueResult.data.league_id])
    .then((res) => {
      return {
        message: "Seasons data retrieved",
        data: {
          seasons: res.rows,
        },
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });
  // TODO: add short circuit if there is an error getting seasons

  const adminsResult = await getLeagueAdminRole(leagueResult.data.league_id);
  // TODO: add short circuit if there is an error getting league admins

  // combine all retrieved data into a single data object and return
  return {
    message: "League data found.",
    status: 200,
    data: {
      ...leagueResult.data,
      ...seasonsResult.data,
      league_role_id: adminsResult,
    },
  };
}

export async function editLeague(
  state: LeagueFormState,
  formData: FormData,
): Promise<LeagueFormState> {
  // Verify user session
  await verifySession();

  // insert data from form into object that can be checked for errors
  const leagueData = {
    name: formData.get("name"),
    description: formData.get("description"),
    sport: formData.get("sport"),
    status: formData.get("status"),
    league_id: parseInt(formData.get("league_id") as string),
  };

  // check if user can edit league
  const { canEdit } = await canEditLeague(leagueData.league_id);

  if (!canEdit) {
    // failed both user role check and league role check, shortcut out
    return {
      message: "You do not have permission to edit this league.",
      status: 401,
    };
  }

  // Validate form fields
  const validatedFields = LeagueFormSchema.safeParse(leagueData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  // build sql update statement
  const sql = `
    UPDATE
      league_management.leagues
    SET
      name = $1,
      description = $2,
      sport = $3,
      status = $4
    WHERE
      league_id = $5
    RETURNING
      slug
  `;

  // query the database
  const updatedResult: ResultProps<LeagueData> = await db
    .query(sql, [
      leagueData.name,
      leagueData.description,
      leagueData.sport,
      leagueData.status,
      leagueData.league_id,
    ])
    .then((res) => {
      return {
        message: "League updated",
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

  if (updatedResult?.data?.slug)
    redirect(createDashboardUrl({ l: updatedResult?.data?.slug }));

  return updatedResult;
}

export async function deleteLeague(state: { league_id: number }) {
  // Verify user session
  await verifySession();

  // set check for whether user has permission to delete
  let canDelete = false;

  // Check user role to see if they have admin privileges
  const isAdmin = await verifyUserRole(1);
  // if so, they can delete the league
  if (isAdmin) canDelete = true;

  // skip league admin check if already confirmed the user is a site wide admin
  if (!canDelete) {
    // do a check if user is the league commissioner
    const isCommissioner = await verifyLeagueAdminRole(state.league_id, 1);

    if (isCommissioner) canDelete = true;
  }

  if (!canDelete) {
    // failed both user role check and league role check, shortcut out
    return {
      message: "You do not have permission to delete this league.",
      status: 401,
    };
  }

  // create delete sql statement
  const sql = `
    DELETE FROM league_management.leagues
    WHERE league_id = $1
  `;

  // query the database
  const deleteResult = await db
    .query(sql, [state.league_id])
    .then(() => {
      return {
        message: "League deleted",
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  if (deleteResult.status === 400) {
    return deleteResult;
  }

  redirect("/dashboard/");
}
