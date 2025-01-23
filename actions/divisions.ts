"use server";

import { db } from "@/db/pg";
import { gender_options, status_options } from "@/lib/definitions";
import { verifySession } from "@/lib/session";
import { z } from "zod";
import { canEditLeague } from "./leagues";
import { redirect } from "next/navigation";

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

type DivisionFormState =
  | {
      errors?: DivisionErrorProps;
      message?: string;
      status?: number;
      link?: string;
    }
  | undefined;

export async function createDivision(
  state: DivisionFormState,
  formData: FormData
): Promise<DivisionFormState> {
  // check user is logged in
  await verifySession();

  const divisionData = {
    name: formData.get("name"),
    description: formData.get("description"),
    season_id: parseInt(formData.get("season_id") as string),
    league_id: parseInt(formData.get("league_id") as string),
    tier: parseInt(formData.get("tier") as string),
    gender: formData.get("gender"),
    join_code: formData.get("join_code"),
  };

  // Check to see if the user is allowed to create a season for this league
  const { canEdit } = await canEditLeague(divisionData.league_id);

  if (!canEdit) {
    return {
      message:
        "You do not have permission to create a division for this season",
      status: 400,
    };
  }

  // Validate form fields
  const validatedFields = DivisionFormSchema.safeParse(divisionData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      errors: validatedFields.error.flatten().fieldErrors,
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
      divisionData.name,
      divisionData.description,
      divisionData.season_id,
      divisionData.tier,
      divisionData.gender,
      divisionData.join_code,
      divisionData.league_id,
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
      `/dashboard/l/${insertResult?.data.league_slug}/s/${insertResult?.data.season_slug}/d/${insertResult?.data.slug}`
    );

  return insertResult;
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

export async function getDivision(
  division_slug: string,
  season_slug: string,
  league_slug: string
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
            SUM(home_team_score)
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
            SUM(away_team_score)
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
            SUM(away_team_score)
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
            SUM(home_team_score)
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
    ORDER BY points DESC

  `;

  const divisionTeamsResult: ResultProps<TeamStandingsData[]> = await db
    .query(divisionTeamsSql, [divisionResult.data.division_id])
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

  const { canEdit } = await canEditLeague(league_slug);

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
      status NOT IN ('draft', 'archived')
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

  if (divisionTeamsResult.data) {
    fullDivisionData.data.teams = divisionTeamsResult.data;
  }

  if (divisionGamesResult.data) {
    fullDivisionData.data.games = divisionGamesResult.data;
  }

  return fullDivisionData;
}

export async function editDivision(
  state: DivisionFormState,
  formData: FormData
): Promise<DivisionFormState> {
  // check user is logged in
  await verifySession();

  const divisionData = {
    name: formData.get("name"),
    description: formData.get("description"),
    division_id: parseInt(formData.get("division_id") as string),
    league_id: parseInt(formData.get("league_id") as string),
    tier: parseInt(formData.get("tier") as string),
    gender: formData.get("gender"),
    join_code: formData.get("join_code"),
    status: formData.get("status"),
  };

  // Check to see if the user is allowed to create a season for this league
  const { canEdit } = await canEditLeague(divisionData.league_id);

  if (!canEdit) {
    return {
      message:
        "You do not have permission to create a division for this season",
      status: 400,
    };
  }

  // Validate form fields
  const validatedFields = DivisionFormSchema.safeParse(divisionData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      errors: validatedFields.error.flatten().fieldErrors,
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
      divisionData.name,
      divisionData.description,
      divisionData.tier,
      divisionData.gender,
      divisionData.join_code,
      divisionData.status,
      divisionData.division_id,
    ])
    .then((res) => {
      console.log(res);
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

  if (state?.link) redirect(state?.link);

  return { ...updateResult };
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
    console.log("can't delete");
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

  redirect(state.backLink);
}
