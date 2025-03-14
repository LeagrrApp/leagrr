"use server";
import { db } from "@/db/pg";
import { team_roles, team_status_options } from "@/lib/definitions";
import { verifySession } from "@/lib/session";
import {
  createDashboardUrl,
  createMetaTitle,
} from "@/utils/helpers/formatting";
import { check_string_is_color_hex } from "@/utils/helpers/validators";
import { redirect } from "next/navigation";
import { z } from "zod";
import { getDivisionStandings } from "./divisions";
import { verifyUserRole } from "./users";

/* ---------- CREATE ---------- */

const CreateTeamSchema = z.object({
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
});

type TeamErrorProps = {
  team_id?: string[] | undefined;
  user_id?: string[] | undefined;
  name?: string[] | undefined;
  description?: string[] | undefined;
  color?: string[] | undefined;
  custom_color?: string[] | undefined;
  join_code?: string[] | undefined;
};

type TeamFormState = FormState<TeamErrorProps, Partial<TeamData>>;

export async function createTeam(
  state: TeamFormState,
  formData: FormData,
): Promise<TeamFormState> {
  // Confirmed logged in
  await verifySession();

  // get data from form
  const submittedData = {
    user_id: parseInt(formData.get("user_id") as string),
    name: formData.get("name") as string,
    description: formData.get("description") as string,
    color: formData.get("color") as string,
    custom_color: (formData.get("custom_color") as string) || "#000",
  };

  const validatedFields = CreateTeamSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      data: submittedData,
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  // initialize redirect link
  let redirectLink: string | undefined = undefined;

  try {
    // create insert statement
    const teamInsertSql = `
    INSERT INTO league_management.teams
      (name, description, color)
    VALUES
      ($1, $2, $3)
    RETURNING
      slug, team_id
  `;

    // Value clean up to insure they are null in database not empty strings
    let color: string | null =
      submittedData.color !== "custom"
        ? submittedData.color
        : submittedData.custom_color;
    if (color === "") color = null;

    // query database
    const { rows: teamRows } = await db.query<{
      slug: string;
      team_id: number;
    }>(teamInsertSql, [submittedData.name, submittedData.description, color]);

    if (!teamRows[0])
      throw new Error("Sorry, there was a problem creating team.");

    const { team_id, slug } = teamRows[0];

    // add user to team as manager (1)
    const teamMembershipSql = `
      INSERT INTO league_management.team_memberships
        (user_id, team_id, team_role)
      VALUES
        ($1, $2, 1)
    `;

    const { rowCount: tmRowCount } = await db.query(teamMembershipSql, [
      submittedData.user_id,
      team_id,
    ]);

    if (tmRowCount === 0) {
      // Failed to add user as team admin, delete the team and return error

      // delete the team
      const deleteSql = `
        DELETE FROM league_management.teams
        WHERE team_id = $1
      `;

      await db.query(deleteSql, [team_id]);

      throw new Error("Unable to add user as team manager.");
    }

    // Success route, set redirectLink to the new team page
    redirectLink = createDashboardUrl({ t: slug });
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

  if (redirectLink) redirect(redirectLink);
}

/* ---------- READ ---------- */

export async function getTeam(
  slug: string,
): Promise<ResultProps<TeamPageData>> {
  // verify logged in
  await verifySession();

  try {
    const teamSql = `
    SELECT
      team_id,
      slug,
      name,
      description,
      status,
      color,
      join_code
    FROM
      league_management.teams
    WHERE slug = $1
  `;

    const { rows } = await db.query(teamSql, [slug]);

    return {
      message: `Team data found!`,
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

export async function getTeams(options?: {
  limit?: number;
  offset?: number;
  search?: string;
  status?: string;
}): Promise<
  ResultProps<{
    teams: TeamData[];
    perPage: number;
    page: number;
    total: number;
  }>
> {
  // verify session
  await verifySession();

  try {
    const limit = options?.limit || 10;
    const offset = options?.offset || 0;
    const search = options?.search || undefined;
    const status = options?.status;

    let where: string | undefined = undefined;

    const additionalParams: string[] = [];

    if (search) {
      where = `WHERE
          name ILIKE $1
      `;

      additionalParams.push(`%${search}%`);
    }

    if (status) {
      if (!where) {
        where = `WHERE`;
      } else {
        where = `AND`;
      }
      where = `${where}
          status = $${additionalParams.length + 1}`;
      additionalParams.push(status);
    }

    const leaguesSql = `
      SELECT
        team_id,
        slug,
        name,
        description,
        color,
        status
      FROM
        league_management.teams
      ${where}
      ORDER BY name ASC
      LIMIT $${additionalParams.length + 1}
      OFFSET $${additionalParams.length + 2}
    `;

    const { rows: teams } = await db.query<TeamData>(leaguesSql, [
      ...additionalParams,
      limit,
      offset,
    ]);

    const countSql = `
        SELECT
          count(*)::int
        FROM
          league_management.teams
        ${where}
      `;

    const { rows: countRows } = await db.query<{ count: number }>(
      countSql,
      additionalParams.length > 0 ? additionalParams : undefined,
    );

    return {
      message: "Teams loaded.",
      status: 200,
      data: {
        teams,
        perPage: limit,
        page: offset / limit + 1,
        total: countRows[0].count,
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

export async function getTeamMetaData(
  team: string,
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
        league_management.teams
      WHERE
        slug = $1
    `;

    const { rows } = await db.query<{ name: string; description: string }>(
      sql,
      [team],
    );

    let title = createMetaTitle([rows[0].name, "Teams"]);

    if (options?.prefix)
      title = createMetaTitle([options.prefix, rows[0].name, "Teams"]);

    return {
      message: "Team meta data retrieved",
      status: 200,
      data: {
        title,
        description: rows[0].description,
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

export async function getTeamRole(
  team: string | number,
  options?: {
    user_id?: number;
  },
) {
  // verify logged in and get user_id
  const { user_id: logged_user_id } = await verifySession();

  const final_user_id = options?.user_id || logged_user_id;

  try {
    const sql = `
    SELECT 
      team_role,
      t.team_id
    FROM
      league_management.team_memberships AS tm
    JOIN
      league_management.teams AS T
    ON
      t.team_id = tm.team_id
    WHERE
      tm.user_id = $1
      AND
      ${typeof team === "string" ? "t.slug" : "t.team_id"} = $2
  `;

    const { rows } = await db.query<{ team_role: number }>(sql, [
      final_user_id,
      team,
    ]);

    if (!rows) throw new Error("User does not have a role on this team.");

    return {
      message: "User role found!",
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

export async function verifyTeamRoleLevel(
  team: string | number,
  roleLevel: number,
  options?: {
    user_id?: number;
  },
) {
  const { data } = await getTeamRole(team, options);

  if (!data?.team_role) return false;

  return data.team_role <= roleLevel;
}

export async function canEditTeam(
  team: string | number,
  options?: {
    user_id?: number;
  },
): Promise<{
  canEdit: boolean;
  role: RoleData | undefined;
}> {
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
    const { data } = await getTeamRole(team, options);
    // verify which role the user has
    if (data) {
      // set canEdit based on whether it is a commissionerOnly check or not
      canEdit = data.team_role === 1;
      // set name of role
      role = team_roles.get(data.team_role);
    }
  }

  return {
    canEdit,
    role,
  };
}

export async function getTeamsByLeagueId(
  league_id: number,
  options?: { excludeDivision?: number },
) {
  try {
    const sql = `
      SELECT
        t.team_id,
        t.name,
        t.slug,
        t.color
      FROM
        league_management.leagues AS l
      JOIN
        league_management.seasons AS s
      ON
        s.league_id = l.league_id
      JOIN
        league_management.divisions AS d
      ON
        s.season_id = d.season_id
      JOIN
        league_management.division_teams AS dt
      ON
        d.division_id = dt.division_id
      JOIN
        league_management.teams AS t
      ON
        dt.team_id = t.team_id
      WHERE
        l.league_id = $1
        ${
          options?.excludeDivision
            ? `AND
        t.team_id NOT IN (
          SELECT
            team_id
          FROM
            league_management.division_teams
          WHERE
            division_id = $2
        )`
            : ""
        }
      GROUP BY t.team_id
      ORDER BY t.name ASC
    `;

    const queryArgs = [league_id];

    if (options?.excludeDivision) queryArgs.push(options.excludeDivision);

    const result = await db.query<TeamData>(sql, queryArgs);

    return {
      message: "Teams loaded",
      status: 200,
      data: result.rows,
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

export async function getTeamsByDivisionId(division_id: number) {
  try {
    const sql = `
      SELECT
        t.team_id,
        t.name,
        t.slug,
        t.status,
        t.color,
        dt.division_team_id
      FROM
        league_management.teams as t
      JOIN
        league_management.division_teams as dt
      ON
        t.team_id = dt.team_id
      WHERE
        dt.division_id = $1
      ORDER BY t.name ASC
    `;

    const { rows } = await db.query<DivisionTeamData>(sql, [division_id]);

    return {
      message: "Teams loaded.",
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

export async function getDivisionTeamId(team_id: number, division_id: number) {
  // confirm logged in
  await verifySession();

  try {
    const sql = `
      SELECT
        division_team_id
      FROM
        league_management.division_teams AS dt
      WHERE
        team_id = $1 AND division_id = $2
    `;

    const { rows } = await db.query<{ division_team_id: number }>(sql, [
      team_id,
      division_id,
    ]);
    return {
      message: "Team list found",
      status: 200,
      data: rows[0].division_team_id,
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

export async function getDivisionsByTeam(
  team_id: number,
): Promise<ResultProps<TeamDivisionsData[]>> {
  // verify signed in
  await verifySession();

  try {
    const sql = `
      SELECT
        d.name AS division,
        d.division_id AS division_id,
        d.slug AS division_slug,
        s.name AS season,
        s.slug AS season_slug,
        s.start_date AS start_date,
        s.end_date AS end_date,
        l.name AS league,
        l.slug AS league_slug
      FROM
        league_management.division_teams AS dt
      JOIN
        league_management.divisions AS d
      ON
        dt.division_id = d.division_id
      JOIN
        league_management.seasons AS s
      ON
        s.season_id = d.season_id
      JOIN
        league_management.leagues AS l
      ON
        s.league_id = l.league_id
      WHERE
        dt.team_id = $1
        AND
        d.status = 'public'
        AND
        s.status = 'public'
        AND
        l.status = 'public'
    `;

    const { rows } = await db.query<TeamDivisionsData>(sql, [team_id]);
    return {
      message: `Divisions found!`,
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

export async function getTeamGamePreviews(
  team_id: number,
  division_id: number,
  pastGames = false,
  limit = 1,
) {
  try {
    const sql = `
      SELECT
        g.division_id,
        g.game_id,
        g.home_team_id,
        ht.name AS home_team,
        ht.color AS home_team_color,
        ht.slug AS home_team_slug,
        sum(
          CASE
            WHEN s.team_id = ht.team_id THEN 1
            ELSE 0
          END
        ) AS home_team_shots,
        g.home_team_score,
        g.away_team_id,
        at.name AS away_team,
        at.color AS away_team_color,
        at.slug AS away_team_slug,
        sum(
          CASE
            WHEN s.team_id = at.team_id THEN 1
            ELSE 0
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
        g.status = ${pastGames ? "'completed'" : "'public'"}
        AND
        (
          home_team_id = $1
          OR
          away_team_id = $1
        )
        AND
        g.date_time ${pastGames ? "<" : ">"} now()
        AND
        g.division_id = $2
      GROUP BY g.game_id, ht.name, ht.color, ht.slug, at.name, at.color, at.slug, a.name, v.name
      ORDER BY
        date_time ${pastGames ? "DESC" : "ASC"}
      LIMIT $3
    `;

    const { rows } = await db.query<GameData>(sql, [
      team_id,
      division_id,
      limit,
    ]);

    return {
      message: `Game(s) loaded.`,
      status: 200,
      data: rows,
    };
  } catch (err) {
    if (err instanceof Error) {
      return {
        message: err.message,
        status: 400,
        data: [],
      };
    }
    return {
      message: "Something went wrong.",
      status: 500,
      data: [],
    };
  }
}

export async function getTeamDivisionRosterStats(
  team_id: number,
  division_id: number,
) {
  // confirm logged in
  await verifySession();

  try {
    // TODO: improve query
    const sql = `
    SELECT
      tm.team_id,
      u.user_id,
      u.first_name,
      u.last_name,
      u.username,
      u.pronouns,
      u.email,
      dr.position,
      dr.number,
      tm.team_role,
      (SELECT COUNT(*) FROM stats.goals AS g WHERE g.user_id = tm.user_id AND g.game_id IN (
        SELECT game_id FROM league_management.games WHERE (home_team_id = $1 OR away_team_id = $1) AND division_id = $2
      ))::int AS goals,
      (SELECT COUNT(*) FROM stats.assists AS a WHERE a.user_id = tm.user_id AND a.game_id IN (
        SELECT game_id FROM league_management.games WHERE (home_team_id = $1 OR away_team_id = $1) AND division_id = $2
      ))::int AS assists,
      (
        (SELECT COUNT(*) FROM stats.goals AS g WHERE g.user_id = tm.user_id AND g.game_id IN (
        SELECT game_id FROM league_management.games WHERE (home_team_id = $1 OR away_team_id = $1) AND division_id = $2
      )) +
        (SELECT COUNT(*) FROM stats.assists AS a WHERE a.user_id = tm.user_id AND a.game_id IN (
        SELECT game_id FROM league_management.games WHERE (home_team_id = $1 OR away_team_id = $1) AND division_id = $2
      ))
      )::int AS points,
      (SELECT COUNT(*) FROM stats.shots AS s WHERE s.user_id = tm.user_id AND s.game_id IN (
        SELECT game_id FROM league_management.games WHERE (home_team_id = $1 OR away_team_id = $1) AND division_id = $2
      ))::int AS shots,
      (SELECT COALESCE(SUM(minutes), 0) FROM stats.penalties AS p WHERE p.user_id = tm.user_id AND p.game_id IN (
      SELECT game_id FROM league_management.games WHERE (home_team_id = $1 OR away_team_id = $1) AND division_id = $2
      ))::int AS penalties_in_minutes,
      (SELECT COUNT(*) FROM stats.saves AS sa WHERE sa.user_id = tm.user_id AND sa.game_id IN (
        SELECT game_id FROM league_management.games WHERE (home_team_id = $1 OR away_team_id = $1) AND division_id = $2
      ))::int AS saves,
      (SELECT COUNT(*) FROM stats.goals AS goal WHERE goal.team_id != 2 AND goal.game_id IN (
        SELECT game_id FROM league_management.games WHERE (home_team_id = $1 OR away_team_id = $1) AND division_id = $2
      ))::int AS goals_against,
      (SELECT COUNT(*) FROM stats.shots AS sh WHERE sh.team_id != 2 AND sh.game_id IN (
        SELECT game_id FROM league_management.games WHERE (home_team_id = $1 OR away_team_id = $1) AND division_id = $2
      ))::int AS shots_against
    FROM
      league_management.division_rosters AS dr
    JOIN
      league_management.team_memberships AS tm
    ON
      dr.team_membership_id = tm.team_membership_id
    JOIN
      admin.users AS u
    ON
      tm.user_id = u.user_id
    JOIN
      league_management.division_teams AS dt
    ON
      dt.division_team_id = dr.division_team_id
    WHERE
      dt.team_id = $1
      AND
      dt.division_id = $2
      AND
      dr.roster_role IN (2, 3, 4)
    ORDER BY points DESC, goals DESC, assists DESC, shots DESC, last_name ASC, first_name ASC
  `;

    // const sql = `
    //   SELECT
    //       user_id,
    //       username,
    //       first_name,
    //       last_name,
    //       position,
    //       number,
    //       goals,
    //       assists,
    //       shots,
    //       saves,
    //       penalties_in_minutes,
    //       (goals + assists) AS points
    //     FROM
    //     (
    //       SELECT
    //         u.user_id,
    //         u.username,
    //         u.first_name,
    //         u.last_name,
    //         dr.position,
    //         dr.number,
    //         COUNT(DISTINCT g.goal_id)::int AS goals,
    //         COUNT(DISTINCT a.assist_id)::int AS assists,
    //         COUNT(DISTINCT s.shot_id)::int AS shots,
    //         COUNT(DISTINCT sa.shot_id)::int AS saves,
    //         (SELECT COALESCE(SUM(minutes), 0) FROM stats.penalties AS p WHERE p.user_id = u.user_id AND p.game_id IN (SELECT game_id FROM league_management.games WHERE division_id = $2))::int as penalties_in_minutes
    //       FROM
    //         league_management.division_rosters AS dr
    //       JOIN
    //         league_management.team_memberships AS tm
    //       ON
    //         dr.team_membership_id = tm.team_membership_id
    //       JOIN
    //         admin.users AS u
    //       ON
    //         tm.user_id = u.user_id
    //       JOIN
    //         league_management.division_teams AS dt
    //       ON
    //         dt.division_team_id = dr.division_team_id
    //       LEFT JOIN
    //         stats.goals AS g
    //       ON
    //         g.user_id = u.user_id AND g.game_id IN (SELECT game_id FROM league_management.games WHERE division_id = $2)
    //       LEFT JOIN
    //         stats.assists AS a
    //       ON
    //         a.user_id = u.user_id AND a.game_id IN (SELECT game_id FROM league_management.games WHERE division_id = $2)
    //       LEFT JOIN
    //         stats.shots AS s
    //       ON
    //         s.user_id = u.user_id AND s.game_id IN (SELECT game_id FROM league_management.games WHERE division_id = $2)
    //       LEFT JOIN
    //         stats.saves AS sa
    //       ON
    //         sa.user_id = u.user_id AND sa.game_id IN (SELECT game_id FROM league_management.games WHERE division_id = $2)
    //       WHERE
    //         dt.team_id = $1
    //         AND
    //         dt.division_id = $2
    //         AND
    //         dr.roster_role IN (2, 3, 4)
    //       GROUP BY (u.username, u.user_id, u.first_name, u.last_name, dr.position, dr.number)
    //     )
    //   ORDER BY points DESC, goals DESC, assists DESC, shots DESC, last_name ASC, first_name ASC
    // `;

    const { rows } = await db.query<PlayerStats>(sql, [team_id, division_id]);

    return {
      message: `Games found!`,
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

export async function getTeamDashboardData(
  team_id: number,
  division_id: number,
) {
  // confirm logged in
  await verifySession();

  // get next game
  const { data: nextGames } = await getTeamGamePreviews(team_id, division_id);

  // get previous game
  const { data: prevGames } = await getTeamGamePreviews(
    team_id,
    division_id,
    true,
  );

  // get team members
  const { data: teamMembers } = await getTeamDivisionRosterStats(
    team_id,
    division_id,
  );

  // get current div/season/league data
  const { data: divisionStandings } = await getDivisionStandings(division_id);

  return {
    nextGame: nextGames[0],
    prevGame: prevGames[0],
    teamMembers,
    divisionStandings,
  };
}

/* ---------- UPDATE ---------- */

const EditTeamSchema = z.object({
  team_id: z.number().min(1),
  name: z
    .string()
    .min(2, { message: "Name must be at least 2 characters long." })
    .trim(),
  description: z.string().trim().optional(),
  color: z.string().optional(),
  custom_color: z.string().refine(check_string_is_color_hex, {
    message: "Invalid color format.",
  }),
});

export async function editTeam(
  state: TeamFormState,
  formData: FormData,
): Promise<TeamFormState> {
  // get data from form
  const submittedData = {
    team_id: parseInt(formData.get("team_id") as string),
    name: formData.get("name") as string,
    description: formData.get("description") as string,
    color: formData.get("color") as string,
    custom_color: (formData.get("custom_color") as string) || "#000",
  };

  // Validate data
  const validatedFields = EditTeamSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      data: submittedData,
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  // set initial status code
  let status = 400;

  // initialize redirectLink
  let redirectLink: string | undefined = undefined;

  try {
    // Check if user can edit
    const { canEdit } = await canEditTeam(submittedData.team_id);

    if (!canEdit) {
      // failed role check, shortcut out
      status = 401;
      throw new Error("You do not have permission to edit this team.");
    }

    let color: string | null =
      submittedData.color !== "custom"
        ? submittedData.color
        : submittedData.custom_color;
    if (color === "") color = null;

    const sql = `
      UPDATE league_management.teams
      SET
        name = $1,
        description = $2,
        color = $3
      WHERE
        team_id = $4
      RETURNING
        slug
    `;

    // query database
    const { rows } = await db.query<{ slug: string }>(sql, [
      submittedData.name,
      submittedData.description,
      color,
      submittedData.team_id,
    ]);

    if (!rows[0])
      throw new Error("Sorry, there was a problem editing the team.");

    redirectLink = createDashboardUrl({ t: rows[0].slug });
  } catch (err) {
    if (err instanceof Error) {
      return {
        message: err.message,
        status: status,
        data: submittedData,
      };
    }
    return {
      message: "Something went wrong.",
      status: 500,
      data: submittedData,
    };
  }

  if (redirectLink) redirect(redirectLink);
}

const EditTeamAsAdminSchema = z.object({
  team_id: z.number().min(1),
  status: z.enum(team_status_options),
});

type EditTeamAsAdminErrors = {
  team_id?: string[];
  status?: string[];
};
type EditTeamAsAdminState = FormState<
  EditTeamAsAdminErrors,
  {
    team_id?: number;
    status?: "active" | "inactive" | "suspended" | "banned";
  }
>;

export async function editTeamAsAdmin(
  state: EditTeamAsAdminState,
  formData: FormData,
): Promise<EditTeamAsAdminState> {
  // Confirm user is site admin
  const isAdmin = await verifyUserRole(1);

  const submittedData = {
    team_id: parseInt(formData.get("team_id") as string),
    status: formData.get("status") as
      | "active"
      | "inactive"
      | "suspended"
      | "banned",
  };

  // initialize response status code
  let status = 400;

  try {
    if (!isAdmin) {
      status = 401;
      throw new Error("Sorry, you do not have admin privileges.");
    }

    // Validate data
    const validatedFields = EditTeamAsAdminSchema.safeParse(submittedData);

    // If any form fields are invalid, return early
    if (!validatedFields.success) {
      return {
        ...state,
        data: submittedData,
        errors: validatedFields.error.flatten().fieldErrors,
      };
    }

    // set up sql
    const sql = `
      UPDATE league_management.teams
      SET status = $1
      WHERE team_id = $2
    `;

    const { rowCount } = await db.query(sql, [
      submittedData.status,
      submittedData.team_id,
    ]);

    if (rowCount !== 1) {
      throw new Error("Sorry, there was a problem updating the team.");
    }

    return {
      message: "Team updated",
      status: 200,
      data: submittedData,
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

const TeamJoinCodeSchema = z.object({
  join_code: z
    .string()
    .min(6, { message: "Join code must be at least 6 characters long" })
    .regex(/[a-zA-Z0-9-]/, { message: "Fails regex" }),
  team_id: z.number().min(1),
});

export async function setTeamJoinCode(
  state: TeamFormState,
  formData: FormData,
): Promise<TeamFormState> {
  const submittedData = {
    join_code: formData.get("join_code") as string,
    team_id: parseInt(formData.get("team_id") as string),
  };

  // Validate data
  const validatedFields = TeamJoinCodeSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      errors: validatedFields.error.flatten().fieldErrors,
      data: submittedData,
    };
  }

  try {
    // Check if user can edit
    const { canEdit } = await canEditTeam(submittedData.team_id);

    if (!canEdit) {
      // failed role check, shortcut out
      return {
        message: "You do not have permission to edit this team.",
        status: 401,
        data: submittedData,
      };
    }

    const sql = `
      UPDATE league_management.teams
      SET
        join_code = $1
      WHERE
        team_id = $2
      RETURNING
        join_code
    `;

    // query database
    const { rows } = await db.query<{ join_code: string }>(sql, [
      submittedData.join_code,
      submittedData.team_id,
    ]);

    return {
      message: `Join code updated!`,
      status: 200,
      data: rows[0],
    };
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
}

/* ---------- DELETE ---------- */

export async function deleteTeam(state: { team_id: number }) {
  // initialize success check
  let success = false;

  // initialize response status code
  let status = 400;

  try {
    // Check if user can delete
    const siteAdmin = await verifyUserRole(1);
    // if not, short circuit
    if (!siteAdmin) {
      status = 401;
      throw new Error(
        "Only site admins are permitted to delete teams. Contact support for assistance.",
      );
    }

    const sql = `
      DELETE FROM league_management.teams
      WHERE team_id = $1
    `;

    const { rowCount } = await db.query(sql, [state.team_id]);

    if (rowCount !== 1) {
      throw new Error("Sorry, there was a problem deleting team.");
    }

    success = true;
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

  if (success) redirect("/dashboard/t");
}
