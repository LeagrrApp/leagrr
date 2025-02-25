"use server";

import { db } from "@/db/pg";
import {
  league_roles,
  sports_options,
  status_options,
} from "@/lib/definitions";
import { verifySession } from "@/lib/session";
import {
  createDashboardUrl,
  createMetaTitle,
} from "@/utils/helpers/formatting";
import { redirect } from "next/navigation";
import { z } from "zod";
import { getSeasonsByLeague } from "./seasons";
import { verifyUserRole } from "./users";

/* ---------- CREATE ---------- */

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

type LeagueFormState = FormState<
  LeagueErrorProps,
  {
    name: string;
    description: string;
    sport: string;
    status?: string;
    league_id?: number;
  }
>;

export async function createLeague(
  state: LeagueFormState,
  formData: FormData,
): Promise<LeagueFormState> {
  // Verify user session
  const { user_id } = await verifySession();

  // TODO: add user role permission check

  // insert data from form into object that can be checked for errors
  const submittedData = {
    name: formData.get("name") as string,
    description: formData.get("description") as string,
    sport: formData.get("sport") as string,
  };

  // Validate form fields
  const validatedFields = LeagueFormSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      errors: validatedFields.error.flatten().fieldErrors,
      data: submittedData,
    };
  }

  // initialize redirect link
  let redirectLink: string | undefined = undefined;

  // no validation errors, submit data to database
  try {
    // Build insert sql statement
    const leagueInsertSql = `
      INSERT INTO league_management.leagues
        (name, description, sport)
      VALUES
        ($1, $2, $3)
      RETURNING league_id, slug
    `;

    // Insert new league into the database
    const { rows: leagueRows } = await db.query<{
      league_id: number;
      slug: string;
    }>(leagueInsertSql, [
      submittedData.name,
      submittedData.description,
      submittedData.sport,
    ]);

    // if no data was returned, throw an error
    if (!leagueRows[0]) {
      throw new Error("Sorry, there was an error creating the league.");
    }

    // get league_id and slug generated and returned by the database
    const { league_id, slug } = leagueRows[0];

    // Insert user and league into the league_admins table as Commissioner (league_role_id = 1)
    const leagueAdminSql = `
      INSERT INTO league_management.league_admins (league_role, league_id, user_id)
      VALUES (1, $1, $2)
      RETURNING
        league_admin_id
    `;

    const { rows: adminRows } = await db.query<{ league_admin_id: number }>(
      leagueAdminSql,
      [league_id, user_id],
    );

    // Failed to add user as league admin, delete the league and return error
    if (!adminRows[0]) {
      // TODO: delete the league on this error

      throw new Error("Unable to set user as league admin.");
    }

    // set redirect link
    redirectLink = createDashboardUrl({ l: slug });
  } catch (err) {
    if (err instanceof Error) {
      return {
        message: err.message,
        status: 400,
        data: submittedData,
      };
    }
    return {
      message: "Something went wrong.",
      status: 500,
      data: submittedData,
    };
  }

  // Redirect to the new league page
  if (redirectLink) redirect(redirectLink);
}

/* ---------- READ ---------- */

export async function getLeague(
  identifier: string | number,
  options?: {
    includeSeasons?: boolean;
  },
): Promise<ResultProps<LeagueData>> {
  // Verify user session
  await verifySession();

  try {
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
      ${typeof identifier === "string" ? `l.slug` : `l.league_id`} = $1
  `;

    // make request to database for leagues
    const { rows: leagueRows } = await db.query<LeagueData>(leagueSql, [
      identifier,
    ]);

    // if the league was not found, throw error
    if (!leagueRows[0]) throw new Error("League not found.");

    // data to return
    const data = leagueRows[0];

    if (options?.includeSeasons) {
      const { data: seasons } = await getSeasonsByLeague(identifier);

      data.seasons = seasons;
    }

    // combine all retrieved data into a single data object and return
    return {
      message: "League data found.",
      status: 200,
      data,
    };
  } catch (err) {
    if (err instanceof Error) {
      return { message: err.message, status: 400 };
    }
    return { message: "Something went wrong.", status: 500 };
  }
}

export async function getLeagueMetaData(
  league: string | number,
  options?: {
    prefix?: string;
  },
) {
  try {
    const sql = `
      SELECT
        name,
        description
      FROM
        league_management.leagues
      WHERE
        ${typeof league === "string" ? `slug` : `league_id`} = $1
    `;

    const { rows } = await db.query<{ name: string; description: string }>(
      sql,
      [league],
    );

    let title = createMetaTitle([rows[0].name]);

    if (options?.prefix)
      title = createMetaTitle([options.prefix, rows[0].name]);

    return {
      message: "League metadata loaded",
      status: 200,
      data: {
        title,
        description: rows[0].description,
      },
    };
  } catch (err) {
    if (err instanceof Error)
      return {
        message: err.message,
        status: 400,
      };

    return {
      message: "Sorry, something went wrong.",
      status: 500,
    };
  }
}

export async function getLeagueIdFromSlug(slug: string) {
  try {
    const sql = `
      SELECT
        league_id
      FROM
        league_management.leagues
      WHERE
        slug = $1
    `;

    const { rows } = await db.query<{ league_id: number }>(sql, [slug]);

    if (!rows[0]) throw new Error("League not found!");

    return {
      message: "League id found!",
      status: 200,
      data: { league_id: rows[0].league_id },
    };
  } catch (err) {
    if (err instanceof Error) {
      return { message: err.message, status: 400 };
    }
    return { message: "Something went wrong.", status: 500 };
  }
}

export async function getLeagueAdminRole(
  league: number | string,
  options?: {
    user_id?: number;
  },
): Promise<ResultProps<AdminRole>> {
  // Verify user session
  const { user_id: logged_user_id } = await verifySession();

  // initialize status
  let status = 400;

  try {
    const final_user_id = options?.user_id || logged_user_id;

    let league_id = league;

    if (typeof league === "string") {
      // league slug was provided, but need league_id to check role

      // get league_id
      const { data } = await getLeagueIdFromSlug(league);

      if (data?.league_id) league_id = data?.league_id;
    }

    // Unable to find league_id, therefore short circuit out
    if (typeof league_id === "string")
      throw new Error("Unable to verify user\'s admin role status.");

    // build sql select statement using league_id
    const adminsSql = `
      SELECT
        league_role
      FROM
        league_management.league_admins
      WHERE
        league_id = $1 AND user_id = $2
    `;

    // query database for any matching both league and user
    const { rows } = await db.query<AdminRole>(adminsSql, [
      league_id,
      final_user_id,
    ]);

    if (!rows[0]) {
      status = 401;
      throw new Error("User does not have a league admin role.");
    }

    return {
      message: "User league admin role found.",
      status: 200,
      data: rows[0],
    };
  } catch (err) {
    if (err instanceof Error) {
      return {
        message: err.message,
        status,
      };
    }
    return {
      message: "Something went wrong.",
      status: 500,
    };
  }
}

export async function verifyLeagueAdminRole(
  league: number | string,
  roleType: number,
  options?: {
    user_id?: number;
  },
): Promise<boolean> {
  const { data } = await getLeagueAdminRole(league, options);

  if (!data?.league_role) return false;

  return data.league_role === roleType;
}

export async function canEditLeague(
  league: number | string,
  options?: {
    user_id?: number;
    commissionerOnly?: boolean;
  },
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
    const { data } = await getLeagueAdminRole(league);

    // verify which role the user has
    if (data?.league_role) {
      // set canEdit based on whether it is a commissionerOnly check or not
      canEdit = options?.commissionerOnly
        ? data.league_role === 1
        : data.league_role === 1 || data.league_role === 2;
      // set name of role
      role = league_roles.get(data.league_role);
    }
  }

  return {
    canEdit,
    role,
  };
}

/* ---------- UPDATE ---------- */

export async function editLeague(
  state: LeagueFormState,
  formData: FormData,
): Promise<LeagueFormState> {
  // Verify user session
  await verifySession();

  // insert data from form into object that can be checked for errors
  const submittedData = {
    name: formData.get("name") as string,
    description: formData.get("description") as string,
    sport: formData.get("sport") as string,
    status: formData.get("status") as string,
    league_id: parseInt(formData.get("league_id") as string),
  };

  // check if user can edit league
  const { canEdit } = await canEditLeague(submittedData.league_id);

  if (!canEdit) {
    // failed both user role check and league role check, shortcut out
    return {
      message: "You do not have permission to edit this league.",
      status: 401,
      data: submittedData,
    };
  }

  // Validate form fields
  const validatedFields = LeagueFormSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      errors: validatedFields.error.flatten().fieldErrors,
      data: submittedData,
    };
  }

  // set redirect link holder;
  let redirectLink: string | undefined = undefined;

  try {
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
    const { rows } = await db.query<LeagueData>(sql, [
      submittedData.name,
      submittedData.description,
      submittedData.sport,
      submittedData.status,
      submittedData.league_id,
    ]);

    if (!rows[0]) throw new Error("There was a problem updating the league.");

    redirectLink = createDashboardUrl({ l: rows[0].slug });
  } catch (err) {
    if (err instanceof Error) {
      return {
        message: err.message,
        status: 400,
        data: submittedData,
      };
    }
    return {
      message: "Something went wrong.",
      status: 500,
      data: submittedData,
    };
  }

  // Redirect to the new league page
  if (redirectLink) redirect(redirectLink);
}

/* ---------- DELETE ---------- */

export async function deleteLeague(state: { data: { league_id: number } }) {
  // Verify user session
  await verifySession();

  try {
    if (!state.data) throw new Error("Sorry, something when wrong.");

    // set check for whether user has permission to delete
    let canDelete = false;

    // Check user role to see if they have admin privileges
    const isAdmin = await verifyUserRole(1);
    // if so, they can delete the league
    if (isAdmin) canDelete = true;

    // skip league admin check if already confirmed the user is a site wide admin
    if (!canDelete) {
      // do a check if user is the league commissioner
      const isCommissioner = await verifyLeagueAdminRole(
        state.data.league_id,
        1,
      );

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
    const { rowCount } = await db.query(sql, [state.data.league_id]);

    if (rowCount !== 1) throw new Error("There was a problem deleting league.");
  } catch (err) {
    if (err instanceof Error) {
      return {
        message: err.message,
        status: 400,
        ...state,
      };
    }
    return {
      message: "Something went wrong.",
      status: 500,
      ...state,
    };
  }

  redirect("/dashboard/");
}
