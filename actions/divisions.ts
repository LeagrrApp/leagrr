"use server";

import { db } from "@/db/pg";
import { gender_options, status_options } from "@/lib/definitions";
import { verifySession } from "@/lib/session";
import {
  createDashboardUrl,
  createMetaTitle,
} from "@/utils/helpers/formatting";
import { redirect } from "next/navigation";
import { z } from "zod";
import { canEditLeague } from "./leagues";
import { canEditTeam } from "./teams";

const DivisionFormSchema = z.object({
  division_id: z.number().min(1).optional(),
  name: z
    .string()
    .min(2, { message: "Name must be at least 2 characters long." })
    .trim(),
  description: z.string().trim().optional(),
  season_id: z.number().min(1).optional(),
  league_id: z.number().min(1).optional(),
  tier: z.number().min(1),
  gender: z.enum(gender_options),
  status: z.enum(status_options).optional(),
  join_code: z.string().trim().optional(),
});

type DivisionErrorProps = {
  division_id?: string[] | undefined;
  name?: string[] | undefined;
  description?: string[] | undefined;
  league_id?: string[] | undefined;
  season_id?: string[] | undefined;
  tier?: string[] | undefined;
  gender?: string[] | undefined;
  status?: string[] | undefined;
  join_code?: string[] | undefined;
};

type DivisionFormState = FormState<
  DivisionErrorProps,
  Partial<
    Pick<
      DivisionData,
      | "name"
      | "description"
      | "season_id"
      | "league_id"
      | "tier"
      | "gender"
      | "join_code"
    >
  >
>;

export async function createDivision(
  state: DivisionFormState,
  formData: FormData,
): Promise<DivisionFormState> {
  // check user is logged in
  await verifySession();

  const submittedData = {
    name: formData.get("name") as string,
    description: formData.get("description") as string,
    season_id: parseInt(formData.get("season_id") as string),
    league_id: parseInt(formData.get("league_id") as string),
    tier: parseInt(formData.get("tier") as string),
    gender: formData.get("gender") as string,
    join_code: formData.get("join_code") as string,
  };

  // Check to see if the user is allowed to create a division for this season
  const { canEdit } = await canEditLeague(submittedData.league_id);

  if (!canEdit) {
    return {
      message:
        "You do not have permission to create a division for this season",
      status: 400,
      data: submittedData,
    };
  }

  // Validate form fields
  const validatedFields = DivisionFormSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      errors: validatedFields.error.flatten().fieldErrors,
      data: submittedData,
    };
  }

  // create insert postgresql statement
  const sql = `
    INSERT INTO league_management.divisions AS d
      (name, description, season_id, tier, gender, join_code)
    VALUES
      ($1, $2, $3, $4, $5, $6)
    RETURNING
      slug,
      (SELECT slug FROM league_management.seasons as s WHERE s.season_id = $3) AS season_slug,
      (SELECT slug FROM league_management.leagues as l WHERE l.league_id = $7) AS league_slug
  `;

  // query database
  const insertResult: ResultProps<DivisionData> = await db
    .query(sql, [
      submittedData.name,
      submittedData.description,
      submittedData.season_id,
      submittedData.tier,
      submittedData.gender,
      submittedData.join_code,
      submittedData.league_id,
    ])
    .then((res) => {
      return {
        message: "Division created!",
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

  if (insertResult?.data)
    redirect(
      createDashboardUrl({
        l: insertResult?.data.league_slug,
        s: insertResult?.data.season_slug,
        d: insertResult?.data.slug,
      }),
    );

  return { ...insertResult, data: submittedData };
}

export async function getDivisionsBySeason(season_id: number) {
  // check user is logged in
  await verifySession();

  // build sql select statement
  const divisionSql = `
    SELECT
      division_id,
      name,
      slug,
      gender,
      tier,
      status
    FROM
      divisions
    WHERE
      season_id = $1
    ORDER BY
      gender ASC, tier ASC
  `;

  const divisionResult: ResultProps<DivisionPreview[]> = await db
    .query(divisionSql, [season_id])
    .then((res) => {
      return {
        message: "Divisions data loaded",
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

  return divisionResult;
}

export async function getDivisionTeams(division_id: number) {
  const divisionTeamsSql = `
    SELECT
      t.team_id,
      t.name,
      t.slug,
      t.status,
      t.color,
      dt.division_team_id
    FROM
      division_teams as dt
    JOIN
      teams as t
    ON
      t.team_id = dt.team_id
    WHERE
      dt.division_id = $1
    ORDER BY t.name ASC
  `;

  const result: ResultProps<DivisionTeamData[]> = await db
    .query(divisionTeamsSql, [division_id])
    .then((res) => {
      return {
        message: "Division teams loaded",
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

export async function getDivisionStandings(division_id: number) {
  const divisionTeamsSql = `
    SELECT
      t.team_id,
      t.name,
      t.slug,
      t.status,
      (
        SELECT
          COUNT(*)
        FROM
          league_management.games
        WHERE
          (
            (home_team_id = t.team_id)
            OR
            (away_team_id = t.team_id)
          )
          AND
          division_id = $1
          AND
          status = 'completed'
      )::int AS games_played,
      (
        SELECT
          COUNT(*)
        FROM
          league_management.games
        WHERE
          (
            (home_team_id = t.team_id AND home_team_score > away_team_score)
            OR
            (away_team_id = t.team_id AND away_team_score > home_team_score)
          )
          AND
          division_id = $1
          AND
          status = 'completed'
      )::int AS wins,
      (
        SELECT
          COUNT(*)
        FROM
          league_management.games
        WHERE
          (
            (home_team_id = t.team_id AND home_team_score < away_team_score)
            OR
            (away_team_id = t.team_id AND away_team_score < home_team_score)
          )
          AND
          division_id = $1
          AND
          status = 'completed'
      )::int AS losses,
      (
        SELECT
          COUNT(*)
        FROM
          league_management.games
        WHERE
          (
            home_team_id = t.team_id
            OR
            away_team_id = t.team_id
          )
          AND
            away_team_score = home_team_score
          AND
            division_id = $1
          AND
            status = 'completed'
      )::int AS ties,
      (
        (
          SELECT
            COUNT(*)
          FROM
            league_management.games
          WHERE
            (
              (home_team_id = t.team_id AND home_team_score > away_team_score)
              OR
              (away_team_id = t.team_id AND away_team_score > home_team_score)
            )
            AND
            division_id = $1
            AND
            status = 'completed'
        ) * 2
        +
        (
          SELECT
            COUNT(*)
          FROM
            league_management.games
          WHERE
            (
              home_team_id = t.team_id
              OR
              away_team_id = t.team_id
            )
            AND
              away_team_score = home_team_score
            AND
              division_id = $1
            AND
              status = 'completed'
        )
      )::int AS points,
      (
        (
          SELECT
            COALESCE(SUM(home_team_score), 0)
          FROM
            league_management.games
          WHERE
            home_team_id = t.team_id
            AND
            division_id = $1
            AND
            status = 'completed'
        ) + (
          SELECT
            COALESCE(SUM(away_team_score), 0)
          FROM
            league_management.games
          WHERE
            away_team_id = t.team_id
            AND
            division_id = $1
            AND
            status = 'completed'
        )
      )::int AS goals_for,
      (
        (
          SELECT
            COALESCE(SUM(away_team_score), 0)
          FROM
            league_management.games
          WHERE
            home_team_id = t.team_id
            AND
            division_id = $1
            AND
            status = 'completed'
        ) + (
          SELECT
            COALESCE(SUM(home_team_score), 0)
          FROM
            league_management.games
          WHERE
            away_team_id = t.team_id
            AND
            division_id = $1
            AND
            status = 'completed'
        )
      )::int AS goals_against
    FROM
      division_teams as dt
    JOIN
      teams as t
    ON
      t.team_id = dt.team_id
    WHERE
      dt.division_id = $1
    ORDER BY points DESC, games_played ASC, wins DESC, goals_for DESC, goals_against ASC
  `;

  const result: ResultProps<TeamStandingsData[]> = await db
    .query(divisionTeamsSql, [division_id])
    .then((res) => {
      return {
        message: "Division teams loaded",
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

export async function getDivision(
  division_slug: string,
  season_slug: string,
  league_slug: string,
): Promise<ResultProps<DivisionData>> {
  // check user is logged in
  await verifySession();

  const divisionSql = `
    SELECT
      division_id,
      name,
      description,
      slug,
      gender,
      tier,
      join_code,
      status,
      (SELECT league_id FROM leagues WHERE slug = $3),
      (
        SELECT
          season_id
        FROM
          league_management.seasons AS s
        WHERE
          s.slug = $2
          AND
          league_id = (
            SELECT
              league_id
            FROM
              league_management.leagues AS l
            WHERE
              l.slug = $3
          )
      ) AS season_id
    FROM
      divisions
    WHERE
        slug = $1
        AND
        season_id = (
          SELECT
            season_id
          FROM
            league_management.seasons AS s
          WHERE
            s.slug = $2
            AND
            league_id = (
              SELECT
                league_id
              FROM
                league_management.leagues AS l
              WHERE
                l.slug = $3
            )
        )
  `;

  const divisionResult: ResultProps<DivisionData> = await db
    .query(divisionSql, [division_slug, season_slug, league_slug])
    .then((res) => {
      if (res.rowCount === 0) {
        throw new Error("Division not found!");
      }

      return {
        message: "Division data loaded",
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

  if (!divisionResult.data) {
    return divisionResult;
  }

  const divisionStandingsResult = await getDivisionStandings(
    divisionResult.data.division_id,
  );

  const { canEdit } = await canEditLeague(divisionResult.data.league_id);

  let divisionGamesSql = `
    SELECT
      game_id,
      home_team_id,
      (SELECT name FROM league_management.teams WHERE team_id = g.home_team_id) AS home_team,
      home_team_score,
      away_team_id,
      (SELECT name FROM league_management.teams WHERE team_id = g.away_team_id) AS away_team,
      away_team_score,
      date_time,
      arena_id,
      (SELECT name FROM league_management.arenas WHERE arena_id = g.arena_id) AS arena,
      (SELECT name FROM league_management.venues WHERE venue_id = (
        SELECT venue_id FROM league_management.arenas WHERE arena_id = g.arena_id
      )) AS venue,
      status
    FROM league_management.games AS g
    WHERE
      division_id = $1
  `;

  if (!canEdit) {
    divisionGamesSql = `
      ${divisionGamesSql}
      AND
      status IN ('completed', 'public', 'postponed', 'cancelled')
    `;
  }

  divisionGamesSql = `
      ${divisionGamesSql}
      ORDER BY
        date_time DESC
    `;

  const divisionGamesResult: ResultProps<GameData[]> = await db
    .query(divisionGamesSql, [divisionResult.data.division_id])
    .then((res) => {
      return {
        message: "Division teams loaded",
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

  const fullDivisionData = {
    message: divisionResult.message,
    status: divisionResult.status,
    data: {
      ...divisionResult.data,
      season_slug,
      league_slug,
    },
  };

  if (divisionStandingsResult.data) {
    fullDivisionData.data.teams = divisionStandingsResult.data;
  }

  if (divisionGamesResult.data) {
    fullDivisionData.data.games = divisionGamesResult.data;
  }

  return fullDivisionData;
}

export async function getDivisionMetaInfo(
  division_slug: string,
  season_slug: string,
  league_slug: string,
): Promise<
  ResultProps<{
    title: string;
    description?: string;
  }>
> {
  // check user is logged in
  await verifySession();

  const sql = `
    SELECT
      d.name AS division_name,
      (
        SELECT
        s.name
        FROM
        league_management.seasons AS s
        WHERE
        s.slug = $2
        AND
        league_id = (
          SELECT
          league_id
          FROM
          league_management.leagues AS l
          WHERE
          l.slug = $3
        )
      ) AS season_name,
      (
        SELECT
        l.name
        FROM
        league_management.leagues AS l
        WHERE
        l.slug = $3
      ) AS league_name,
      d.description
    FROM
      divisions AS d
    WHERE
      slug = $1
      AND
      season_id = (
        SELECT
        season_id
        FROM
        league_management.seasons AS s
        WHERE
        s.slug = $2
        AND
        league_id = (
          SELECT
          league_id
          FROM
          league_management.leagues AS l
          WHERE
          l.slug = $3
        )
      )
  `;

  const result: ResultProps<{
    division_name: string;
    season_name: string;
    league_name: string;
    description?: string;
  }> = await db
    .query(sql, [division_slug, season_slug, league_slug])
    .then((res) => {
      return {
        data: res.rows[0],
        message: "Division meta data found.",
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  if (!result.data)
    return {
      message: result.message,
      status: result.status,
    };

  const { division_name, season_name, league_name, description } = result.data;

  const metaData = {
    title: createMetaTitle([division_name, season_name, league_name]),
    description,
  };

  return {
    message: result.message,
    status: result.status,
    data: metaData,
  };
}

export async function getDivisionUrlById(
  division_id: number,
): Promise<string | undefined> {
  const sql = `
    SELECT
      d.slug AS division_slug,
      s.slug AS season_slug,
      l.slug AS league_slug
    FROM
      league_management.divisions AS d
    JOIN
      league_management.seasons AS s
    ON
      s.season_id = d.season_id
    JOIN
      league_management.leagues AS l
    ON
      s.league_id = l.league_id
    WHERE
      d.division_id = $1
  `;

  const result: ResultProps<{
    division_slug: string;
    season_slug: string;
    league_slug: string;
  }> = await db
    .query(sql, [division_id])
    .then((res) => {
      if (res.rowCount === 0) {
        throw new Error("Division not found!");
      }

      return {
        data: res.rows[0],
        message: "Division data found",
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  if (!result.data) {
    return undefined;
  }

  return createDashboardUrl({
    l: result.data.league_slug,
    s: result.data.season_slug,
    d: result.data.division_slug,
  });
}

export async function getDivisionStatLeaders(
  division_id: number,
  limit?: number,
): Promise<
  ResultProps<{
    [key: string]: StatLeaderBoardItem[];
    points: StatLeaderBoardItem[];
    goals: StatLeaderBoardItem[];
    assists: StatLeaderBoardItem[];
    shutouts: StatLeaderBoardItem[];
  }>
> {
  // Verify user session
  await verifySession();

  const pointsSql = `
    SELECT
      t.name AS team,
      u.first_name,
      u.last_name,
      u.username,
      (
        (SELECT COUNT(*) FROM stats.goals AS g WHERE g.user_id = u.user_id AND g.game_id IN (SELECT game_id FROM league_management.games WHERE division_id = $1 AND status = 'completed')) +
        (SELECT COUNT(*) FROM stats.assists AS a WHERE a.user_id = u.user_id AND a.game_id IN (SELECT game_id FROM league_management.games WHERE division_id = $1 AND status = 'completed'))	
      )::int AS count
    FROM
      league_management.division_teams AS dt
    JOIN
      league_management.division_rosters AS dr
    ON
      dr.division_team_id = dt.division_team_id
    JOIN
      league_management.team_memberships AS tm
    ON
      tm.team_membership_id = dr.team_membership_id
    JOIN
      admin.users AS u
    ON
      u.user_id = tm.user_id
    JOIN
      league_management.teams AS t
    ON
      t.team_id = tm.team_id
    WHERE
      dt.division_id = $1
      AND
      dr.roster_role != 1
    ORDER BY count DESC, u.last_name ASC, u.first_name ASC
    LIMIT $2
  `;

  const pointsResult: ResultProps<StatLeaderBoardItem[]> = await db
    .query(pointsSql, [division_id, limit || 10])
    .then((res) => {
      return {
        message: "Points loaded.",
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

  // TODO: improve update game score error handling
  if (!pointsResult.data) {
    throw new Error(pointsResult.message);
  }

  const goalsSql = `
    SELECT
      t.name AS team,
      u.first_name,
      u.last_name,
      u.username,
      count(*) AS count
    FROM
      stats.goals AS g
    JOIN
      admin.users AS u
    ON
      g.user_id = u.user_id
    JOIN
      league_management.games AS ga
    ON
      ga.game_id = g.game_id
    JOIN
      league_management.team_memberships as tm
    ON
      u.user_id = tm.user_id
    JOIN
      league_management.teams as t
    ON
      t.team_id = tm.team_id
    WHERE
      ga.division_id = $1
      AND
      ga.status = 'completed'
    GROUP BY team, u.username, u.first_name, u.last_name
    ORDER BY count DESC, u.last_name ASC, u.first_name ASC
    LIMIT $2
  `;

  const goalsResult: ResultProps<StatLeaderBoardItem[]> = await db
    .query(goalsSql, [division_id, limit || 10])
    .then((res) => {
      return {
        message: "Goals loaded.",
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

  // TODO: improve update game score error handling
  if (!goalsResult.data) {
    throw new Error(goalsResult.message);
  }

  const assistsSql = `
    SELECT
      t.name AS team,
      u.first_name,
      u.last_name,
      u.username,
      count(*) AS count
    FROM
      stats.assists AS a
    JOIN
      admin.users AS u
    ON
      a.user_id = u.user_id
    JOIN
      league_management.games AS ga
    ON
      ga.game_id = a.game_id
    JOIN
      league_management.team_memberships as tm
    ON
      u.user_id = tm.user_id
    JOIN
      league_management.teams as t
    ON
      t.team_id = tm.team_id
    WHERE
      ga.division_id = $1
      AND
      ga.status = 'completed'
    GROUP BY team, u.username, u.first_name, u.last_name
    ORDER BY count DESC, u.last_name ASC, u.first_name ASC
    LIMIT $2
  `;

  const assistsResult: ResultProps<StatLeaderBoardItem[]> = await db
    .query(assistsSql, [division_id, limit || 10])
    .then((res) => {
      return {
        message: "Assists loaded.",
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

  // TODO: improve update game score error handling
  if (!assistsResult.data) {
    throw new Error(assistsResult.message);
  }

  const shutoutsSql = `
    SELECT
      t.name AS team,
      u.first_name,
      u.last_name,
      u.username,
      count(*) AS count
    FROM
      league_management.division_teams AS dt
    JOIN
      league_management.division_rosters AS dr
    ON
      dr.division_team_id = dt.division_team_id
    JOIN
      league_management.teams AS t
    ON
      t.team_id = dt.team_id
    JOIN
      league_management.team_memberships AS tm
    ON
      dr.team_membership_id = tm.team_membership_id
    JOIN
      admin.users AS u
    ON
      u.user_id = tm.user_id
    JOIN
      league_management.games AS ga
    ON
      t.team_id IN (ga.home_team_id, ga.away_team_id)
    WHERE 
      dt.division_id = $1
      AND
      dr.position = 'Goalie'
      AND
      dr.roster_role != 1
      AND
      ga.division_id = $1
      AND
      ga.status = 'completed'
      AND
      (
        ((t.team_id = ga.home_team_id) AND ga.away_team_score = 0)
        OR
        ((t.team_id = ga.away_team_id) AND ga.home_team_score = 0)
      )
    GROUP BY team, u.username, u.first_name, u.last_name
    ORDER BY count DESC, u.last_name ASC, u.first_name ASC
    LIMIT $2
  `;

  const shutoutsResult: ResultProps<StatLeaderBoardItem[]> = await db
    .query(shutoutsSql, [division_id, limit || 10])
    .then((res) => {
      return {
        message: "Shutouts loaded.",
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

  // TODO: improve update game score error handling
  if (!shutoutsResult.data) {
    throw new Error(shutoutsResult.message);
  }

  return {
    message: "Stats loaded!",
    status: 200,
    data: {
      points: pointsResult.data,
      goals: goalsResult.data,
      assists: assistsResult.data,
      shutouts: shutoutsResult.data,
    },
  };
}

export async function getLeagueTeamsNotInDivision(
  division_id: number,
  league_id: number,
) {
  const sql = `
    SELECT
      t.team_id,
      t.name,
      t.slug,
      t.color
    FROM
      league_management.teams AS t
    JOIN
      league_management.division_teams AS dt
    ON
      t.team_id = dt.team_id
    WHERE
      dt.division_id IN (
        SELECT
          division_id
        FROM
          league_management.divisions AS d
        WHERE
          d.season_id IN (
            SELECT
              s.season_id
            FROM
              league_management.seasons AS s
            WHERE
              s.league_id = $2
          )
          AND
          division_id != $1
      )
      AND
      t.team_id NOT IN (
        SELECT
          team_id
        FROM
          league_management.division_teams
        WHERE
          division_id = $1
      )
      AND
      t.status = 'active'
    GROUP BY t.team_id
    ORDER BY t.name ASC;
  `;

  const result: ResultProps<TeamData[]> = await db
    .query(sql, [division_id, league_id])
    .then((res) => {
      return {
        message: "League teams loaded.",
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

export async function editDivision(
  state: DivisionFormState,
  formData: FormData,
): Promise<DivisionFormState> {
  // check user is logged in
  await verifySession();

  const submittedData = {
    name: formData.get("name") as string,
    description: formData.get("description") as string,
    division_id: parseInt(formData.get("division_id") as string),
    league_id: parseInt(formData.get("league_id") as string),
    tier: parseInt(formData.get("tier") as string),
    gender: formData.get("gender") as string,
    join_code: formData.get("join_code") as string,
    status: formData.get("status") as string,
  };

  // Check to see if the user is allowed to create a season for this league
  const { canEdit } = await canEditLeague(submittedData.league_id);

  if (!canEdit) {
    return {
      message:
        "You do not have permission to create a division for this season",
      status: 400,
      data: submittedData,
    };
  }

  // Validate form fields
  const validatedFields = DivisionFormSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      errors: validatedFields.error.flatten().fieldErrors,
      data: submittedData,
    };
  }

  const updateSql = `
    UPDATE
      league_management.divisions AS d
    SET
      name = $1,
      description = $2,
      tier = $3,
      gender = $4,
      join_code = $5,
      status = $6
    WHERE
      division_id = $7
  `;

  const updateResult: { message: string; status: number } = await db
    .query(updateSql, [
      submittedData.name,
      submittedData.description,
      submittedData.tier,
      submittedData.gender,
      submittedData.join_code,
      submittedData.status,
      submittedData.division_id,
    ])
    .then(() => {
      return {
        message: "Division teams loaded",
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  // TODO: get slug for redirect in case of slug change
  if (state?.link) redirect(state?.link);

  return { ...updateResult, data: submittedData };
}

const DivisionJoinCodeSchema = z.object({
  join_code: z
    .string()
    .min(6, { message: "Join code must be at least 6 characters long" }),
  division_id: z.number().min(1),
  league_id: z.number().min(1),
});

type DivisionJoinCodeErrorProps = {
  join_code?: string[] | undefined;
  division_id?: string[] | undefined;
  league_id?: string[] | undefined;
};

type DivisionJoinCodeFormState = FormState<
  DivisionJoinCodeErrorProps,
  {
    join_code?: string;
    division_id?: number;
    league_id?: number;
  }
>;

export async function setDivisionJoinCode(
  state: DivisionJoinCodeFormState,
  formData: FormData,
): Promise<DivisionJoinCodeFormState> {
  const submittedData = {
    join_code: formData.get("join_code") as string,
    division_id: parseInt(formData.get("division_id") as string),
    league_id: parseInt(formData.get("league_id") as string),
  };

  const { canEdit } = await canEditLeague(submittedData.league_id);

  if (!canEdit) {
    return {
      message: "You do not have permission to add teams to this division.",
      status: 401,
      data: submittedData,
    };
  }

  // Validate form fields
  const validatedFields = DivisionJoinCodeSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      errors: validatedFields.error.flatten().fieldErrors,
      data: submittedData,
    };
  }

  const sql = `
    UPDATE league_management.divisions
    SET
      join_code = $1
    WHERE
      division_id = $2
    RETURNING
      join_code
  `;

  const result: ResultProps<{ join_code: string }> = await db
    .query(sql, [submittedData.join_code, submittedData.division_id])
    .then((res) => {
      return {
        message: "Join code updated!",
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

  return {
    ...result,
    data: {
      ...submittedData,
      join_code: result.data?.join_code,
    },
  };
}

const DivisionTeamSchema = z.object({
  team_id: z.number().min(1).optional(),
  division_id: z.number().min(1).optional(),
  division_team_id: z.number().min(1).optional(),
  league_id: z.number().min(1),
});

type DivisionTeamErrorProps = {
  team_id?: string[] | undefined;
  division_id?: string[] | undefined;
  division_team_id?: string[] | undefined;
};

type DivisionTeamFormState = FormState<
  DivisionTeamErrorProps,
  {
    team_id?: number;
    division_id?: number;
    division_team_id?: number;
  }
>;

export async function addTeamToDivision(
  state: DivisionTeamFormState,
  formData: FormData,
): Promise<DivisionTeamFormState> {
  const submittedData = {
    team_id: parseInt(formData.get("team_id") as string),
    division_id: parseInt(formData.get("division_id") as string),
    league_id: parseInt(formData.get("league_id") as string),
  };

  const { canEdit } = await canEditLeague(submittedData.league_id);

  if (!canEdit) {
    return {
      message: "You do not have permission to add teams to this division.",
      status: 401,
      data: submittedData,
    };
  }

  // Validate form fields
  const validatedFields = DivisionTeamSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      errors: validatedFields.error.flatten().fieldErrors,
      data: submittedData,
    };
  }

  const sql = `
    INSERT INTO league_management.division_teams
      (division_id, team_id)
    VALUES
      ($1, $2)
  `;

  const result = await db
    .query(sql, [submittedData.division_id, submittedData.team_id])
    .then(() => {
      return {
        message: "Team added to division!",
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  if (result.status === 400) return { ...result, data: submittedData };

  if (state?.link) redirect(state?.link);
}

export async function removeTeamFromDivision(
  state: DivisionTeamFormState,
  formData: FormData,
): Promise<DivisionTeamFormState> {
  const submittedData = {
    team_id: parseInt(formData.get("team_id") as string),
    division_id: parseInt(formData.get("division_id") as string),
    league_id: parseInt(formData.get("league_id") as string),
  };

  const { canEdit } = await canEditLeague(submittedData.league_id);

  if (!canEdit) {
    return {
      message: "You do not have permission to add teams to this division.",
      status: 401,
      data: submittedData,
    };
  }

  // Validate form fields
  const validatedFields = DivisionTeamSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      errors: validatedFields.error.flatten().fieldErrors,
      data: submittedData,
    };
  }

  const sql = `
    DELETE FROM league_management.division_teams
    WHERE
      division_id = $1
      AND
      team_id = $2
  `;

  const result = await db
    .query(sql, [submittedData.division_id, submittedData.team_id])
    .then(() => {
      return {
        message: "Team removed from division!",
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  if (result.status === 400) return { ...result, data: submittedData };

  if (state?.link) redirect(state?.link);
}

const JoinDivisionSchema = z.object({
  join_code: z.string(),
  team_id: z.number().min(1),
  division_id: z.number().min(1),
});

type JoinDivisionErrorProps = {
  join_code?: string[] | undefined;
  team_id?: string[] | undefined;
  division_id?: string[] | undefined;
};

type JoinDivisionFormState = FormState<
  JoinDivisionErrorProps,
  {
    join_code?: string;
    team_id?: number;
    division_id?: number;
  }
>;

export async function joinDivision(
  state: JoinDivisionFormState,
  formData: FormData,
): Promise<JoinDivisionFormState> {
  const submittedData = {
    join_code: formData.get("join_code") as string,
    team_id: parseInt(formData.get("team_id") as string),
    division_id: parseInt(formData.get("division_id") as string),
  };

  // Validate form fields
  const validatedFields = JoinDivisionSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      errors: validatedFields.error.flatten().fieldErrors,
      link: state?.link,
      data: submittedData,
    };
  }

  // check user can edit selected team
  const { canEdit } = await canEditTeam(submittedData.team_id);

  if (!canEdit) {
    return {
      message:
        "You do not have permission to join this division on behalf of this team.",
      status: 401,
      link: state?.link,
      data: submittedData,
    };
  }

  // get division join_code from database
  const joinCodeSql = `
    SELECT
      join_code
    FROM
      league_management.divisions
    WHERE
      division_id = $1
  `;

  const joinCodeResult: ResultProps<{ join_code: string }> = await db
    .query(joinCodeSql, [submittedData.division_id])
    .then((res) => {
      if (res.rowCount === 0) {
        throw new Error("Division not found!");
      }
      return {
        message: "Join code retrieved!",
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

  if (!joinCodeResult?.data) {
    return {
      ...joinCodeResult,
      link: state?.link,
      data: submittedData,
    };
  }

  // check if submitted join code matches division join code
  const joinCodesMatch =
    joinCodeResult.data.join_code === submittedData.join_code;

  // if join_codes do not match, short circuit
  if (!joinCodesMatch)
    return {
      message: "Join code does not match the division's join code!",
      status: 401,
      link: state?.link,
      data: submittedData,
    };

  // check if team is already in division
  const inDivisionCheckSql = `
    SELECT 
      count(*)
    FROM
      league_management.division_teams
    WHERE
      team_id = $1
      AND
      division_id = $2
  `;

  const inDivisionCheckResult = await db
    .query(inDivisionCheckSql, [
      submittedData.team_id,
      submittedData.division_id,
    ])
    .then((res) => {
      if (res.rows[0].count > 0) {
        throw new Error("Team is already a member of this division!");
      }
      return {
        message: "Team is not in division.",
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  // Team is not in division
  if (inDivisionCheckResult.status === 200) {
    // add team to division
    const insertSql = `
      INSERT INTO league_management.division_teams
        (division_id, team_id)
      VALUES
        ($1, $2)
    `;

    const insertResult = await db
      .query(insertSql, [submittedData.division_id, submittedData.team_id])
      .then(() => {
        return {
          message: "Membership updated!",
          status: 200,
        };
      })
      .catch((err) => {
        return {
          message: err.message,
          status: 400,
        };
      });

    if (insertResult.status === 400)
      return { ...insertResult, data: submittedData };

    if (state?.link) redirect(state.link);
  }

  return {
    ...inDivisionCheckResult,
    link: state?.link,
    data: submittedData,
  };
}

export async function deleteDivision(state: {
  division_id: number;
  league_id: number;
  backLink: string;
}) {
  // Verify user session
  await verifySession();

  // set check for whether user has permission to delete
  const { canEdit: canDelete } = await canEditLeague(state.league_id);

  if (!canDelete) {
    // failed both user role check and league role check, shortcut out
    return {
      message: "You do not have permission to delete this division.",
      status: 401,
    };
  }

  // create delete sql statement
  const sql = `
    DELETE FROM league_management.divisions
    WHERE division_id = $1
  `;

  // query the database
  const deleteResult = await db
    .query(sql, [state.division_id])
    .then((res) => {
      return {
        message: "Division deleted",
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

  // TODO: improve error handling if there is an issue deleting season
  if (deleteResult.status === 400) return deleteResult;

  redirect(state.backLink);
}
