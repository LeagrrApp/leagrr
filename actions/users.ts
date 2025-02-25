"use server";

import { db } from "@/db/pg";
import { createSession, verifySession } from "@/lib/session";
import {
  createDashboardUrl,
  createMetaTitle,
  nameDisplay,
} from "@/utils/helpers/formatting";
import { isObjectEmpty } from "@/utils/helpers/objects";
import bcrypt from "bcrypt";
import { redirect } from "next/navigation";
import { z } from "zod";
import { getDivisionStandings } from "./divisions";

/* ---------- READ ---------- */

export async function getUser(
  identifier?: number | string,
): Promise<ResultProps<UserData>> {
  const { user_id } = await verifySession();

  // initialize result status code
  let status = 400;

  try {
    const final_identifier = identifier || user_id;

    const sql = `
      SELECT
        user_id,
        username,
        email,
        first_name,
        last_name,
        gender,
        pronouns,
        user_role,
        img,
        status
      FROM
        admin.users
      WHERE
        ${typeof final_identifier === "string" ? "username" : "user_id"} = $1
    `;

    const { rows } = await db.query<UserData>(sql, [final_identifier]);

    if (!rows[0]) {
      status = 404;
      throw new Error("Could not find requested user.");
    }

    return {
      message: "User data retrieved.",
      data: rows[0],
      status: 200,
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

export async function getUserMetaData(
  username: string,
  options?: {
    prefix?: string;
  },
) {
  try {
    const sql = `
      SELECT
        first_name,
        last_name
      FROM
        admin.users
      WHERE
        username = $1
    `;

    const { rows } = await db.query(sql, [username]);

    const name = nameDisplay(rows[0].first_name, rows[0].last_name, "full");

    let title = createMetaTitle([name, "Users"]);

    if (options?.prefix) {
      title = createMetaTitle([options.prefix, name, "Users"]);
    }

    return {
      message: "User meta data retrieved.",
      status: 200,
      data: {
        title,
      },
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

export async function getUserRole(
  identifier?: string | number,
): Promise<ResultProps<{ user_role: number }>> {
  const { user_id } = await verifySession();

  // initialize result status code
  let status = 400;

  try {
    const final_identifier = identifier || user_id;

    const sql = `
      SELECT
        user_role
      FROM
        admin.users as u
      WHERE
        ${typeof final_identifier === "string" ? "username" : "user_id"} = $1
    `;

    const { rows } = await db.query(sql, [final_identifier]);

    if (!rows[0]) {
      status = 404;
      throw new Error("User not found.");
    }

    return {
      message: "User role loaded.",
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

export async function verifyUserRole(
  roleType: number,
  identifier?: string | number,
) {
  const { data } = await getUserRole(identifier);

  return !data || data.user_role === roleType;
}

export async function canEditUser(identifier: number | string) {
  // get logged in user_id
  const { user_id: logged_user_id } = await verifySession();

  // initialize response status code
  let status = 400;

  try {
    // Check if logged in user is site wide admin
    const isAdmin = await verifyUserRole(1);

    // if username is provided, look up users user_id in database
    let user_to_edit_id =
      typeof identifier === "number" ? identifier : undefined;

    if (typeof identifier === "string") {
      const userIdSql = `
        SELECT
          user_id
        FROM
          admin.users
        WHERE
          username = $1
      `;

      const { rows } = await db.query<{ user_id: number }>(userIdSql, [
        identifier,
      ]);

      if (!rows[0]) {
        status = 404;
        throw new Error("User not found.");
      }
      user_to_edit_id = rows[0].user_id;
    }

    const isCurrentUser = logged_user_id === user_to_edit_id;

    return {
      canEdit: isAdmin || isCurrentUser,
      isAdmin,
      isCurrentUser,
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

export async function getDashboardMenuData(): Promise<
  ResultProps<{
    teams: MenuItemData[];
    leagues: MenuItemData[];
  }>
> {
  const { user_id } = await verifySession();

  try {
    // get list of teams that the user is a part of
    const teamSql = `
      SELECT
        t.slug,
        t.name
      FROM
        league_management.teams AS t
      JOIN
        league_management.team_memberships as m
      ON
        m.team_id = t.team_id
      WHERE
        m.user_id = $1
      ORDER BY
        t.name ASC;
    `;

    const { rows: teams } = await db.query<MenuItemData>(teamSql, [user_id]);

    // get list of user run leagues
    const leagueSql = `
    SELECT
      l.name,
      l.slug,
      a.user_id
    FROM
      league_management.league_admins as a
    JOIN
      league_management.leagues as l
    ON
      l.league_id = a.league_id
    WHERE
      a.user_id = $1
    ORDER BY
      l.name ASC
  `;

    const { rows: leagues } = await db.query<MenuItemData>(leagueSql, [
      user_id,
    ]);

    return {
      message: "Dashboard data retrieved",
      status: 200,
      data: {
        teams: teams,
        leagues: leagues,
      },
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

export async function getUserTeams(identifier?: number | string) {
  const { user_id } = await verifySession();

  try {
    const final_identifier = identifier || user_id;

    const sql = `
      SELECT
        t.team_id,
        t.name,
        t.description,
        t.slug,
        t.color,
        t.status,
        tm.team_role
      FROM
        admin.users AS u
      JOIN
        league_management.team_memberships AS tm
      ON
        tm.user_id = u.user_id
      JOIN
        league_management.teams AS t
      ON
        tm.team_id = t.team_id
      WHERE
        ${typeof final_identifier === "string" ? "u.username" : "u.user_id"} = $1
        AND
        (
          t.status = 'active'
          OR
          t.status IN ('active', 'inactive', 'suspended')
          AND
          tm.team_role = 1
        )
    `;

    const { rows } = await db.query<TeamData>(sql, [final_identifier]);

    return {
      message: "User teams retrieved.",
      data: rows,
      status: 200,
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

export async function getUserRosters(
  identifier?: number | string,
  period?: "current" | "past" | "future",
) {
  const { user_id } = await verifySession();

  try {
    const final_identifier = identifier || user_id;

    let sql = `
      SELECT
        dr.division_roster_id, 
        tm.team_id,
        t.name AS team_name,
        t.slug AS team_slug,
        t.color AS team_color,
        d.name AS division_name,
        d.division_id AS division_id,
        d.slug AS division_slug,
        s.name AS season_name,
        s.season_id AS season_id,
        s.slug AS season_slug,
        l.name AS league_name,
        l.league_id AS league_id,
        l.slug AS league_slug
      FROM
        admin.users AS u
      JOIN
        league_management.team_memberships AS tm
      ON
        u.user_id = tm.user_id
      JOIN
        league_management.division_rosters AS dr
      ON
        dr.team_membership_id = tm.team_membership_id
      JOIN
        league_management.division_teams AS dt
      ON
        dt.division_team_id = dr.division_team_id
      JOIN
        league_management.teams AS t
      ON
        tm.team_id = t.team_id
      JOIN
        league_management.divisions AS d
      ON
        dt.division_id = d.division_id
      JOIN
        league_management.seasons AS s
      ON 
        d.season_id = s.season_id
      JOIN
        league_management.leagues AS l
      ON
        s.league_id = l.league_id
      WHERE
        ${typeof final_identifier === "string" ? "u.username" : "u.user_id"} = $1
        AND
        dr.roster_role IN (2, 3, 4)
    `;

    if (!period || period === "current") {
      sql =
        sql +
        `
      AND
      s.start_date < now()
      AND
      s.end_date > now()`;
    }

    if (period === "future") {
      sql =
        sql +
        `
      AND
      s.start_date > now()`;
    }

    if (period === "past") {
      sql =
        sql +
        `
      AND
      s.end_date < now()`;
    }

    sql =
      sql +
      `
      ORDER BY
        s.end_date ASC, league_name ASC, d.tier ASC, team_name ASC
    `;

    const { rows } = await db.query<UserRosterData>(sql, [final_identifier]);
    return {
      message: "User rosters retrieved.",
      data: rows,
      status: 200,
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

export async function getUserRostersWithStats(
  identifier?: number | string,
): Promise<
  ResultProps<
    {
      rosterInfo: UserRosterData;
      userDivisionStats?: UserRosterStats;
      teamStandings?: TeamStandingsData;
    }[]
  >
> {
  const { user_id } = await verifySession();

  try {
    const final_identifier = identifier || user_id;

    const userRostersResult = await getUserRosters(final_identifier);

    if (!userRostersResult.data)
      return {
        message: userRostersResult.message,
        status: userRostersResult.status,
      };

    const rosterList: {
      rosterInfo: UserRosterData;
      userDivisionStats?: UserRosterStats;
      teamStandings?: TeamStandingsData;
    }[] = [];

    for (const r of userRostersResult.data) {
      const { data: userDivisionStats } = await getUserStatsByDivision(
        r.division_id,
        r.team_id,
        final_identifier,
      );

      const { data: divisionStandings } = await getDivisionStandings(
        r.division_id,
      );

      let teamStandingData;

      divisionStandings?.forEach((t, i) => {
        if (t.team_id === r.team_id) {
          teamStandingData = {
            ...t,
            position: i + 1,
          };
        }
      });

      rosterList.push({
        rosterInfo: r,
        userDivisionStats,
        teamStandings: teamStandingData,
      });
    }

    return {
      message: "User roster stats loaded",
      status: 200,
      data: rosterList,
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

export async function getUserStatsByDivision(
  division_id: number,
  team_id: number,
  identifier?: number | string,
) {
  const { user_id } = await verifySession();

  try {
    const final_identifier = identifier || user_id;

    const sql = `
    SELECT 
      dr.position,
      dr.number,
      (SELECT COUNT(*) FROM stats.goals AS g WHERE g.user_id = tm.user_id AND g.game_id IN (
        SELECT game_id FROM league_management.games WHERE (home_team_id = tm.team_id OR away_team_id = tm.team_id) AND division_id = dt.division_id AND status = 'completed'
      ))::int AS goals,
      (SELECT COUNT(*) FROM stats.assists AS a WHERE a.user_id = tm.user_id AND a.game_id IN (
        SELECT game_id FROM league_management.games WHERE (home_team_id = tm.team_id OR away_team_id = tm.team_id) AND division_id = dt.division_id AND status = 'completed'
      ))::int AS assists,
      (
        (SELECT COUNT(*) FROM stats.goals AS g WHERE g.user_id = tm.user_id AND g.game_id IN (
          SELECT game_id FROM league_management.games WHERE (home_team_id = tm.team_id OR away_team_id = tm.team_id) AND division_id = dt.division_id AND status = 'completed'
        )) +
        (SELECT COUNT(*) FROM stats.assists AS a WHERE a.user_id = tm.user_id AND a.game_id IN (
          SELECT game_id FROM league_management.games WHERE (home_team_id = tm.team_id OR away_team_id = tm.team_id) AND division_id = dt.division_id AND status = 'completed'
        ))	
      )::int AS points,
      (SELECT COUNT(*) FROM stats.shots AS s WHERE s.user_id = tm.user_id AND s.game_id IN (
        SELECT game_id FROM league_management.games WHERE (home_team_id = tm.team_id OR away_team_id = tm.team_id) AND division_id = dt.division_id AND status = 'completed'
      ))::int AS shots,
      (SELECT COALESCE(SUM(minutes), 0) FROM stats.penalties AS p WHERE p.user_id = tm.user_id AND p.game_id IN (
        SELECT game_id FROM league_management.games WHERE (home_team_id = tm.team_id OR away_team_id = tm.team_id) AND division_id = dt.division_id AND status = 'completed'
      ))::int AS penalties_in_minutes,
      (SELECT COUNT(*) FROM stats.saves AS sa WHERE sa.user_id = tm.user_id AND sa.game_id IN (
        SELECT game_id FROM league_management.games WHERE (home_team_id = tm.team_id OR away_team_id = tm.team_id) AND division_id = dt.division_id AND status = 'completed'
      ))::int AS saves,
      (SELECT COUNT(*) FROM stats.goals AS goal WHERE goal.team_id != 2 AND goal.game_id IN (
        SELECT game_id FROM league_management.games WHERE (home_team_id = tm.team_id OR away_team_id = tm.team_id) AND division_id = dt.division_id AND status = 'completed'
      ))::int AS goals_against,
      (SELECT COUNT(*) FROM stats.shots AS sh WHERE sh.team_id != 2 AND sh.game_id IN (
        SELECT game_id FROM league_management.games WHERE (home_team_id = tm.team_id OR away_team_id = tm.team_id) AND division_id = dt.division_id AND status = 'completed'
      ))::int AS shots_against
    FROM
      league_management.division_rosters AS dr
    JOIN
      league_management.team_memberships AS tm
    ON
      dr.team_membership_id = tm.team_membership_id
    JOIN
      league_management.division_teams AS dt
    ON
      dt.division_team_id = dr.division_team_id
    JOIN
      league_management.teams AS t
    ON
      tm.team_id = t.team_id
    JOIN
      league_management.divisions AS d
    ON
      dt.division_id = d.division_id
    WHERE
      d.division_id = $1
      AND
      tm.team_id = $2
      AND
      ${
        typeof final_identifier === "string"
          ? `tm.user_id = (SELECT
          user_id
        FROM
          admin.users
        WHERE
          username = $3)`
          : `tm.user_id = $3`
      }
      AND
      dr.roster_role IN (2, 3, 4)
  `;

    const { rows } = await db.query<UserRosterStats>(sql, [
      division_id,
      team_id,
      final_identifier,
    ]);

    return {
      message: `User roster stats loaded!`,
      status: 200,
      data: rows[0],
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

export async function getUserManagedTeams(
  user_id?: number,
): Promise<ResultProps<TeamData[]>> {
  // verify session
  const { user_id: logged_user_id } = await verifySession();

  try {
    const final_user_id = user_id || logged_user_id;

    const sql = `
    SELECT 
      t.team_id,
      t.name,
      t.slug,
      tm.team_role
    FROM
      league_management.team_memberships AS tm
    JOIN
      league_management.teams AS t
    ON
      tm.team_id = t.team_id
    WHERE
      tm.user_id = $1
      AND
      tm.team_role = 1
    ORDER BY t.name
  `;

    const { rows } = await db.query<TeamData>(sql, [final_user_id]);
    return {
      message: `Managed teams found!`,
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

export async function getUserManagedTeamsForJoinDivision(
  division_id: number,
  user_id?: number,
): Promise<ResultProps<TeamData[]>> {
  // verify session
  const { user_id: logged_user_id } = await verifySession();

  try {
    const id = user_id || logged_user_id;

    const sql = `
    SELECT 
      t.team_id,
      t.name,
      t.slug,
      tm.team_role
    FROM
      league_management.team_memberships AS tm
    JOIN
      league_management.teams AS t
    ON
      tm.team_id = t.team_id
    WHERE
      tm.user_id = $1
      AND
      tm.team_role = 1
      AND
      t.team_id NOT IN (SELECT team_id FROM league_management.division_teams WHERE division_id = $2)
    ORDER BY t.name
  `;

    const { rows } = await db.query<TeamData>(sql, [id, division_id]);

    return {
      message: `Managed teams found!`,
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

export async function getUserGamePreviews(
  user_id: number,
  pastGames?: boolean,
): Promise<ResultProps<GameData>>;
export async function getUserGamePreviews(
  user_id: number,
  pastGames = false,
  limit = 1,
): Promise<ResultProps<GameData | GameData[]>> {
  // initialize result status code
  let status = 400;

  try {
    const sql = `
    SELECT
      g.division_id,
      g.game_id,
      g.home_team_id,
      ht.name AS home_team,
      ht.color AS home_team_color,
      ht.slug AS home_team_slug,
      count(DISTINCT
        CASE
          WHEN s.team_id = ht.team_id THEN s.shot_id
          ELSE null
        END
      ) AS home_team_shots,
      g.home_team_score,
      g.away_team_id,
      at.name AS away_team,
      at.color AS away_team_color,
      at.slug AS away_team_slug,
      count(DISTINCT
        CASE
          WHEN s.team_id = at.team_id THEN s.shot_id
          ELSE null
        END
      ) AS away_team_shots,
      g.away_team_score,
      g.date_time,
      g.arena_id,
      a.name AS arena,
      v.name AS venue,
      g.status
    FROM
      league_management.games AS g
    JOIN
      league_management.division_teams AS dt
    ON
      dt.team_id IN (g.home_team_id, g.away_team_id)
    JOIN
      league_management.division_rosters AS dr
    ON
      dr.division_team_id = dt.division_team_id
    JOIN
      league_management.team_memberships AS tm
    ON
      dr.team_membership_id = tm.team_membership_id
    LEFT JOIN
      league_management.teams AS ht
    ON
      g.home_team_id = ht.team_id
    LEFT JOIN
      league_management.teams AS at
    ON
      g.away_team_id = at.team_id
    LEFT JOIN
      league_management.arenas AS a
    ON
      g.arena_id = a.arena_id
    LEFT JOIN
      league_management.venues AS v
    ON
      a.venue_id = v.venue_id
    LEFT JOIN
      stats.shots AS s
    ON
      g.game_id = s.game_id
    WHERE
      tm.user_id = $1
      AND
      g.status = ${pastGames ? "'completed'" : "'public'"}
      AND
      g.date_time ${pastGames ? "<" : ">"} now()
    GROUP BY
      g.game_id, ht.name, ht.color, ht.slug, at.name, at.color, at.slug, a.name, v.name
    ORDER BY
      g.date_time ${pastGames ? "DESC" : "ASC"}
    LIMIT $2
  `;

    const { rows } = await db.query<GameData>(sql, [user_id, limit]);

    if (!rows[0]) {
      status = 404;
      throw new Error("Sorry, no game(s) found!");
    }

    if (limit === 1) {
      return {
        message: `Game found!`,
        status: 200,
        data: rows[0],
      };
    }
    return {
      message: `Games found!`,
      status: 200,
      data: rows,
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

/* ---------- UPDATE ---------- */

const EditUserSchema = z.object({
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
  gender: z.string().optional(),
  pronouns: z.string().optional(),
});

export async function editUser(
  state: UserFormState,
  formData: FormData,
): Promise<UserFormState> {
  // organize submitted data
  const submittedData = {
    user_id: parseInt(formData.get("user_id") as string),
    username: formData.get("username") as string,
    email: formData.get("email") as string,
    first_name: formData.get("first_name") as string,
    last_name: formData.get("last_name") as string,
    gender: formData.get("gender") as string,
    pronouns: formData.get("pronouns") as string,
  };

  // Validate data
  const validatedFields = EditUserSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      data: submittedData,
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  // initialize result status code
  let status = 400;

  // initialize redirect link
  let redirectLink: string | undefined = undefined;

  try {
    // check if user can edit the user
    const { canEdit, isCurrentUser } = await canEditUser(submittedData.user_id);

    if (!canEdit) {
      status = 401;
      throw new Error("You do not have permission to edit this user!");
    }

    const sql = `
      UPDATE admin.users
      SET
        username = $1,
        email = $2,
        first_name = $3,
        last_name = $4,
        gender = $5,
        pronouns = $6
      WHERE
        user_id = $7
      RETURNING
      ${
        isCurrentUser
          ? `user_id,
          username,
          user_role,
          first_name,
          last_name,
          img`
          : `username`
      }
    `;

    const { rows } = await db.query<UserSessionData>(sql, [
      submittedData.username,
      submittedData.email,
      submittedData.first_name,
      submittedData.last_name,
      submittedData.gender,
      submittedData.pronouns,
      submittedData.user_id,
    ]);

    if (!rows[0])
      throw new Error("Sorry, there was a problem updating the user.");

    if (isCurrentUser) {
      await createSession(rows[0]);
    }

    redirectLink = createDashboardUrl({ u: rows[0].username }, "edit");
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

  if (redirectLink) redirect(redirectLink);
}

const PasswordSchema = z.object({
  current_password: z.string().trim(),
  new_password: z
    .string()
    .min(8, { message: "Be at least 8 characters long" })
    .regex(/[a-zA-Z]/, { message: "Contain at least one letter." })
    .regex(/[0-9]/, { message: "Contain at least one number." })
    .regex(/[^a-zA-Z0-9]/, {
      message: "Contain at least one special character.",
    })
    .trim(),
  confirm_password: z.string().trim(),
  user_id: z.number().min(1),
});

type PasswordFormErrors = {
  current_password?: string[] | undefined;
  new_password?: string[] | undefined;
  confirm_password?: string[] | undefined;
  user_id?: string[] | undefined;
};

type PasswordFormState = FormState<
  PasswordFormErrors,
  {
    current_password: string;
    new_password: string;
    confirm_password: string;
    user_id: number;
  }
>;

export async function updatePassword(
  state: PasswordFormState,
  formData: FormData,
): Promise<PasswordFormState> {
  const submittedData = {
    current_password: formData.get("current_password") as string,
    new_password: formData.get("new_password") as string,
    confirm_password: formData.get("confirm_password") as string,
    user_id: parseInt(formData.get("user_id") as string),
  };

  // initialize errors array
  let errors: PasswordFormErrors = {};

  // initialize response status code
  let status = 400;

  try {
    // Validate data
    const validatedFields = PasswordSchema.safeParse(submittedData);

    // If any form fields are invalid, add errors to list
    if (!validatedFields.success) {
      errors = validatedFields.error.flatten().fieldErrors;
    }

    // check if passwords match
    if (submittedData.new_password !== submittedData.confirm_password) {
      errors.confirm_password = ["Passwords must match!"];
    }

    // If there are any errors, return the errors
    if (!isObjectEmpty(errors)) {
      throw new Error("There are errors in your password data.");
    }

    const { isCurrentUser } = await canEditUser(submittedData.user_id);

    if (!isCurrentUser) {
      status = 401;
      throw new Error(
        "You are only permitted to change your own password. If a user needs their password reset, use the reset password functionality.",
      );
    }

    // get user's current password from DB
    const selectSql = `
      SELECT
        password_hash
      FROM
        admin.users
      WHERE
        user_id = $1
    `;

    const { rows: passwordHashRows } = await db.query<{
      password_hash: string;
    }>(selectSql, [submittedData.user_id]);

    if (!passwordHashRows[0]) {
      status = 404;
      throw new Error("User not found.");
    }

    const { password_hash } = passwordHashRows[0];

    // compare passwords
    const passwordsMatch = await bcrypt.compare(
      submittedData.current_password,
      password_hash,
    );

    if (!passwordsMatch) {
      status = 401;
      errors.current_password = ["Password is incorrect"];
      throw new Error("Passwords do not match.");
    }

    // hash new_password
    const hashed_new_password = await bcrypt.hash(
      submittedData.new_password,
      10,
    );

    // build update sql statement
    const updateSql = `
      UPDATE admin.users
      SET
        password_hash = $1
      WHERE
        user_id = $2
    `;

    // query the database
    const { rowCount } = await db.query(updateSql, [
      hashed_new_password,
      submittedData.user_id,
    ]);

    if (rowCount !== 1)
      throw new Error("Sorry, there was a problem updating password.");

    return {
      message: "Password successfully updated.",
      status: 200,
      data: submittedData,
    };
  } catch (err) {
    if (err instanceof Error) {
      return {
        ...state,
        errors,
        message: err.message,
        status,
        data: submittedData,
      };
    }
    return {
      ...state,
      errors,
      message: "Something went wrong.",
      status: 500,
      data: submittedData,
    };
  }
}
