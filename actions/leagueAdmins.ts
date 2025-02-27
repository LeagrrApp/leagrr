"use server";

import { db } from "@/db/pg";
import { verifySession } from "@/lib/session";
import { redirect } from "next/navigation";
import { z } from "zod";
import { canEditLeague, getLeagueIdFromSlug } from "./leagues";

const LeagueAdminSchema = z.object({
  league_id: z.number().min(1),
  league_admin_id: z.number().min(1).optional(),
  league_role: z.number().min(1).max(2).optional(),
  user_id: z.number().min(1).optional(),
});

interface LeagueAdminErrorProps {
  league_id?: string[] | undefined;
  league_admin_id?: string[] | undefined;
  league_role?: string[] | undefined;
  user_id?: string[] | undefined;
}

type LeagueAdminFormState = FormState<
  LeagueAdminErrorProps,
  {
    league_id?: number;
    league_admin_id?: number;
    league_role?: number;
    user_id?: number;
  }
>;

/* ---------- CREATE ---------- */

export async function createLeagueAdmin(
  state: LeagueAdminFormState,
  formData: FormData,
): Promise<LeagueAdminFormState> {
  await verifySession();

  const submittedData = {
    league_id: parseInt(formData.get("league_id") as string),
    league_role: parseInt(formData.get("league_role") as string),
    user_id: parseInt(formData.get("user_id") as string),
  };

  // initialize success check
  let success = false;

  // initialize response status code.
  let status = 400;

  try {
    const { isAdmin, isCommissioner } = await canEditLeague(
      submittedData.league_id,
    );

    if (!isAdmin && !isCommissioner) {
      status = 401;
      throw new Error("Sorry, you do not have permission to add admins.");
    }

    // Validate form fields
    const validatedFields = LeagueAdminSchema.safeParse(submittedData);

    // If any form fields are invalid, return early
    if (!validatedFields.success) {
      return {
        errors: validatedFields.error.flatten().fieldErrors,
        data: submittedData,
      };
    }

    // TODO: check if already an admin

    // build insert sql
    const sql = `
      INSERT INTO league_management.league_admins
        (league_id, user_id, league_role)
      VALUES
        ($1, $2, $3)
    `;

    const { rowCount } = await db.query(sql, [
      submittedData.league_id,
      submittedData.user_id,
      submittedData.league_role,
    ]);

    if (rowCount !== 1)
      throw new Error("Sorry, there was a problem adding league admin.");

    success = true;
  } catch (err) {
    if (err instanceof Error) {
      return {
        ...state,
        message: err.message,
        status,
        data: submittedData,
      };
    }
    return {
      ...state,
      message: "Something went wrong.",
      status: 500,
      data: submittedData,
    };
  }

  if (success && state?.link) redirect(state.link);
}

/* ---------- READ ---------- */

export async function getLeagueAdminData(
  league: number | string,
  options?: {
    user_id?: number;
  },
): Promise<ResultProps<LeagueAdminData>> {
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
    const { rows } = await db.query<LeagueAdminData>(adminsSql, [
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

export async function getLeagueAdmins(league: number | string) {
  // Verify user session
  await verifySession();

  try {
    const sql = `
      SELECT
        la.league_admin_id,
        la.league_role,
        u.user_id,
        u.username,
        u.first_name,
        u.last_name
      FROM
        league_management.league_admins AS la
      JOIN
        league_management.leagues AS l
      ON
        la.league_id = l.league_id
      JOIN
        admin.users AS u
      ON
        la.user_id = u.user_id
      WHERE
        l.${typeof league === "string" ? "slug" : "league_id"} = $1
      ORDER BY
        u.last_name ASC, u.first_name ASC
    `;

    const { rows } = await db.query<LeagueAdminData>(sql, [league]);

    return {
      message: "League admins loaded.",
      status: 200,
      data: rows,
    };
  } catch (err) {
    if (err instanceof Error) {
      return {
        message: err.message,
        status: 400,
      };
    }
    return {
      message: "Something went wrong.",
      status: 500,
    };
  }
}

/* ---------- UPDATE ---------- */

export async function editLeagueAdmin(
  state: LeagueAdminFormState,
  formData: FormData,
): Promise<LeagueAdminFormState> {
  const submittedData = {
    league_id: parseInt(formData.get("league_admin_id") as string),
    league_admin_id: parseInt(formData.get("league_admin_id") as string),
    league_role: parseInt(formData.get("league_role") as string),
  };

  // initialize response status code.
  let status = 400;

  try {
    const { isAdmin, isCommissioner } = await canEditLeague(
      submittedData.league_id,
    );

    if (!isAdmin && !isCommissioner) {
      status = 401;
      throw new Error(
        "Sorry, you do not have permission to change admin roles.",
      );
    }

    // Validate form fields
    const validatedFields = LeagueAdminSchema.safeParse(submittedData);

    // If any form fields are invalid, return early
    if (!validatedFields.success) {
      return {
        errors: validatedFields.error.flatten().fieldErrors,
        data: submittedData,
      };
    }

    // TODO:  check if there is at least one other commissioner
    //        before allowing the role to be change from commissioner to manager

    // build update sql
    const sql = `
      UPDATE league_management.league_admins
      SET
        league_role = $1
      WHERE
        league_admin_id = $2
      RETURNING
        league_role
    `;

    const { rows } = await db.query<{ league_role: number }>(sql, [
      submittedData.league_role,
      submittedData.league_admin_id,
    ]);

    if (!rows[0])
      throw new Error("Sorry, there was a problem updating league admin.");

    return {
      message: "League admin successfully updated.",
      status: 200,
      data: {
        league_role: rows[0].league_role,
        league_admin_id: submittedData.league_admin_id,
      },
    };
  } catch (err) {
    if (err instanceof Error) {
      return {
        ...state,
        message: err.message,
        status,
        data: submittedData,
      };
    }
    return {
      ...state,
      message: "Something went wrong.",
      status: 500,
      data: submittedData,
    };
  }
}

/* ---------- DELETE ---------- */
export async function removeLeagueAdmin(
  state: LeagueAdminFormState,
  formData: FormData,
): Promise<LeagueAdminFormState> {
  const submittedData = {
    league_id: parseInt(formData.get("league_admin_id") as string),
    league_admin_id: parseInt(formData.get("league_admin_id") as string),
  };

  // initialize response status code.
  let status = 400;

  try {
    const { isAdmin, isCommissioner } = await canEditLeague(
      submittedData.league_id,
    );

    if (!isAdmin && !isCommissioner) {
      status = 401;
      throw new Error(
        "Sorry, you do not have permission to remove admin roles.",
      );
    }

    // Validate form fields
    const validatedFields = LeagueAdminSchema.safeParse(submittedData);

    // If any form fields are invalid, return early
    if (!validatedFields.success) {
      return {
        errors: validatedFields.error.flatten().fieldErrors,
        data: submittedData,
      };
    }

    // TODO:  check if there is at least one other commissioner before removing

    // build delete sql
    const sql = `
      DELETE FROM league_management.league_admins
      WHERE
        league_admin_id = $1
    `;

    const { rowCount } = await db.query(sql, [submittedData.league_admin_id]);

    if (rowCount !== 1)
      throw new Error("Sorry, there was a problem removing league admin.");

    return {
      message: "League admin successfully removed.",
      status: 200,
      data: {
        league_admin_id: submittedData.league_admin_id,
      },
    };
  } catch (err) {
    if (err instanceof Error) {
      return {
        ...state,
        message: err.message,
        status,
        data: submittedData,
      };
    }
    return {
      ...state,
      message: "Something went wrong.",
      status: 500,
      data: submittedData,
    };
  }
}
