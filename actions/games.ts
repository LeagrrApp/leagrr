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

/* ---------- CREATE ---------- */

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

  let createGameSuccessful = false;

  try {
    // Check to see if the user is allowed to create a season for this league
    const { canEdit } = await canEditLeague(submittedData.league_id);

    if (!canEdit) {
      return {
        message: "You do not have permission to create games for this division",
        status: 400,
        link: state?.link,
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

    const tz_offset = parseInt(formData.get("tz_offset") as string) * -1;
    const date_string = `${(formData.get("date_time") as string).replace("T", " ")}:00${tz_offset < 0 ? tz_offset : `+${tz_offset}`}`;

    const insertSql = `
      INSERT INTO league_management.games
        (home_team_id, away_team_id, division_id, date_time, arena_id, status)
      VALUES
        ($1, $2, $3, $4, $5, $6)
      RETURNING game_id
    `;

    const { rows } = await db.query<{ game_id: number }>(insertSql, [
      submittedData.home_team_id,
      submittedData.away_team_id,
      submittedData.division_id,
      date_string,
      submittedData.arena_id,
      submittedData.status,
    ]);

    if (!rows[0]) throw new Error("Sorry, unable to create game.");

    createGameSuccessful = true;
  } catch (err) {
    if (err instanceof Error) {
      return {
        message: err.message,
        status: 400,
        link: state?.link,
        data: submittedData,
      };
    }
    return {
      message: "Something went wrong.",
      status: 500,
      link: state?.link,
      data: submittedData,
    };
  }

  if (state?.link && createGameSuccessful) redirect(state?.link);
}

const AddGameFeedShotSchema = z.object({
  game_id: z.number().min(1),
  user_id: z.number().min(1),
  team_id: z.number().min(1),
  period: z.number().min(1),
  minutes: z.number(),
  seconds: z.number(),
  coordinates: z.string({ message: "Please provide stat location." }),
  shorthanded: z.boolean().optional(),
  power_play: z.boolean().optional(),
  empty_net: z.boolean().optional(),
  rebound: z.boolean().optional(),
  assists: z.array(z.string()),
  penalty_minutes: z.number().min(1).optional(),
  infraction: z
    .string()
    .min(2, { message: "Infraction must be at least 2 characters long." })
    .trim()
    .optional(),
  goalie_id: z.number().min(1).optional(),
  opposition_id: z.number().min(1).optional(),
});

type AddGameFeedErrorProps = {
  game_id?: string[] | undefined;
  user_id?: string[] | undefined;
  team_id?: string[] | undefined;
  period?: string[] | undefined;
  minutes?: string[] | undefined;
  seconds?: string[] | undefined;
  coordinates?: string[] | undefined;
  penalty_minutes?: string[] | undefined;
  infraction?: string[] | undefined;
  opposition_id?: string[] | undefined;
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
    coordinates?: string;
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
  const submittedData = {
    game_id: parseInt(formData.get("game_id") as string),
    user_id: parseInt(formData.get("user_id") as string),
    team_id: parseInt(formData.get("team_id") as string),
    period: parseInt(formData.get("period") as string),
    minutes: parseInt(formData.get("minutes") as string),
    seconds: parseInt(formData.get("seconds") as string),
    coordinates: formData.get("coordinates") as string,
    shorthanded: formData.get("shorthanded") === "true",
    power_play: formData.get("power_play") === "true",
    empty_net: formData.get("empty_net") === "true",
    rebound: formData.get("rebound") === "true",
    assists: formData.getAll("assists") as string[],
    penalty_minutes:
      parseInt(formData.get("penalty_minutes") as string) || undefined,
    infraction: (formData.get("infraction") as string) || undefined,
    goalie_id: parseInt(formData.get("goalie_id") as string) || undefined,
    opposition_id:
      parseInt(formData.get("opposition_id") as string) || undefined,
  };

  // Validate form fields
  const validatedFields = AddGameFeedShotSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      ...state,
      errors: validatedFields.error.flatten().fieldErrors,
      data: submittedData,
    };
  }

  // initialize success check
  let successful = false;

  try {
    const period_time = createPeriodTimeString(
      submittedData.minutes,
      submittedData.seconds,
    );

    // initialize inserted_goal_id
    let inserted_goal_id: number | null = null;

    // goal or shot
    if (type === "goal" || type === "shot") {
      // -- add goal
      if (type === "goal") {
        const goalSql = `
          INSERT INTO stats.goals
            (game_id, user_id, team_id, period, period_time, coordinates, shorthanded, power_play, empty_net)
          VALUES
            ($1, $2, $3, $4, $5, $6, $7, $8, $9)
          RETURNING
            goal_id
        `;

        const { rows: goalRows } = await db.query<{ goal_id: number }>(
          goalSql,
          [
            submittedData.game_id,
            submittedData.user_id,
            submittedData.team_id,
            submittedData.period,
            period_time,
            submittedData.coordinates,
            submittedData.shorthanded,
            submittedData.power_play,
            submittedData.empty_net,
          ],
        );

        if (!goalRows[0])
          throw new Error("Sorry, there was a problem creating goal.");

        // set inserted goal id returned by goal insert statement
        inserted_goal_id = goalRows[0].goal_id;

        // -- -- add assists
        if (submittedData?.assists?.length && inserted_goal_id) {
          const assistSql = `
            INSERT INTO stats.assists
              (goal_id, game_id, user_id, team_id, primary_assist)
            VALUES
              ($1, $2, $3, $4, $5)
          `;

          // Loop through each assist and add to database
          let assistCount = 0;
          for await (const assist of submittedData.assists) {
            const { rowCount: assistsRowCount } = await db.query(assistSql, [
              inserted_goal_id,
              submittedData.game_id,
              assist,
              submittedData.team_id,
              assistCount === 0,
            ]);

            if (assistsRowCount !== 1) {
              throw new Error(`Sorry, there was a problem creating assist.`);
            }

            assistCount++;
          }
        }
      }

      // -- add shot
      const shotSql = `
        INSERT INTO stats.shots
          (game_id, user_id, team_id, period, period_time, coordinates, goal_id, shorthanded, power_play)
        VALUES
          ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        RETURNING
          shot_id
      `;

      const { rows: shotRows } = await db.query<{ shot_id: number }>(shotSql, [
        submittedData.game_id,
        submittedData.user_id,
        submittedData.team_id,
        submittedData.period,
        period_time,
        submittedData.coordinates,
        inserted_goal_id,
        submittedData.shorthanded,
        submittedData.power_play,
      ]);

      if (!shotRows[0]) {
        throw new Error("Sorry, there was a problem creating shot.");
      }

      if (type !== "goal" && submittedData.goalie_id !== 0) {
        // -- -- add save if not goal and the team has a goalie registered

        const saveSql = `
          INSERT INTO stats.saves
            (game_id, user_id, team_id, shot_id, period, period_time, penalty_kill, rebound)
          VALUES
            ($1, $2, $3, $4, $5, $6, $7, $8)
        `;

        const { rowCount: saveRowCount } = await db.query(saveSql, [
          submittedData.game_id,
          submittedData.goalie_id,
          submittedData.opposition_id,
          shotRows[0].shot_id,
          submittedData.period,
          period_time,
          submittedData.shorthanded,
          submittedData.rebound,
        ]);

        if (saveRowCount !== 1) {
          throw new Error("Sorry, there was a problem creating save.");
        }
      }
    }

    // penalty
    if (type === "penalty") {
      const penaltySql = `
        INSERT INTO stats.penalties
          (game_id, user_id, team_id, period, period_time, coordinates, infraction, minutes)
        VALUES
          ($1, $2, $3, $4, $5, $6, $7, $8)
      `;

      const { rowCount: penaltyRowCount } = await db.query(penaltySql, [
        submittedData.game_id,
        submittedData.user_id,
        submittedData.team_id,
        submittedData.period,
        period_time,
        submittedData.coordinates,
        submittedData.infraction,
        submittedData.penalty_minutes,
      ]);

      if (penaltyRowCount !== 1) {
        throw new Error("Sorry, there was a problem creating penalty.");
      }
    }

    successful = true;
  } catch (err) {
    if (err instanceof Error) {
      return {
        ...state,
        message: err.message,
        status: 400,
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

  if (state?.link && successful) redirect(`${state?.link}#game-feed-add`);
}

/* ---------- READ ---------- */

export async function getGame(game_id: number) {
  // verify user is signed in
  await verifySession();

  try {
    const sql = `
      SELECT
        g.game_id,
        g.home_team_id,
        g.home_team_score,
        ht.name AS home_team,
        ht.color AS home_team_color,
        ht.slug AS home_team_slug,
        sum(
          CASE
            WHEN s.team_id = ht.team_id THEN 1
            ELSE 0
          END
        ) AS home_team_shots,
        g.away_team_id,
        g.away_team_score,
        at.name AS away_team,
        at.color AS away_team_color,
        at.slug AS away_team_slug,
        sum(
          CASE
            WHEN s.team_id = at.team_id THEN 1
            ELSE 0
          END
        ) AS away_team_shots,
        g.division_id,
        g.date_time,
        g.arena_id,
        a.name AS arena,
        v.name AS venue,
        g.status,
        g.has_been_published
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
        g.game_id = $1
      GROUP BY g.game_id, ht.name, ht.color, ht.slug, at.name, at.color, at.slug, a.name, v.name
    `;

    const { rows } = await db.query<GameData>(sql, [game_id]);

    if (!rows[0])
      throw new Error("Sorry, there was a problem loading the game data.");

    return {
      message: "Game data retrieved.",
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

export async function getGameUrl(game_id: number) {
  // verify user is signed in
  await verifySession();

  try {
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
        s.season_id = d.season_id
      JOIN
        league_management.leagues AS l
      ON
        s.league_id = l.league_id
      WHERE
        game_id = $1
    `;

    const { rows } = await db.query<{
      game_id: number;
      league_slug: string;
      division_slug: string;
      season_slug: string;
    }>(sql, [game_id]);

    if (!rows[0]) throw new Error("Sorry, unable to load game URL.");

    return {
      message: "Game url created!",
      status: 200,
      data: createDashboardUrl({
        l: rows[0].league_slug,
        s: rows[0].season_slug,
        d: rows[0].division_slug,
        g: rows[0].game_id,
      }),
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

export async function canEditGame(
  game_id: number,
  options?: {
    user_id?: number;
  },
) {
  try {
    const sql = `
      SELECT
        s.league_id
      FROM
        league_management.games AS g
      JOIN
        league_management.divisions AS d
      ON
        g.division_id = d.division_id
      JOIN
        league_management.seasons AS s
      ON
        d.season_id = s.season_id
      WHERE
      game_id = $1
    `;

    const { rows } = await db.query<{ league_id: string }>(sql, [game_id]);

    if (!rows[0]) throw new Error("Game not found.");

    const { league_id } = rows[0];

    const canEditLeagueResult = await canEditLeague(league_id, options);

    return canEditLeagueResult;
  } catch (err) {
    if (err instanceof Error) {
      return {
        message: err.message,
        status: 400,
        canEdit: false,
      };
    }
    return {
      message: "Something went wrong",
      status: 500,
      canEdit: false,
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

export async function getTeamGameStats(
  game_id: number,
  team_id: number,
  division_id: number,
) {
  // verify user is signed in
  await verifySession();

  try {
    const sql = `
      SELECT
        user_id,
        username,
        first_name,
        last_name,
        position,
        number,
        goals,
        assists,
        shots,
        saves,
        penalties_in_minutes,
        (goals + assists) AS points
      FROM
      (
        SELECT
          u.user_id,
          u.username,
          u.first_name,
          u.last_name,
          dr.position,
          dr.number,
          COUNT(DISTINCT g.goal_id)::int AS goals,
          COUNT(DISTINCT a.assist_id)::int AS assists,
          COUNT(DISTINCT s.shot_id)::int AS shots,
          COUNT(DISTINCT sa.shot_id)::int AS saves,
          (SELECT COALESCE(SUM(minutes), 0) FROM stats.penalties AS p WHERE p.user_id = u.user_id AND p.game_id = $1)::int as penalties_in_minutes
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
        LEFT JOIN
          stats.goals AS g
        ON
          g.user_id = u.user_id AND g.game_id = $1
        LEFT JOIN
          stats.assists AS a
        ON
          a.user_id = u.user_id AND a.game_id = $1
        LEFT JOIN
          stats.shots AS s
        ON
          s.user_id = u.user_id AND s.game_id = $1
        LEFT JOIN
          stats.saves AS sa
        ON
          sa.user_id = u.user_id AND sa.game_id = $1
        WHERE
          dt.team_id = $2
          AND
          dt.division_id = $3
          AND
          dr.roster_role IN (2, 3, 4)
        GROUP BY (u.username, u.user_id, u.first_name, u.last_name, dr.position, dr.number)
      )
      ORDER BY points DESC, goals DESC, assists DESC, shots DESC, last_name ASC, first_name ASC
    `;

    const { rows } = await db.query<PlayerStats>(sql, [
      game_id,
      team_id,
      division_id,
    ]);

    return {
      message: "Team game stats loaded",
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

  try {
    // get all shots
    const shotsSql = `
      SELECT
        s.tableoid::regclass AS type,
        s.shot_id AS item_id,
        u.username,
        u.first_name,
        u.last_name,
        s.user_id,
        s.team_id,
        t.name AS team,
        s.period,
        s.period_time,
        s.coordinates
      FROM
        stats.shots AS s
      JOIN
        admin.users AS u
      ON
        s.user_id = u.user_id
      JOIN
        league_management.teams AS t
      ON
        s.team_id = t.team_id
      WHERE
        game_id = $1
      ORDER BY
        period ASC, period_time ASC
    `;

    const { rows: shots } = await db.query<StatsData>(shotsSql, [game_id]);

    // get all goals
    const goalsSql = `
      SELECT
        g.tableoid::regclass AS type,
        g.goal_id AS item_id,
        g.user_id,
        u.username,
        u.first_name,
        u.last_name,
        g.team_id,
        t.name AS team,
        g.period,
        g.period_time,
        g.shorthanded,
        g.power_play,
        g.empty_net,
        g.coordinates
      FROM
        stats.goals AS g
      JOIN
          admin.users AS u
        ON
          g.user_id = u.user_id
      JOIN
        league_management.teams AS t
      ON
        g.team_id = t.team_id
      WHERE
        game_id = $1
      ORDER BY
        period ASC, period_time ASC
    `;

    const { rows: goals } = await db.query<StatsData>(goalsSql, [game_id]);

    // get all assists
    const assistsSql = `
      SELECT
        a.tableoid::regclass AS type,
        a.assist_id AS item_id,
        a.goal_id,
        a.user_id,
        u.username,
        u.first_name,
        u.last_name,
        a.team_id,
        t.name AS team,
        a.primary_assist
      FROM
        stats.assists AS a
      JOIN
          admin.users AS u
        ON
          a.user_id = u.user_id
      JOIN
        league_management.teams AS t
      ON
        a.team_id = t.team_id
      WHERE
        game_id = $1
      ORDER BY
        goal_id ASC, primary_assist DESC
    `;

    const { rows: assists } = await db.query<StatsData>(assistsSql, [game_id]);

    // get all saves
    const savesSql = `
      SELECT
        s.tableoid::regclass AS type,
        s.save_id AS item_id,
        s.user_id,
        u.username,
        u.first_name,
        u.last_name,
        s.team_id,
        t.name AS team,
        s.period,
        s.period_time,
        s.penalty_kill,
        s.rebound
      FROM
        stats.saves AS s
      JOIN
          admin.users AS u
      ON
        s.user_id = u.user_id
      JOIN
        league_management.teams AS t
      ON
        s.team_id = t.team_id
      WHERE
        game_id = $1
      ORDER BY
        period ASC, period_time ASC
    `;

    const { rows: saves } = await db.query<StatsData>(savesSql, [game_id]);

    // get all penalties
    const penaltiesSql = `
      SELECT
        p.tableoid::regclass AS type,
        p.penalty_id AS item_id,
        p.user_id,
        u.username,
        u.first_name,
        u.last_name,
        p.team_id,
        t.name AS team,
        p.period,
        p.period_time,
        p.infraction,
        p.minutes,
        p.coordinates
      FROM
        stats.penalties AS p
      JOIN
          admin.users AS u
      ON
        p.user_id = u.user_id
      JOIN
        league_management.teams AS t
      ON
        p.team_id = t.team_id
      WHERE
        game_id = $1
      ORDER BY
        period ASC, period_time ASC
    `;

    const { rows: penalties } = await db.query<StatsData>(penaltiesSql, [
      game_id,
    ]);

    // attach assists to goals
    const goalsWithAssists: StatsData[] = [];

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
      shots: 1,
      goals: 2,
      save: 3,
      penalties: 4,
      default: Number.MAX_VALUE,
    };

    // combine into single array, order by period & time
    // when multiple different types share same period & time,
    // put in this order: shot, goal, save, penalty
    const gameFeedItems = [
      ...shots,
      ...goalsWithAssists,
      ...saves,
      ...penalties,
    ]
      .sort(
        (a, b) =>
          a.period - b.period ||
          (a.period_time.minutes || 0) * 60 +
            (a.period_time.seconds || 0) -
            ((b.period_time.minutes || 0) * 60 +
              (b.period_time.seconds || 0)) ||
          (typeOrder[a.type] || typeOrder.default) -
            (typeOrder[b.type] || typeOrder.default),
      )
      .map((item) => {
        const transformedItem = { ...item };

        transformedItem.type = item.type.replace("stats.", "");

        return transformedItem;
      });

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

export async function getGameTeamRosters(
  away_team_id: number,
  home_team_id: number,
  division_id: number,
) {
  // verify user is signed in
  await verifySession();

  try {
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

    const { rows } = await db.query<TeamRosterItem>(rostersSql, [
      away_team_id,
      home_team_id,
      division_id,
    ]);

    return {
      message: "Game team rosters loaded!",
      status: 200,
      data: {
        away_roster: rows.filter((p) => p.team_id === away_team_id),
        home_roster: rows.filter((p) => p.team_id === home_team_id),
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

/* ---------- UPDATE ---------- */

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

  // initialize success check
  let editSuccessful = false;

  // create returnable state data object that is compatible with form fields
  const returnableStateData = {
    home_team_id: submittedData.home_team_id,
    away_team_id: submittedData.away_team_id,
    arena_id: submittedData.arena_id,
    date_time: formData.get("date_time") as string,
    status: submittedData.status,
  };

  try {
    // Check to see if the user is allowed to create a season for this league
    const { canEdit } = await canEditLeague(submittedData.league_id);

    if (!canEdit) {
      return {
        message: "You do not have permission to edit this game.",
        status: 400,
        data: returnableStateData,
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
        data: returnableStateData,
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

    const { rowCount } = await db.query(updateSql, [
      submittedData.home_team_id,
      submittedData.away_team_id,
      submittedData.arena_id,
      submittedData.date_time,
      submittedData.status,
      submittedData.game_id,
    ]);

    if (rowCount === 0)
      throw new Error("Sorry, there was an issue updating the game.");

    editSuccessful = true;
  } catch (err) {
    if (err instanceof Error) {
      return {
        message: err.message,
        status: 400,
        data: returnableStateData,
      };
    }
    return {
      message: "Something went wrong.",
      status: 500,
      data: returnableStateData,
    };
  }

  if (state?.link && editSuccessful) redirect(state?.link);
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
  // initialize success check
  let successful = false;

  try {
    if (
      !state ||
      !state.data ||
      !state.data.game ||
      !state.data.league ||
      !state.link
    )
      throw new Error("Missing necessary data to set the score!");

    // verify user is signed in
    await verifySession();

    const { canEdit } = await canEditLeague(state.data.league);

    if (!canEdit) {
      return {
        ...state,
        message: "You do not have permission to create games for this division",
        status: 401,
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

    const { rowCount } = await db.query(sql, [
      gameScoreData.home_team_score,
      gameScoreData.away_team_score,
      state.data.game.game_id,
    ]);

    if (rowCount === 0)
      throw new Error("Sorry, there was a problem setting the game score.");

    successful = true;
  } catch (err) {
    if (err instanceof Error) {
      return {
        message: err.message,
        status: 400,
        data: state?.data,
        link: state?.link,
      };
    }
    return {
      message: "Something went wrong.",
      status: 500,
      data: state?.data,
      link: state?.link,
    };
  }

  if (state.link && successful) redirect(state.link);
}

export default async function endGame(state: {
  canEdit: boolean;
  game_id: number;
  backLink: string;
}) {
  // Verify user session
  await verifySession();

  // Initialize success message
  let success = false;

  // Initialize response status
  let status = 400;
  try {
    // TODO: create a canEditGame function to check this on backend
    if (!state.canEdit) {
      status = 401;
      throw new Error("You do not have permission to end this game.");
    }

    const sql = `
    UPDATE league_management.games
    SET status = 'completed'
    WHERE game_id = $1
  `;

    const { rowCount } = await db.query(sql, [state.game_id]);

    if (rowCount !== 1) {
      throw new Error("Sorry, there was a problem ending this game.");
    }

    success = true;
  } catch (err) {
    if (err instanceof Error) {
      return {
        ...state,
        message: err.message,
        status,
      };
    }
    return {
      ...state,
      message: "Something went wrong.",
      status: 500,
    };
  }

  if (state.backLink && success) redirect(state.backLink);
}

/* ---------- DELETE ---------- */

export async function deleteGame(state: {
  data: {
    game_id: number;
  };
  link: string;
}) {
  // Verify user session
  await verifySession();

  // initialize success
  let success = false;

  // set default status code;
  let status = 400;
  try {
    // confirm can edit this game
    const { canEdit } = await canEditGame(state.data.game_id);

    if (!canEdit) {
      status = 401;
      throw new Error("You do not have permission to delete this game.");
    }

    const sql = `
      DELETE FROM league_management.games
      WHERE game_id = $1
    `;

    const { rowCount } = await db.query(sql, [state.data.game_id]);

    if (rowCount !== 1)
      throw new Error("Sorry, there was a problem deleting the game.");

    success = true;
  } catch (err) {
    if (err instanceof Error) {
      return {
        ...state,
        message: err.message,
        status,
      };
    }
    return {
      ...state,
      message: "Something went wrong.",
      status: 500,
    };
  }

  if (success && state.link) redirect(state.link);
}

type DeleteFeedItemState = FormState<undefined, { id: number; type: string }>;

export async function deleteFeedItem(
  state: DeleteFeedItemState,
): Promise<DeleteFeedItemState> {
  // initialize success check
  let success = false;

  try {
    if (!state) {
      throw new Error('"Missing necessary data to delete feed item!"');
    }

    let sql: string;

    switch (state.data.type) {
      case "goals":
        sql = `
        DELETE FROM stats.goals
        WHERE goal_id = $1
      `;
        break;
      case "saves":
        sql = `
        DELETE FROM stats.saves
        WHERE save_id = $1
      `;
        break;
      case "penalties":
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

    const { rowCount } = await db.query(sql, [state.data.id]);

    if (rowCount !== 1)
      throw new Error("Sorry, there was a problem deleting feed item.");

    success = true;
  } catch (err) {
    if (err instanceof Error) {
      return {
        ...state,
        message: err.message,
        status: 400,
        data: {
          id: state?.data?.id || 0,
          type: state?.data?.type || "goal",
        },
      };
    }
    return {
      ...state,
      message: "Something went wrong.",
      status: 500,
      data: {
        id: state?.data?.id || 0,
        type: state?.data?.type || "goal",
      },
    };
  }

  if (state?.link && success) redirect(state?.link);
}
