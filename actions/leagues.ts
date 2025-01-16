"use server";

import { db } from "@/db/pg";
import { LeagueFormSchema, LeagueFormState } from "@/lib/definitions";
import { redirect } from "next/navigation";
import { verifyUserRole } from "./users";
import { verifySession } from "@/lib/session";

interface LeagueResultProps extends ResultProps {
  data?: {
    league_id: number;
    slug: string;
  };
}

export async function createLeague(
  state: LeagueFormState,
  formData: FormData
): Promise<LeagueFormState> {
  // Verify user session
  const { user_id } = await verifySession();

  // insert data from form into object that can be checked for errors
  const leagueData = {
    name: formData.get("name"),
    description: formData.get("description"),
    sport_id: parseInt(formData.get("sport_id") as string),
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
      (name, description, sport_id)
    VALUES
      ($1, $2, $3)
    RETURNING league_id, slug
  `;

  // Insert new league into the database
  const leagueInsertResult: LeagueResultProps = await db
    .query(leagueInsertSql, [
      leagueData.name,
      leagueData.description,
      leagueData.sport_id,
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
    INSERT INTO league_management.league_admins (league_role_id, league_id, user_id)
    VALUES (1, $1, $2)
  `;

  const leagueAdminInsertResult = await db
    .query(leagueAdminSql, [league_id, user_id])
    .then((res) => {
      console.log("league_admins", res);
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
    return leagueAdminInsertResult;
  }

  // Success route, redirect to the new league page
  redirect(`/dashboard/l/${slug}`);
}

interface LeagueResult extends ResultProps {
  data?: LeagueData;
}

interface SeasonData {
  slug: string;
  name: string;
  status: string;
}

interface SeasonsResult extends ResultProps {
  data?: {
    seasons: SeasonData[];
  };
}

interface AdminsResult extends ResultProps {
  data?: {
    league_role_id: number | undefined;
  };
}

export async function verifyLeagueAdminRole(
  league_id: number,
  roleType?: number
): Promise<AdminsResult | boolean> {
  // Verify user session
  const { user_id } = await verifySession();

  // build sql select statement
  const adminsSql = `
    SELECT
      league_role_id
    FROM
      league_management.league_admins
    WHERE
      league_id = $1 AND user_id = $2
  `;

  // query database for any matching both league and user
  const adminsResult: AdminsResult = await db
    .query(adminsSql, [league_id, user_id])
    .then((res) => {
      if (res.rowCount) {
        return {
          message: "User has league admin role",
          data: {
            league_role_id: res.rows[0].league_role_id,
          },
          status: 200,
        };
      }

      return {
        message: "User doest not have league admin role",
        data: {
          league_role_id: undefined,
        },
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: `There was a problem verifying the user's admin status: ${err.message}`,
        status: 400,
        data: {
          league_role_id: undefined,
        },
      };
    });

  if (roleType) return adminsResult.data?.league_role_id === roleType;

  return adminsResult;
}

export async function getLeagueData(slug: string): Promise<LeagueResult> {
  // Verify user session
  await verifySession();

  // build league select statement
  const leagueSql = `
    SELECT
      league_id,
      name,
      description,
      sport_id,
      (SELECT name FROM admin.sports as s WHERE s.sport_id = l.sport_id) as sport,
      status
    FROM
      league_management.leagues as l
    WHERE
      l.slug = $1
  `;

  // make request to database for leagues
  const leagueResult: LeagueResult = await db
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
        status: 400,
      };
    });

  // if the league was not found, return error
  if (!leagueResult.data) return leagueResult;

  // build select statement to get all seasons for associated league
  const seasonsSql = `
    SELECT
      slug,
      name,
      status
    FROM
      league_management.seasons
    WHERE
      league_id = $1
    ORDER BY end_date DESC
  `;

  // make request to database for seasons
  const seasonsResult: SeasonsResult = await db
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

  const adminsResult = await verifyLeagueAdminRole(leagueResult.data.league_id);
  // TODO: add short circuit if there is an error getting league admins

  // combine all retrieved data into a single data object and return
  return {
    message: "League data found.",
    status: 200,
    data: {
      ...leagueResult.data,
      ...seasonsResult.data,
      league_role_id:
        typeof adminsResult === "object"
          ? adminsResult?.data?.league_role_id
          : undefined,
    },
  };
}

export async function editLeague(
  state: LeagueFormState,
  formData: FormData
): Promise<LeagueFormState> {
  // Verify user session
  await verifySession();

  // insert data from form into object that can be checked for errors
  const leagueData = {
    name: formData.get("name"),
    description: formData.get("description"),
    sport_id: parseInt(formData.get("sport_id") as string),
    status: formData.get("status"),
    league_id: parseInt(formData.get("league_id") as string),
  };

  // set check for whether user has permission to delete
  let canEdit = false;

  // Check user role to see if they have admin privileges
  const isAdmin = await verifyUserRole(1);
  // if so, they can delete the league
  if (isAdmin) canEdit = true;

  // skip league admin check if already confirmed the user is a site wide admin
  if (!canEdit) {
    // do a check if user is the league commissioner
    const adminsResult = await verifyLeagueAdminRole(leagueData.league_id);

    if (typeof adminsResult === "object")
      canEdit = adminsResult?.data?.league_role_id === (1 || 2);
  }

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
      sport_id = $3,
      status = $4
    WHERE
      league_id = $5
    RETURNING
      slug
  `;

  // query the database
  const updatedResult: LeagueResultProps = await db
    .query(sql, [
      leagueData.name,
      leagueData.description,
      leagueData.sport_id,
      leagueData.status,
      leagueData.league_id,
    ])
    .then((res) => {
      console.log(res);
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
    redirect(`/dashboard/l/${updatedResult?.data?.slug}`);

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
  const deleteResult = db
    .query(sql, [state.league_id])
    .then((res) => {
      return {
        message: "League deleted",
        data: res.rows[0],
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  redirect("/dashboard/");

  return deleteResult;
}
