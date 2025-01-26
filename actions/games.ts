"use server";

import { verifySession } from "@/lib/session";
import { canEditLeague } from "./leagues";
import { db } from "@/db/pg";
import { z } from "zod";
import { game_status_options } from "@/lib/definitions";
import { isObjectEmpty } from "@/utils/helpers/objects";
import { redirect } from "next/navigation";

export async function getAddGameData(
  division_slug: string,
  season_slug: string,
  league_slug: string
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

const GameFormSchema = z.object({
  game_id: z.number().min(1).optional(),
  division_id: z.number().min(1),
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

type GameFormState =
  | {
      errors?: GameErrorProps;
      message?: string;
      status?: number;
      link?: string;
      data?: {
        home_team_id: number;
        away_team_id: number;
        arena_id: number;
        date_time: string;
        status: string;
      };
    }
  | undefined;

export async function createGame(
  state: GameFormState,
  formData: FormData
): Promise<GameFormState> {
  // check user is logged in
  await verifySession();

  const gameData = {
    division_id: parseInt(formData.get("division_id") as string),
    league_id: parseInt(formData.get("league_id") as string),
    home_team_id: parseInt(formData.get("home_team_id") as string),
    away_team_id: parseInt(formData.get("away_team_id") as string),
    arena_id: parseInt(formData.get("arena_id") as string),
    date_time: new Date(formData.get("date_time") as string),
    status: formData.get("status") as string,
  };

  // Check to see if the user is allowed to create a season for this league
  const { canEdit } = await canEditLeague(gameData.league_id);

  if (!canEdit) {
    return {
      message: "You do not have permission to create games for this division",
      status: 400,
    };
  }

  let errors: GameErrorProps = {};

  // Validate form fields
  const validatedFields = GameFormSchema.safeParse(gameData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    errors = validatedFields.error.flatten().fieldErrors;
  }

  if (gameData.home_team_id === gameData.away_team_id) {
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
        home_team_id: gameData.home_team_id,
        away_team_id: gameData.away_team_id,
        arena_id: gameData.arena_id,
        date_time: formData.get("date_time") as string,
        status: gameData.status,
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
      gameData.home_team_id,
      gameData.away_team_id,
      gameData.division_id,
      gameData.date_time,
      gameData.arena_id,
      gameData.status,
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
    };
  }

  // TODO: handle if there link isn't working

  state?.link && redirect(state?.link);
}

export async function getGame(game_id: number) {
  // verify user is signed in
  await verifySession();

  const sql = `
    SELECT
      game_id,
      home_team_id,
      (SELECT name FROM league_management.teams WHERE team_id = g.home_team_id) AS home_team,
      (SELECT slug FROM league_management.teams WHERE team_id = g.home_team_id) AS home_team_slug,
      home_team_score,
      (SELECT COUNT(*) FROM stats.goals AS goal WHERE goal.team_id = g.home_team_id AND g.game_id = $1)::int AS home_team_stats_goals,
      (SELECT COUNT(*) FROM stats.shots AS sh WHERE sh.team_id = g.home_team_id AND sh.game_id = $1)::int AS home_team_shots,
      away_team_id,
      (SELECT name FROM league_management.teams WHERE team_id = g.away_team_id) AS away_team,
      (SELECT slug FROM league_management.teams WHERE team_id = g.away_team_id) AS away_team_slug,
      away_team_score,
      (SELECT COUNT(*) FROM stats.goals AS goal WHERE goal.team_id = g.away_team_id AND g.game_id = $1)::int AS away_team_stats_goals,
      (SELECT COUNT(*) FROM stats.shots AS sh WHERE sh.team_id = g.away_team_id AND sh.game_id = $1)::int AS away_team_shots,
      division_id,
      date_time,
      arena_id,
      (SELECT name FROM league_management.arenas WHERE arena_id = g.arena_id) AS arena,
      (SELECT name FROM league_management.venues WHERE venue_id = (
        SELECT venue_id FROM league_management.arenas WHERE arena_id = g.arena_id
      )) AS venue,
      status
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

const GameScoreSchema = z.object({
  home_team_score: z.number().min(0),
  away_team_score: z.number().min(0),
});

type GameScoreState =
  | {
      errors?: {
        home_team_score?: string[] | undefined;
        away_team_score?: string[] | undefined;
      };
      message?: string;
      status?: number;
      link?: string;
      game?: GameData;
      league?: string;
    }
  | undefined;

export async function setGameScore(
  state: GameScoreState,
  formData: FormData
): Promise<GameScoreState> {
  if (!state || !state.league || !state.game || !state.link)
    return {
      message: "Missing necessary data to set the score!",
      status: 400,
    };

  // verify user is signed in
  await verifySession();

  const { canEdit } = await canEditLeague(state.league);

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
      state.game.game_id,
    ])
    .then((res) => {
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

  if (gameScoreResult.status === 400) return gameScoreResult;

  redirect(state.link);
}

export async function getTeamGameStats(game_id: number, team_id: number) {
  // verify user is signed in
  await verifySession();

  const sql = `
    SELECT
      u.user_id,
      u.username,
      u.first_name,
      u.last_name,
      tm.number,
      tm.position,
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
      league_management.team_memberships AS tm
    JOIN
      admin.users AS u
    ON
      u.user_id = tm.user_id
    WHERE
      tm.team_id = $2
    ORDER BY points DESC, goals DESC, assists DESC, shots DESC, last_name ASC, first_name ASC
  `;

  const teamGameStatsResult: ResultProps<PlayerStats[]> = await db
    .query(sql, [game_id, team_id])
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
