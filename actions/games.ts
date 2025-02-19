"use server";

import { db } from "@/db/pg";
import { game_status_options } from "@/lib/definitions";
import { verifySession } from "@/lib/session";
import {
  createDashboardUrl,
  createMetaTitle,
  createPeriodTimeString,
} from "@/utils/helpers/formatting";
import { isObjectEmpty } from "@/utils/helpers/objects";
import { redirect } from "next/navigation";
import { z } from "zod";
import { canEditLeague } from "./leagues";

// TODO: Rename this function to something clearer
export async function getLeagueInfoForGames(
  division_slug: string,
  season_slug: string,
  league_slug: string,
): Promise<ResultProps<AddGameData>> {
  // check user is logged in
  await verifySession();

  // Check to see if the user is allowed to create a season for this league
  const { canEdit } = await canEditLeague(league_slug);

  if (!canEdit) {
    return {
      message: "You do not have permission to a game for this division",
      status: 400,
    };
  }

  // get list of teams
  const teamsSql = `
    SELECT
      t.team_id,
      t.name
    FROM
      league_management.division_teams AS dt
    JOIN
        league_management.teams AS t
    ON
        t.team_id = dt.team_id
    JOIN
      league_management.divisions AS d
    ON
      d.division_id = dt.division_id
    WHERE
      d.slug = $1
      AND
      d.season_id = (
        SELECT
          s.season_id
        FROM
          league_management.seasons AS s
        WHERE
          s.slug = $2
          AND
          s.league_id = (
            SELECT
              l.league_id
            FROM
              league_management.leagues AS l
            WHERE
              l.slug = $3
          )
      )
  `;

  const teamsResult: ResultProps<QuickTeam[]> = await db
    .query(teamsSql, [division_slug, season_slug, league_slug])
    .then((res) => {
      if (res.rowCount === 0) {
        throw new Error("There are no teams in this division!");
      }
      return {
        message: "Division teams found",
        status: 200,
        data: res.rows,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 404,
      };
    });

  if (!teamsResult.data) {
    return {
      message: teamsResult.message,
      status: teamsResult.status,
    };
  }

  // get list of arenas and venues
  const locationsSql = `
    SELECT 
      v.slug AS venue_slug,
      v.name AS venue,
      a.name AS arena,
      CONCAT(a.name, ' - ', v.name) AS location,
      a.arena_id AS arena_id
    FROM
      league_management.league_venues AS lv
    JOIN
      league_management.venues AS v
    ON
      lv.venue_id = v.venue_id
    JOIN
      league_management.arenas AS a
    ON
      a.venue_id = v.venue_id
    WHERE
      league_id = (
        SELECT
          l.league_id
        FROM
          league_management.leagues AS L
        WHERE 
          l.slug = $1
      )
    ORDER BY
      venue, arena
  `;

  const locationsResult: ResultProps<LocationData[]> = await db
    .query(locationsSql, [league_slug])
    .then((res) => {
      if (res.rowCount === 0) {
        throw new Error("This league does not have any assigned venues.");
      }
      return {
        message: "league venues found",
        status: 200,
        data: res.rows,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 404,
      };
    });

  if (!locationsResult.data) {
    return {
      message: locationsResult.message,
      status: locationsResult.status,
    };
  }

  return {
    message: "Game add data found",
    status: 200,
    data: {
      teams: teamsResult.data,
      locations: locationsResult.data,
    },
  };
}

const GameCreateFormSchema = z.object({
  division_id: z.number().min(1),
  league_id: z.number().min(1),
  home_team_id: z.number().min(1),
  away_team_id: z.number().min(1),
  arena_id: z.number().min(1),
  date_time: z.date(),
  status: z.enum(game_status_options).optional(),
});

type GameErrorProps = {
  game_id?: string[] | undefined;
  division_id?: string[] | undefined;
  home_team_id?: string[] | undefined;
  away_team_id?: string[] | undefined;
  arena_id?: string[] | undefined;
  date_time?: string[] | undefined;
  status?: string[] | undefined;
};

type GameFormState = FormState<
  GameErrorProps,
  {
    home_team_id?: number;
    away_team_id?: number;
    arena_id?: number;
    date_time?: Date | string;
    status?: string;
  }
>;

export async function createGame(
  state: GameFormState,
  formData: FormData,
): Promise<GameFormState> {
  // check user is logged in
  await verifySession();

  const submittedData = {
    division_id: parseInt(formData.get("division_id") as string),
    league_id: parseInt(formData.get("league_id") as string),
    home_team_id: parseInt(formData.get("home_team_id") as string),
    away_team_id: parseInt(formData.get("away_team_id") as string),
    arena_id: parseInt(formData.get("arena_id") as string),
    date_time: new Date(formData.get("date_time") as string),
    status: formData.get("status") as string,
  };

  // Check to see if the user is allowed to create a season for this league
  const { canEdit } = await canEditLeague(submittedData.league_id);

  if (!canEdit) {
    return {
      message: "You do not have permission to create games for this division",
      status: 400,
      data: submittedData,
    };
  }

  let errors: GameErrorProps = {};

  // Validate form fields
  const validatedFields = GameCreateFormSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    errors = validatedFields.error.flatten().fieldErrors;
  }

  if (submittedData.home_team_id === submittedData.away_team_id) {
    if (errors.away_team_id) {
      errors.away_team_id.push("Home and away teams must be different!");
    } else {
      errors.away_team_id = ["Home and away teams must be different!"];
    }
  }

  // if there are any validation errors, return errors
  if (!isObjectEmpty(errors))
    return {
      link: state?.link,
      errors,
      data: {
        home_team_id: submittedData.home_team_id,
        away_team_id: submittedData.away_team_id,
        arena_id: submittedData.arena_id,
        date_time: formData.get("date_time") as string,
        status: submittedData.status,
      },
    };

  const insertSql = `
    INSERT INTO league_management.games
      (home_team_id, away_team_id, division_id, date_time, arena_id, status)
    VALUES
      ($1, $2, $3, $4, $5, $6)
    RETURNING game_id
  `;

  const insertResult: ResultProps<{ game_id: number }> = await db
    .query(insertSql, [
      submittedData.home_team_id,
      submittedData.away_team_id,
      submittedData.division_id,
      submittedData.date_time,
      submittedData.arena_id,
      submittedData.status,
    ])
    .then((res) => {
      return {
        message: "Game created!",
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

  if (!insertResult.data) {
    return {
      message: insertResult.message,
      status: insertResult.status,
      data: submittedData,
    };
  }

  // TODO: handle if there link isn't working

  if (state?.link) redirect(state?.link);
}

export async function getGame(game_id: number) {
  // verify user is signed in
  await verifySession();

  const sql = `
    SELECT
      game_id,
      home_team_id,
      (SELECT name FROM league_management.teams WHERE team_id = g.home_team_id) AS home_team,
      (SELECT color FROM league_management.teams WHERE team_id = g.home_team_id) AS home_team_color,
      (SELECT slug FROM league_management.teams WHERE team_id = g.home_team_id) AS home_team_slug,
      home_team_score,
      (SELECT COUNT(*) FROM stats.shots AS sh WHERE sh.team_id = g.home_team_id AND sh.game_id = $1)::int AS home_team_shots,
      away_team_id,
      (SELECT name FROM league_management.teams WHERE team_id = g.away_team_id) AS away_team,
      (SELECT color FROM league_management.teams WHERE team_id = g.away_team_id) AS away_team_color,
      (SELECT slug FROM league_management.teams WHERE team_id = g.away_team_id) AS away_team_slug,
      away_team_score,
      (SELECT COUNT(*) FROM stats.shots AS sh WHERE sh.team_id = g.away_team_id AND sh.game_id = $1)::int AS away_team_shots,
      division_id,
      date_time,
      arena_id,
      (SELECT name FROM league_management.arenas WHERE arena_id = g.arena_id) AS arena,
      (SELECT name FROM league_management.venues WHERE venue_id = (
        SELECT venue_id FROM league_management.arenas WHERE arena_id = g.arena_id
      )) AS venue,
      status,
      has_been_published
    FROM league_management.games AS g
    WHERE
      game_id = $1
  `;

  const gameResult: ResultProps<GameData> = await db
    .query(sql, [game_id])
    .then((res) => {
      return {
        message: "Game data loaded",
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

  return gameResult;
}

export async function getGameUrl(game_id: number) {
  // verify user is signed in
  await verifySession();

  const sql = `
    SELECT
      g.game_id,
      d.slug AS division_slug,
      s.slug AS season_slug,
      l.slug AS league_slug
    FROM
      league_management.games AS g
    JOIN
      league_management.divisions AS d
    ON
      g.division_id = d.division_id
    JOIN
      league_management.seasons AS s
    ON
      s.season_id = d.division_id
    JOIN
      league_management.leagues AS l
    ON
      s.league_id = l.league_id
    WHERE
      game_id = $1
  `;

  const result: ResultProps<{
    game_id: number;
    league_slug: string;
    division_slug: string;
    season_slug: string;
  }> = await db
    .query(sql, [game_id])
    .then((res) => {
      return {
        message: "Game data found!",
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

  if (!result.data) return result;

  const urlParts = result.data;

  const url = createDashboardUrl({
    l: urlParts.league_slug,
    s: urlParts.season_slug,
    d: urlParts.division_slug,
    g: urlParts.game_id,
  });

  return {
    message: "Game url created!",
    status: 200,
    data: url,
  };
}

export async function getGameMetaInfo(
  game_id: number,
  options?: {
    prefix?: string;
  },
): Promise<
  ResultProps<{
    title: string;
    description?: string;
  }>
> {
  try {
    const sql = `
      SELECT
        at.name AS away_team,
        ht.name AS home_team,
        g.date_time,
        d.name AS division,
        s.name AS season,
        l.name AS league
      FROM
        league_management.games AS g
      LEFT JOIN
        league_management.teams AS at
      ON
        at.team_id = g.away_team_id
      LEFT JOIN
        league_management.teams AS ht
      ON
        ht.team_id = g.home_team_id
      JOIN
        league_management.divisions AS d
      ON
        g.division_id = d.division_id
      JOIN
        league_management.seasons AS s
      ON
        d.season_id = s.season_id
      JOIN
        league_management.leagues AS l
      ON
        l.league_id = s.league_id
      WHERE
        g.game_id = $1
    `;

    const { rows } = await db.query<{
      away_team: string;
      home_team: string;
      date_time: Date;
      division: string;
      season: string;
      league: string;
    }>(sql, [game_id]);

    const { away_team, home_team, date_time, division, season, league } =
      rows[0];

    const game_date = date_time.toLocaleDateString("en-CA", {
      month: "long",
      day: "numeric",
      year: "numeric",
    });

    const game_time = date_time.toLocaleTimeString("en-CA", {
      hour: "numeric",
      minute: "2-digit",
    });

    let title = createMetaTitle([
      `${away_team} vs ${home_team}`,
      game_date,
      division,
      season,
      league,
    ]);

    let description = `Game taking place on ${game_date} at ${game_time} between ${away_team} at ${home_team} of ${division} of the ${season} of ${league}.`;

    if (options?.prefix) {
      title = createMetaTitle([
        options.prefix,
        `${away_team} vs ${home_team}`,
        game_date,
        division,
        season,
        league,
      ]);

      if (options.prefix === "Edit") {
        description = `Edit game taking place on ${game_date} at ${game_time} between ${away_team} at ${home_team} of ${division} of the ${season} of ${league}.`;
      }
    }

    return {
      message: "Game meta data retrieved.",
      status: 200,
      data: {
        title,
        description,
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
      message: "Something went wrong",
      status: 500,
    };
  }
}

export async function getGamesByDivisionId(
  division_id: number,
  league: number | string,
) {
  try {
    const divisionGamesSql = `
      SELECT
        g.game_id,
        g.home_team_id,
        ht.name AS home_team,
        g.home_team_score,
        g.away_team_id,
        at.name AS away_team,
        g.away_team_score,
        g.date_time,
        g.arena_id,
        a.name AS arena,
        v.name AS venue,
        g.status,
        g.division_id
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
        a.arena_id = g.arena_id
      LEFT JOIN
        league_management.venues AS v
      ON
        a.venue_id = v.venue_id
      WHERE
        division_id = $1
      ORDER BY
        date_time DESC
    `;

    const { rows } = await db.query<GameData>(divisionGamesSql, [division_id]);

    if (!rows[0]) {
      return {
        message: "This division has no games.",
        status: 200,
        data: [],
      };
    }

    let games = rows;

    const { canEdit } = await canEditLeague(league);

    if (!canEdit) {
      games = games.filter(
        (g) =>
          g.status === "public" ||
          g.status === "completed" ||
          g.status === "postponed" ||
          g.status === "cancelled",
      );
    }

    return {
      message: "Division games retrieved.",
      status: 200,
      data: games,
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

const GameEditFormSchema = z.object({
  game_id: z.number().min(1),
  league_id: z.number().min(1),
  home_team_id: z.number().min(1),
  away_team_id: z.number().min(1),
  arena_id: z.number().min(1),
  date_time: z.date(),
  status: z.enum(game_status_options),
});

export async function editGame(
  state: GameFormState,
  formData: FormData,
): Promise<GameFormState> {
  // check user is logged in
  await verifySession();

  const submittedData = {
    game_id: parseInt(formData.get("game_id") as string),
    league_id: parseInt(formData.get("league_id") as string),
    home_team_id: parseInt(formData.get("home_team_id") as string),
    away_team_id: parseInt(formData.get("away_team_id") as string),
    arena_id: parseInt(formData.get("arena_id") as string),
    date_time: new Date(formData.get("date_time") as string),
    status: formData.get("status") as string,
  };

  // Check to see if the user is allowed to create a season for this league
  const { canEdit } = await canEditLeague(submittedData.league_id);

  if (!canEdit) {
    return {
      message: "You do not have permission to edit this game.",
      status: 400,
      data: submittedData,
    };
  }

  let errors: GameErrorProps = {};

  // Validate form fields
  const validatedFields = GameEditFormSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    errors = validatedFields.error.flatten().fieldErrors;
  }

  if (submittedData.home_team_id === submittedData.away_team_id) {
    if (errors.away_team_id) {
      errors.away_team_id.push("Home and away teams must be different!");
    } else {
      errors.away_team_id = ["Home and away teams must be different!"];
    }
  }

  // if there are any validation errors, return errors
  if (!isObjectEmpty(errors))
    return {
      link: state?.link,
      errors,
      data: {
        home_team_id: submittedData.home_team_id,
        away_team_id: submittedData.away_team_id,
        arena_id: submittedData.arena_id,
        date_time: formData.get("date_time") as string,
        status: submittedData.status,
      },
    };

  const updateSql = `
    UPDATE
      league_management.games
    SET
      home_team_id = $1,
      away_team_id = $2,
      arena_id = $3,
      date_time = $4,
      status = $5
    WHERE
      game_id = $6
  `;

  const updateResult: ResultProps<{ game_id: number }> = await db
    .query(updateSql, [
      submittedData.home_team_id,
      submittedData.away_team_id,
      submittedData.arena_id,
      submittedData.date_time,
      submittedData.status,
      submittedData.game_id,
    ])
    .then((res) => {
      return {
        message: "Game updated!",
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

  if (updateResult.status === 400) {
    return {
      ...updateResult,
      data: submittedData,
    };
  }

  // TODO: handle if there link isn't working

  if (state?.link) redirect(state?.link);
}

const GameScoreSchema = z.object({
  home_team_score: z.number().min(0),
  away_team_score: z.number().min(0),
});

type GameScoreState = FormState<
  {
    home_team_score?: string[] | undefined;
    away_team_score?: string[] | undefined;
  },
  | {
      game?: GameData;
      league?: string;
      home_team_score?: number;
      away_team_score?: number;
    }
  | undefined
>;

export async function setGameScore(
  state: GameScoreState,
  formData: FormData,
): Promise<GameScoreState> {
  if (
    !state ||
    !state.data ||
    !state.data.game ||
    !state.data.league ||
    !state.link
  )
    return {
      message: "Missing necessary data to set the score!",
      status: 400,
      data: state?.data,
    };

  // verify user is signed in
  await verifySession();

  const { canEdit } = await canEditLeague(state.data.league);

  if (!canEdit) {
    return {
      ...state,
      message: "You do not have permission to create games for this division",
      status: 400,
    };
  }

  const gameScoreData = {
    home_team_score: parseInt(formData.get("home_team_score") as string),
    away_team_score: parseInt(formData.get("away_team_score") as string),
  };

  // Validate form fields
  const validatedFields = GameScoreSchema.safeParse(gameScoreData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      ...state,
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  const sql = `
    UPDATE league_management.games
    SET 
      home_team_score = $1,
      away_team_score = $2,
      status = 'completed'
    WHERE
      game_id = $3
  `;

  const gameScoreResult = await db
    .query(sql, [
      gameScoreData.home_team_score,
      gameScoreData.away_team_score,
      state.data.game.game_id,
    ])
    .then(() => {
      return {
        message: "Game score updated",
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  if (gameScoreResult.status === 400)
    return {
      ...gameScoreResult,
      data: {
        ...state?.data,
        ...gameScoreData,
      },
    };

  redirect(state.link);
}

export async function getTeamGameStats(
  game_id: number,
  team_id: number,
  division_id: number,
) {
  // verify user is signed in
  await verifySession();

  const sql = `
    SELECT
      u.user_id,
      u.username,
      u.first_name,
      u.last_name,
      dr.number,
      dr.position,
      (SELECT COUNT(*) FROM stats.goals AS g WHERE g.user_id = tm.user_id AND g.game_id = $1)::int AS goals,
      (SELECT COUNT(*) FROM stats.assists AS a WHERE a.user_id = tm.user_id AND a.game_id = $1)::int AS assists,
      (
        (SELECT COUNT(*) FROM stats.goals AS g WHERE g.user_id = tm.user_id AND g.game_id = $1) +
        (SELECT COUNT(*) FROM stats.assists AS a WHERE a.user_id = tm.user_id AND a.game_id = $1)	
      )::int AS points,
      (SELECT COUNT(*) FROM stats.shots AS s WHERE s.user_id = tm.user_id AND s.game_id = $1)::int AS shots,
      (SELECT COUNT(*) FROM stats.saves AS sa WHERE sa.user_id = tm.user_id AND sa.game_id = $1)::int AS saves,
      (SELECT SUM(minutes) FROM stats.penalties AS p WHERE p.user_id = tm.user_id AND p.game_id = $1)::int AS penalties_in_minutes
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
      dt.team_id = $2
      AND
      dt.division_id = $3
      AND
      dr.roster_role IN (2, 3, 4)
    ORDER BY points DESC, goals DESC, assists DESC, shots DESC, last_name ASC, first_name ASC
  `;

  const teamGameStatsResult: ResultProps<PlayerStats[]> = await db
    .query(sql, [game_id, team_id, division_id])
    .then((res) => {
      return {
        message: "Player stats loaded",
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

  return teamGameStatsResult;
}

export async function getGameFeed(game_id: number): Promise<
  ResultProps<{
    period1: StatsData[];
    period2: StatsData[];
    period3: StatsData[];
    [key: string]: StatsData[];
  }>
> {
  // verify user is signed in
  await verifySession();

  const errorResponse = {
    message: "There was a problem loading the game feed.",
    status: 400,
  };

  // get all shots
  const shotsSql = `
    SELECT
      tableoid::regclass AS type,
      s.shot_id AS item_id,
      s.user_id,
      (SELECT username FROM admin.users AS u WHERE u.user_id = s.user_id) AS username,
      (SELECT last_name FROM admin.users AS u WHERE u.user_id = s.user_id) AS user_last_name,
      s.team_id,
      (SELECT name FROM league_management.teams AS t WHERE t.team_id = s.team_id) AS team,
      s.period,
      s.period_time
    FROM
      stats.shots AS s
    WHERE
      game_id = $1
    ORDER BY
      period ASC, period_time ASC
  `;

  const shotsResult: ResultProps<StatsData[]> = await db
    .query(shotsSql, [game_id])
    .then((res) => {
      return {
        message: "Shot stats loaded",
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

  if (!shotsResult.data) {
    return {
      message: "There was a problem loading the game feed.",
      status: 400,
    };
  }

  // get all goals
  const goalsSql = `
    SELECT
      tableoid::regclass AS type,
      g.goal_id AS item_id,
      g.user_id,
      (SELECT username FROM admin.users AS u WHERE u.user_id = g.user_id) AS username,
      (SELECT last_name FROM admin.users AS u WHERE u.user_id = g.user_id) AS user_last_name,
      g.team_id,
      (SELECT name FROM league_management.teams AS t WHERE t.team_id = g.team_id) AS team,
      g.period,
      g.period_time,
      g.shorthanded,
      g.power_play,
      g.empty_net
    FROM
      stats.goals AS g
    WHERE
      game_id = $1
    ORDER BY
      period ASC, period_time ASC
  `;

  const goalsResult: ResultProps<StatsData[]> = await db
    .query(goalsSql, [game_id])
    .then((res) => {
      return {
        message: "Goals stats loaded",
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

  if (!goalsResult.data) {
    return errorResponse;
  }

  // get all assists
  const assistsSql = `
    SELECT
      tableoid::regclass AS type,
      a.assist_id AS item_id,
      a.goal_id,
      a.user_id,
      (SELECT username FROM admin.users AS u WHERE u.user_id = a.user_id) AS username,
      (SELECT last_name FROM admin.users AS u WHERE u.user_id = a.user_id) AS user_last_name,
      a.team_id,
      (SELECT name FROM league_management.teams AS t WHERE t.team_id = a.team_id) AS team,
      a.primary_assist
    FROM
      stats.assists AS a
    WHERE
      game_id = $1
    ORDER BY
      goal_id ASC, primary_assist DESC
  `;

  const assistsResult: ResultProps<StatsData[]> = await db
    .query(assistsSql, [game_id])
    .then((res) => {
      return {
        message: "Assist stats loaded",
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

  if (!assistsResult.data) {
    return errorResponse;
  }

  // get all saves
  const savesSql = `
    SELECT
      tableoid::regclass AS type,
      s.save_id AS item_id,
      s.user_id,
      (SELECT username FROM admin.users AS u WHERE u.user_id = s.user_id) AS username,
      (SELECT last_name FROM admin.users AS u WHERE u.user_id = s.user_id) AS user_last_name,
      s.team_id,
      (SELECT name FROM league_management.teams AS t WHERE t.team_id = s.team_id) AS team,
      s.period,
      s.period_time,
      s.penalty_kill,
      s.rebound
    FROM
      stats.saves AS s
    WHERE
      game_id = $1
    ORDER BY
      period ASC, period_time ASC
  `;

  const savesResult: ResultProps<StatsData[]> = await db
    .query(savesSql, [game_id])
    .then((res) => {
      return {
        message: "Saves stats loaded",
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

  if (!savesResult.data) {
    return errorResponse;
  }

  // get all penalties
  const penaltiesSql = `
    SELECT
      tableoid::regclass AS type,
      p.penalty_id AS item_id,
      p.user_id,
      (SELECT username FROM admin.users AS u WHERE u.user_id = p.user_id) AS username,
      (SELECT last_name FROM admin.users AS u WHERE u.user_id = p.user_id) AS user_last_name,
      p.team_id,
      (SELECT name FROM league_management.teams AS t WHERE t.team_id = p.team_id) AS team,
      p.period,
      p.period_time,
      p.infraction,
      p.minutes
    FROM
      stats.penalties AS p
    WHERE
      game_id = $1
    ORDER BY
      period ASC, period_time ASC
  `;

  const penaltiesResult: ResultProps<StatsData[]> = await db
    .query(penaltiesSql, [game_id])
    .then((res) => {
      return {
        message: "Penalties stats loaded",
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

  if (!penaltiesResult.data) {
    return errorResponse;
  }

  // attach assists to goals
  const goalsWithAssists: StatsData[] = [];
  const goals = goalsResult.data;
  const assists = assistsResult.data;

  goals.forEach((g) => {
    goalsWithAssists.push({
      ...g,
      assists: assists.filter((a) => a.goal_id === g.item_id),
    });
  });

  // Object used as reference to order feed items
  const typeOrder: {
    [key: string]: number;
  } = {
    "stats.shots": 1,
    "stats.goals": 2,
    "stats.save": 3,
    "stats.penalties": 4,
    default: Number.MAX_VALUE,
  };

  // combine into single array, order by period & time
  // when multiple different types share same period & time,
  // put in this order: shot, goal, save, penalty
  const gameFeedItems = [
    ...shotsResult.data,
    ...goalsWithAssists,
    ...savesResult.data,
    ...penaltiesResult.data,
  ].sort(
    (a, b) =>
      a.period - b.period ||
      (a.period_time.minutes || 0) * 60 +
        (a.period_time.seconds || 0) -
        ((b.period_time.minutes || 0) * 60 + (b.period_time.seconds || 0)) ||
      (typeOrder[a.type] || typeOrder.default) -
        (typeOrder[b.type] || typeOrder.default),
  );

  const gameFeed: {
    period1: StatsData[];
    period2: StatsData[];
    period3: StatsData[];
    [key: string]: StatsData[];
  } = {
    period1: gameFeedItems.filter((g) => g.period === 1),
    period2: gameFeedItems.filter((g) => g.period === 2),
    period3: gameFeedItems.filter((g) => g.period === 3),
  };

  return {
    message: "Game feed data loaded!",
    status: 200,
    data: gameFeed,
  };
}

export async function getGameTeamRosters(
  away_team_id: number,
  home_team_id: number,
  division_id: number,
) {
  // verify user is signed in
  await verifySession();

  const rostersSql = `
    SELECT
      tm.team_id,
      u.user_id,
      u.first_name,
      u.last_name,
      dr.position
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
      dt.team_id IN ($1, $2) AND dt.division_id = $3
    ORDER BY
      tm.team_id, u.last_name, u.first_name
  `;

  const rosterResult: ResultProps<TeamRosterItem[]> = await db
    .query(rostersSql, [away_team_id, home_team_id, division_id])
    .then((res) => {
      return {
        message: "Rosters loaded",
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

  if (!rosterResult.data) {
    return {
      message: rosterResult.message,
      status: rosterResult.status,
    };
  }

  return {
    message: rosterResult.message,
    status: rosterResult.status,
    data: {
      away_roster: rosterResult.data.filter((p) => p.team_id === away_team_id),
      home_roster: rosterResult.data.filter((p) => p.team_id === home_team_id),
    },
  };
}

// TODO: Add game feed data validation

// const AddGameFeedShotSchema = z.object({
//   team_id: z.number().min(1),
//   game_id: z.number().min(1),
//   user_id: z.number().min(1),
//   period: z.number().min(1).max(3),
//   minutes: z.number().min(0).max(19),
//   seconds: z.number().min(0).max(59),
//   power_play: z.boolean(),
//   rebound: z.boolean(),
// });

type AddGameFeedErrorProps = {
  team_id?: string[] | undefined;
  game_id?: string[] | undefined;
  user_id?: string[] | undefined;
  period?: string[] | undefined;
  minutes?: string[] | undefined;
  seconds?: string[] | undefined;
  power_play?: string[] | undefined;
  rebound?: string[] | undefined;
};

type AddGameFeedState = FormState<
  AddGameFeedErrorProps,
  {
    game_id?: number;
    user_id?: number;
    team_id?: number;
    period?: number;
    minutes?: number;
    seconds?: number;
    shorthanded?: boolean;
    power_play?: boolean;
    empty_net?: boolean;
    rebound?: boolean;
    assists?: string[];
    penalty_minutes?: number;
    infraction?: string;
    goalie_id?: number;
    opposition_id?: number;
  }
>;

export async function addToGameFeed(
  state: AddGameFeedState,
  formData: FormData,
): Promise<AddGameFeedState> {
  const type = formData.get("type");
  const feedItemData = {
    game_id: parseInt(formData.get("game_id") as string),
    user_id: parseInt(formData.get("user_id") as string),
    team_id: parseInt(formData.get("team_id") as string),
    period: parseInt(formData.get("period") as string),
    minutes: parseInt(formData.get("minutes") as string),
    seconds: parseInt(formData.get("seconds") as string),
    shorthanded: formData.get("shorthanded") === "true",
    power_play: formData.get("power_play") === "true",
    empty_net: formData.get("empty_net") === "true",
    rebound: formData.get("rebound") === "true",
    assists: formData.getAll("assists") as string[],
    penalty_minutes: parseInt(formData.get("penalty_minutes") as string),
    infraction: formData.get("infraction") as string,
    goalie_id: parseInt(formData.get("goalie_id") as string),
    opposition_id: parseInt(formData.get("opposition_id") as string),
  };

  const period_time = createPeriodTimeString(
    feedItemData.minutes,
    feedItemData.seconds,
  );

  let inserted_goal_id: number | null = null;

  // goal or shot
  if (type === "goal" || type === "shot") {
    // -- add goal
    if (type === "goal") {
      const goalSql = `
        INSERT INTO stats.goals
          (game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net)
        VALUES
          ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING
          goal_id
      `;

      const goalResult: ResultProps<{ goal_id: number }> = await db
        .query(goalSql, [
          feedItemData.game_id,
          feedItemData.user_id,
          feedItemData.team_id,
          feedItemData.period,
          period_time,
          feedItemData.shorthanded,
          feedItemData.power_play,
          feedItemData.empty_net,
        ])
        .then((res) => {
          return {
            message: "Goal created!",
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

      // if goal adding was successful, update the game score
      if (goalResult.data) {
        inserted_goal_id = goalResult.data.goal_id;
      } else {
        return {
          ...goalResult,
          data: feedItemData,
          link: state?.link,
        };
      }

      // -- -- add assists
      if (feedItemData?.assists?.length && inserted_goal_id) {
        const assistSql = `
          INSERT INTO stats.assists
            (goal_id, game_id, user_id, team_id, primary_assist)
          VALUES
            ($1, $2, $3, $4, $5)
        `;

        let assistCount = 0;
        for await (const assist of feedItemData.assists) {
          const assistResult = await db
            .query(assistSql, [
              inserted_goal_id,
              feedItemData.game_id,
              assist,
              feedItemData.team_id,
              assistCount === 0,
            ])
            .then(() => {
              return {
                message: "Assist created!",
                status: 200,
              };
            })
            .catch((err) => {
              return {
                message: err.message,
                status: 400,
              };
            });

          // TODO: improve assist error handling
          if (assistResult.status === 400) {
            throw new Error(assistResult.message);
          }

          assistCount++;
        }
      }
    }

    // -- add shot
    const shotSql = `
      INSERT INTO stats.shots
        (game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play)
      VALUES 
        ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING
        shot_id
    `;

    const shotResult: ResultProps<{ shot_id: number }> = await db
      .query(shotSql, [
        feedItemData.game_id,
        feedItemData.user_id,
        feedItemData.team_id,
        feedItemData.period,
        period_time,
        inserted_goal_id,
        feedItemData.shorthanded,
        feedItemData.power_play,
      ])
      .then((res) => {
        return {
          message: "Shot created!",
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

    // TODO: improve shot error handling
    if (shotResult.status === 400) {
      throw new Error(shotResult.message);
    }

    if (type !== "goal" && shotResult.data && feedItemData.goalie_id !== 0) {
      // -- -- add save if not goal and the team has a goalie registered

      const saveSql = `
        INSERT INTO stats.saves
          (game_id, user_id, team_id, shot_id, period, period_time, penalty_kill, rebound)
        VALUES 
          ($1, $2, $3, $4, $5, $6, $7, $8)
      `;

      const saveResult = await db
        .query(saveSql, [
          feedItemData.game_id,
          feedItemData.goalie_id,
          feedItemData.opposition_id,
          shotResult.data.shot_id,
          feedItemData.period,
          period_time,
          feedItemData.shorthanded,
          feedItemData.rebound,
        ])
        .then(() => {
          return {
            message: "Save created!",
            status: 200,
          };
        })
        .catch((err) => {
          return {
            message: err.message,
            status: 400,
          };
        });

      // TODO: improve save error handling
      if (saveResult.status === 400) {
        throw new Error(saveResult.message);
      }
    }
  }

  // penalty
  if (type === "penalty") {
    const penaltySql = `
      INSERT INTO stats.penalties
        (game_id, user_id, team_id, period, period_time, infraction, minutes)
      VALUES
        ($1, $2, $3, $4, $5, $6, $7)
    `;

    const penaltyResult = await db
      .query(penaltySql, [
        feedItemData.game_id,
        feedItemData.user_id,
        feedItemData.team_id,
        feedItemData.period,
        period_time,
        feedItemData.infraction,
        feedItemData.penalty_minutes,
      ])
      .then(() => {
        return {
          message: "Penalty created!",
          status: 200,
        };
      })
      .catch((err) => {
        return {
          message: err.message,
          status: 400,
        };
      });

    // TODO: improve penalty error handling
    if (penaltyResult.status === 400) {
      throw new Error(penaltyResult.message);
    }
  }

  if (state?.link) redirect(`${state?.link}#game-feed-add`);
}

export default async function endGame(state: {
  canEdit: boolean;
  game_id: number;
  backLink: string;
}) {
  // Verify user session
  await verifySession();

  if (!state.canEdit) redirect(state.backLink);

  const sql = `
    UPDATE league_management.games
    SET status = 'completed'
    WHERE game_id = $1
    RETURNING game_id
  `;

  const endGameResult = await db
    .query(sql, [state.game_id])
    .then((res) => {
      if (res.rowCount === 0) {
        throw new Error("Game not found!");
      }
      return {
        message: "Game completed!",
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  // TODO: improve penalty error handling
  if (endGameResult.status === 400) {
    throw new Error(endGameResult.message);
  }

  redirect(state.backLink);
}

type DeleteFeedItemState = FormState<undefined, { id: number; type: string }>;

export async function deleteFeedItem(
  state: DeleteFeedItemState,
): Promise<DeleteFeedItemState> {
  if (!state?.data?.id || !state?.data?.type) {
    return {
      message: "Missing necessary data to delete feed item!",
      status: 400,
      link: state?.link,
      data: {
        id: state?.data?.id || 0,
        type: state?.data?.type || "stats.goal",
      },
    };
  }

  let sql: string;

  switch (state.data.type) {
    case "stats.goals":
      sql = `
        DELETE FROM stats.goals
        WHERE goal_id = $1
      `;
      break;
    case "stats.saves":
      sql = `
        DELETE FROM stats.shots
        WHERE shot_id = $1
      `;
      break;
    case "stats.penalties":
      sql = `
        DELETE FROM stats.penalties
        WHERE penalty_id = $1
      `;
      break;
    default:
      sql = `
        DELETE FROM stats.shots
        WHERE shot_id = $1
      `;
      break;
  }

  await db
    .query(sql, [state.data.id])
    .then(() => {
      return {
        message: "Feed item deleted!",
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  if (state?.link) redirect(state?.link);
}
