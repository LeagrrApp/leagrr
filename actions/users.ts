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

export async function getDashboardMenuData(): Promise<
  ResultProps<{
    teams: MenuItemData[];
    leagues: MenuItemData[];
  }>
> {
  const { user_id } = await verifySession();

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

  const teamsResult: {
    message: string;
    status: number;
    data?: MenuItemData[];
  } = await db
    .query(teamSql, [user_id])
    .then((res) => {
      return {
        message: "User team data retrieved.",
        data: res.rows,
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  if (!teamsResult.data) {
    return {
      message: teamsResult.message,
      status: teamsResult.status,
    };
  }

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

  const leaguesResult: {
    message: string;
    status: number;
    data?: MenuItemData[];
  } = await db
    .query(leagueSql, [user_id])
    .then((res) => {
      return {
        message: "User league data retrieved.",
        data: res.rows,
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  if (!leaguesResult.data) {
    return {
      message: leaguesResult.message,
      status: leaguesResult.status,
    };
  }

  return {
    message: "Dashboard data retrieved",
    status: 200,
    data: {
      teams: teamsResult.data,
      leagues: leaguesResult.data,
    },
  };
}

export async function getUser(
  identifier?: number | string,
): Promise<ResultProps<UserData>> {
  const { user_id } = await verifySession();

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

  const result: { message: string; status: number; data?: UserData } = await db
    .query(sql, [final_identifier])
    .then((res) => {
      if (!res.rowCount) {
        throw new Error("Could not find requested user.");
      }
      return {
        message: "User data retrieved.",
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

  return result;
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
): Promise<number> {
  const { user_id } = await verifySession();

  const final_identifier = identifier || user_id;

  const sql = `
    SELECT
      user_role
    FROM
      admin.users as u
    WHERE
      ${typeof final_identifier === "string" ? "username" : "user_id"} = $1
  `;

  const result: number = await db
    .query(sql, [final_identifier])
    .then((res) => {
      if (!res.rowCount) {
        throw new Error("User not found.");
      }

      return res.rows[0].user_role;
    })
    .catch(() => {
      // TODO: add more comprehensive error handling
      return 0;
    });

  return result;
}

export async function verifyUserRole(
  roleType: number,
  identifier?: string | number,
) {
  const user_role = await getUserRole(identifier);

  return user_role === roleType;
}

export async function canEditUser(identifier: number | string) {
  // get logged in user_id
  const { user_id: logged_user_id } = await verifySession();

  // Check if logged in user is site wide admin
  const isAdmin = await verifyUserRole(1);

  // if username is provided, look up users user_id in database
  let user_to_edit_id = typeof identifier === "number" ? identifier : undefined;

  if (typeof identifier === "string") {
    const userIdSql = `
      SELECT
        user_id
      FROM
        admin.users
      WHERE
        username = $1
    `;

    await db.query(userIdSql, [identifier]).then((res) => {
      if (res.rowCount === 0) {
        throw new Error("User not found");
      }
      user_to_edit_id = res.rows[0].user_id;
    });
  }

  const isCurrentUser = logged_user_id === user_to_edit_id;

  return {
    canEdit: isAdmin || isCurrentUser,
    isAdmin,
    isCurrentUser,
  };
}

export async function getUserTeams(identifier?: number | string) {
  const { user_id } = await verifySession();

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

  const result: ResultProps<TeamData[]> = await db
    .query(sql, [final_identifier])
    .then((res) => {
      return {
        message: "User teams retrieved.",
        data: res.rows,
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  return result;
}

export async function getUserRosters(
  identifier?: number | string,
  period?: "current" | "past" | "future",
) {
  const { user_id } = await verifySession();

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

  const result: ResultProps<UserRosterData[]> = await db
    .query(sql, [final_identifier])
    .then((res) => {
      return {
        message: "User rosters retrieved.",
        data: res.rows,
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  return result;
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
}

export async function getUserStatsByDivision(
  division_id: number,
  team_id: number,
  identifier?: number | string,
) {
  const { user_id } = await verifySession();

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

  const result: ResultProps<UserRosterStats> = await db
    .query(sql, [division_id, team_id, final_identifier])
    .then((res) => {
      return {
        message: `User roster stats loaded!`,
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

  return result;
}

export async function getUserManagedTeams(
  user_id?: number,
): Promise<ResultProps<TeamData[]>> {
  // verify session
  const { user_id: logged_user_id } = await verifySession();

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
    ORDER BY t.name
  `;

  const result = await db
    .query(sql, [id])
    .then((res) => {
      return {
        message: `Managed teams found!`,
        status: 200,
        data: res.rows,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  return result;
}

export async function getUserManagedTeamsForJoinDivision(
  division_id: number,
  user_id?: number,
): Promise<ResultProps<TeamData[]>> {
  // verify session
  const { user_id: logged_user_id } = await verifySession();

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

  const result = await db
    .query(sql, [id, division_id])
    .then((res) => {
      return {
        message: `Managed teams found!`,
        status: 200,
        data: res.rows,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  return result;
}

export async function getUserGamePreviews(
  user_id: number,
  pastGames?: boolean,
): Promise<GameData>;
export async function getUserGamePreviews(
  user_id: number,
  pastGames = false,
  limit = 1,
): Promise<GameData | GameData[]> {
  const sql = `
    SELECT
      g.division_id,
      g.game_id,
      g.home_team_id,
      (SELECT name FROM league_management.teams WHERE team_id = g.home_team_id) AS home_team,
      (SELECT slug FROM league_management.teams WHERE team_id = g.home_team_id) AS home_team_slug,
      (SELECT color FROM league_management.teams WHERE team_id = g.home_team_id) AS home_team_color,
      (SELECT COUNT(*) FROM stats.shots AS sh WHERE sh.team_id = g.home_team_id AND sh.game_id = g.game_id)::int AS home_team_shots,
      g.home_team_score,
      g.away_team_id,
      (SELECT name FROM league_management.teams WHERE team_id = g.away_team_id) AS away_team,
      (SELECT slug FROM league_management.teams WHERE team_id = g.away_team_id) AS away_team_slug,
      (SELECT color FROM league_management.teams WHERE team_id = g.away_team_id) AS away_team_color,
      (SELECT COUNT(*) FROM stats.shots AS sh WHERE sh.team_id = g.away_team_id AND sh.game_id = g.game_id)::int AS away_team_shots,
      g.away_team_score,
      g.date_time,
      g.arena_id,
      (SELECT name FROM league_management.arenas WHERE arena_id = g.arena_id) AS arena,
      (SELECT name FROM league_management.venues WHERE venue_id = (
      SELECT venue_id FROM league_management.arenas WHERE arena_id = g.arena_id
      )) AS venue,
      g.status
    FROM
      league_management.team_memberships AS tm
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
      league_management.games AS g
    ON
      t.team_id = g.home_team_id OR t.team_id = g.away_team_id
    WHERE
      tm.user_id = $1
      AND
      t.status = 'active'
      AND
      g.date_time ${pastGames ? "<" : ">"} now()
      AND
      g.status = ${pastGames ? "'completed'" : "'public'"}
    ORDER BY
      g.date_time ${pastGames ? "DESC" : "ASC"}
    LIMIT $2
  `;

  const result = await db
    .query(sql, [user_id, limit])
    .then((res) => {
      return {
        message: `Games found!`,
        status: 200,
        data: res.rows,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
        data: [],
      };
    });

  // TODO: add better error handling
  if (limit === 1) {
    return result.data[0];
  }
  return result.data;
}

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

  // check if user can edit the user
  const { canEdit, isCurrentUser } = await canEditUser(submittedData.user_id);

  if (!canEdit) {
    return {
      message: "You do not have permission to edit this user!",
      status: 401,
      data: submittedData,
    };
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

  const result: ResultProps<UserSessionData> = await db
    .query(sql, [
      submittedData.username,
      submittedData.email,
      submittedData.first_name,
      submittedData.last_name,
      submittedData.gender,
      submittedData.pronouns,
      submittedData.user_id,
    ])
    .then((res) => {
      return {
        message: "User updated!",
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

  if (!result.data) {
    return {
      ...result,
      data: submittedData,
    };
  }

  if (isCurrentUser) {
    await createSession(result.data);
  }

  redirect(createDashboardUrl({ u: result.data.username }, "edit"));
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

  const { isCurrentUser } = await canEditUser(submittedData.user_id);

  if (!isCurrentUser) {
    return {
      message:
        "You are only permitted to change your own password. If a user needs their password reset, use the reset password functionality.",
      status: 401,
      data: submittedData,
    };
  }

  let errors: PasswordFormErrors = {};

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
    return {
      errors,
      data: submittedData,
    };
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

  const selectResult: ResultProps<{ password_hash: string }> = await db
    .query(selectSql, [submittedData.user_id])
    .then((res) => {
      if (res.rowCount === 0) {
        throw new Error("User not found.");
      }
      return {
        message: "Password retrieved.",
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

  if (!selectResult.data) {
    return {
      ...selectResult,
      data: submittedData,
    };
  }

  // compare passwords
  const passwordsMatch = await bcrypt.compare(
    submittedData.current_password,
    selectResult.data.password_hash,
  );

  if (!passwordsMatch) {
    return {
      errors: {
        current_password: ["Password is incorrect"],
      },
      data: submittedData,
    };
  }

  // hash new_password
  const hashed_new_password = await bcrypt.hash(submittedData.new_password, 10);

  // build update sql statement
  // this statement automatically confirms the current_password matches
  // by including it in the WHERE clause with the user_id
  const updateSql = `
    UPDATE admin.users
    SET
      password_hash = $1
    WHERE
      user_id = $2
  `;

  // query the database
  const updateResult = await db
    .query(updateSql, [hashed_new_password, submittedData.user_id])
    .then(() => {
      return {
        message: "Password successfully updated.",
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  return {
    ...updateResult,
    data: submittedData,
  };
}
