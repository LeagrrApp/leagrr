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
import { getGamesByDivisionId } from "./games";
import { canEditLeague } from "./leagues";
import {
  getAssistLeadersByDivision,
  getGoalLeadersByDivision,
  getPointLeadersByDivision,
  getShutoutLeadersByDivision,
} from "./stats";
import { canEditTeam, getTeamsByDivisionId } from "./teams";
import { getVenuesByDivisionId } from "./venues";

/* ---------- CREATE ---------- */

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
      | "status"
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
  };

  // initialize redirect link
  let redirectLink: string | undefined = undefined;

  try {
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
        (name, description, season_id, tier, gender)
      VALUES
        ($1, $2, $3, $4, $5)
      RETURNING
        slug,
        (SELECT slug FROM league_management.seasons as s WHERE s.season_id = $3) AS season_slug,
        (SELECT slug FROM league_management.leagues as l WHERE l.league_id = $6) AS league_slug
    `;

    // query database
    const { rows } = await db.query(sql, [
      submittedData.name,
      submittedData.description,
      submittedData.season_id,
      submittedData.tier,
      submittedData.gender,
      submittedData.league_id,
    ]);

    if (!rows[0])
      throw new Error("Sorry, there was a problem creating the division");

    redirectLink = createDashboardUrl({
      l: rows[0].league_slug,
      s: rows[0].season_slug,
      d: rows[0].slug,
    });
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

export async function getDivision(
  division_slug: string,
  season_slug: string,
  league_slug: string,
): Promise<ResultProps<DivisionData>> {
  // check user is logged in
  await verifySession();

  try {
    // check if user has league role or is admin by checking if canEdit
    const { canEdit } = await canEditLeague(league_slug);

    let divisionSql = `
      SELECT
        d.division_id,
        d.name,
        d.description,
        d.slug,
        d.gender,
        d.tier,
        d.join_code,
        d.status,
        s.slug AS season_slug,
        s.season_id,
        l.slug AS league_slug,
        l.league_id
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
        d.slug = $1
        AND
        s.slug = $2
        AND
        l.slug = $3
    `;

    // if does not have league role or league admin, add restriction to public league only
    if (!canEdit) {
      divisionSql = `
        ${divisionSql}
        AND
        d.status = 'public'
      `;
    }

    const { rows } = await db.query<DivisionData>(divisionSql, [
      division_slug,
      season_slug,
      league_slug,
    ]);

    if (!rows[0]) throw new Error("Division not found.");

    const division = rows[0];

    const divisionStandingsResult = await getDivisionStandings(
      division.division_id,
    );

    if (divisionStandingsResult.data) {
      division.teams = divisionStandingsResult.data;
    }

    const { data: divisionGames } = await getGamesByDivisionId(
      division.division_id,
      league_slug,
    );

    if (divisionGames) {
      division.games = divisionGames;
    }

    return {
      message: "Division loaded.",
      status: 200,
      data: division,
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

export async function getDivisionMetaInfo(
  division_slug: string,
  season_slug: string,
  league_slug: string,
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
        d.name AS division,
        d.description AS description,
        s.name AS season,
        l.name AS league
      FROM
        league_management.divisions AS d
      JOIN
        league_management.seasons AS s
      ON
        d.season_id = s.season_id
      JOIN
        league_management.leagues AS l
      ON
        s.league_id = l.league_id
      WHERE
        d.slug = $1
        AND
        s.slug = $2
        AND
        l.slug = $3
    `;

    const { rows } = await db.query<{
      division: string;
      description: string;
      season: string;
      league: string;
    }>(sql, [division_slug, season_slug, league_slug]);

    const { division, description, season, league } = rows[0];

    let title = createMetaTitle([division, season, league]);

    if (options?.prefix)
      title = createMetaTitle([options.prefix, division, season, league]);

    return {
      message: "Division meta data loaded!",
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

export async function getDivisionUrlById(
  division_id: number,
): Promise<ResultProps<string>> {
  try {
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

    const { rows } = await db.query<{
      division_slug: string;
      season_slug: string;
      league_slug: string;
    }>(sql, [division_id]);

    if (!rows[0]) throw new Error("Division not found!");

    return {
      message: "Division url found",
      status: 200,
      data: createDashboardUrl({
        l: rows[0].league_slug,
        s: rows[0].season_slug,
        d: rows[0].division_slug,
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

export async function getDivisionByJoinCode(
  join_code: string,
): Promise<ResultProps<DivisionData>> {
  // check user is logged in
  await verifySession();

  try {
    const divisionSql = `
      SELECT
        d.division_id,
        d.name,
        d.description,
        d.slug,
        d.gender,
        d.tier,
        d.join_code,
        d.status,
        s.slug AS season_slug,
        s.season_id,
        s.name AS season_name,
        l.slug AS league_slug,
        l.league_id,
        l.name AS league_name
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
        d.join_code = $1
        AND
        d.status = 'public'
    `;

    const { rows } = await db.query<DivisionData>(divisionSql, [join_code]);

    if (!rows[0]) throw new Error("Division not found.");

    const division = rows[0];

    return {
      message: "Division loaded.",
      status: 200,
      data: division,
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

export async function getDivisionOptionsForGames(
  division_id: number,
): Promise<ResultProps<AddGameData>> {
  // This function loads the list of teams in the division and the list of venues the league uses

  // check user is logged in
  await verifySession();

  try {
    // get list of teams
    const { data: teamsList } = await getTeamsByDivisionId(division_id);

    // get list of venues
    const { data: locationsList } = await getVenuesByDivisionId(division_id);

    return {
      message: "Game add data found",
      status: 200,
      data: {
        teams: teamsList || [],
        locations: locationsList || [],
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
      status: 400,
    };
  }
}

export async function getDivisionStandings(
  division_id: number,
): Promise<ResultProps<TeamStandingsData[]>> {
  try {
    const divisionTeamsSql = `
      SELECT 
        team_id,
        name,
        slug,
        status,
        games_played,
        wins,
        ties,
        losses,
        (wins * 2) + ties as points,
        goals_for,
        goals_against,
        goals_for - goals_against as plus_minus
      FROM (
        SELECT
          t.team_id,
          t.name,
          t.slug,
          t.status,
          SUM(
            CASE WHEN 
            g.status = 'completed'
            AND
            g.division_id = $1
            THEN 1 ELSE 0 END
          ) as games_played,
          SUM(
            CASE WHEN 
            (
              (g.home_team_id = t.team_id AND g.home_team_score > g.away_team_score)
              OR 
              (g.away_team_id = t.team_id AND g.away_team_score > g.home_team_score)
            )
            AND
            g.status = 'completed'
            AND
            g.division_id = $1
            THEN 1 ELSE 0 END
          ) as wins,
          SUM(
            CASE WHEN 
            (
              (g.home_team_id = t.team_id AND g.home_team_score < g.away_team_score)
              OR 
              (g.away_team_id = t.team_id AND g.away_team_score < g.home_team_score) 
            )
            AND
            g.status = 'completed'
            AND
            g.division_id = $1
            THEN 1 ELSE 0 END) as losses,
          SUM(
            CASE WHEN 
            (g.away_team_score = g.home_team_score)
            AND
            g.status = 'completed'
            AND
            g.division_id = $1
            THEN 1 ELSE 0 END) as ties,
          
          SUM	(
            CASE
              WHEN
                g.home_team_id = t.team_id
                AND
                g.status = 'completed'
                AND
                g.division_id = $1
              THEN g.home_team_score
              WHEN
                g.away_team_id = t.team_id
                AND
                g.status = 'completed'
                AND
                g.division_id = $1
              THEN g.away_team_score
            ELSE 0
            END
          ) as goals_for,
          SUM	(
            CASE
              WHEN
                g.home_team_id = t.team_id
                AND
                g.status = 'completed'
                AND
                g.division_id = $1
              THEN g.away_team_score
              WHEN
                g.away_team_id = t.team_id
                AND
                g.status = 'completed'
                AND
                g.division_id = $1
              THEN g.home_team_score
            ELSE 0
            END
          ) as goals_against
        FROM league_management.division_teams dt
        LEFT JOIN league_management.teams t ON dt.team_id = t.team_id
        LEFT JOIN league_management.games g ON (t.team_id = g.away_team_id OR t.team_id = g.home_team_id)
        WHERE dt.division_id = $1
        GROUP BY t.team_id
      )
      ORDER BY points DESC, wins DESC, ties DESC, games_played ASC, goals_for DESC, goals_against ASC;
    `;

    const { rows: data } = await db.query<TeamStandingsData>(divisionTeamsSql, [
      division_id,
    ]);

    return {
      message: "Division teams loaded",
      status: 200,
      data,
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

  // get point leaders
  const { data: pointLeaders } = await getPointLeadersByDivision(
    division_id,
    limit,
  );

  // get goal leaders
  const { data: goalLeaders } = await getGoalLeadersByDivision(
    division_id,
    limit,
  );

  // get assist leaders
  const { data: assistLeaders } = await getAssistLeadersByDivision(
    division_id,
    limit,
  );

  // get shutout leaders
  const { data: shutoutLeaders } = await getShutoutLeadersByDivision(
    division_id,
    limit,
  );

  return {
    message: "Stats loaded!",
    status: 200,
    data: {
      points: pointLeaders || [],
      goals: goalLeaders || [],
      assists: assistLeaders || [],
      shutouts: shutoutLeaders || [],
    },
  };
}

export async function getDivisionsBySeason(
  season_id: number,
  options?: {
    publicOnly?: boolean;
  },
) {
  // check user is logged in
  await verifySession();

  try {
    // build sql select statement
    const divisionSql = `
      SELECT
        division_id,
        name,
        description,
        tier,
        slug,
        gender,
        season_id,
        status,
        join_code
      FROM league_management.divisions
      WHERE
        season_id = $1
        ${options?.publicOnly ? `AND status = 'public'` : ""}
      ORDER BY gender, tier
    `;

    const { rows: divisionRows } = await db.query<DivisionData>(divisionSql, [
      season_id,
    ]);

    return {
      message: "Divisions found.",
      status: 200,
      data: divisionRows,
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

const DivisionToJoinAsTeamSchema = z.object({
  team_id: z.number().min(1),
  join_code: z.string(),
});

type DivisionToJoinAsTeamErrorProps = {
  team_id?: string[];
  join_code?: string[];
};

type DivisionToJoinAsTeamFormState = FormState<
  DivisionToJoinAsTeamErrorProps,
  {
    team_id?: number;
    join_code?: string;
    division?: DivisionData;
    inDivision?: boolean;
  }
>;

export async function getDivisionToJoinAsTeam(
  state: DivisionToJoinAsTeamFormState,
  formData: FormData,
): Promise<DivisionToJoinAsTeamFormState> {
  const submittedData = {
    team_id: parseInt(formData.get("team_id") as string),
    join_code: formData.get("join_code") as string,
  };

  // Validate form fields
  const validatedFields = DivisionToJoinAsTeamSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      errors: validatedFields.error.flatten().fieldErrors,
      data: submittedData,
    };
  }

  // set initial response code status
  let status = 400;

  try {
    // check if can edit team
    const { canEdit } = await canEditTeam(submittedData.team_id);

    if (!canEdit) {
      status = 401;
      throw new Error(
        "Sorry, you do not have manager permissions for this team.",
      );
    }

    // get division data
    const { data: division } = await getDivisionByJoinCode(
      submittedData.join_code,
    );

    if (!division) {
      status = 404;
      throw new Error("Sorry, division not found.");
    }

    // check if team is already in division
    const sql = `
      SELECT
        *
      FROM
        league_management.division_teams
      WHERE
        division_id = $1
        AND
        team_id = $2
    `;

    const { rowCount } = await db.query(sql, [
      division.division_id,
      submittedData.team_id,
    ]);

    return {
      data: {
        division,
        inDivision: rowCount && rowCount > 0 ? true : false,
      },
    };
  } catch (err) {
    if (err instanceof Error) {
      return {
        message: err.message,
        status,
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

/* ---------- UPDATE ---------- */

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
    status: formData.get("status") as LeagueStatus,
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

  // initialize redirect link
  let redirectLink: string | undefined = undefined;

  try {
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

    const { rowCount } = await db.query<{ slug: string }>(updateSql, [
      submittedData.name,
      submittedData.description,
      submittedData.tier,
      submittedData.gender,
      submittedData.join_code,
      submittedData.status,
      submittedData.division_id,
    ]);

    if (rowCount !== 1)
      throw new Error("Sorry, there was a problem updating the division.");

    const { data: divisionUrl } = await getDivisionUrlById(
      submittedData.division_id,
    );

    redirectLink = divisionUrl;
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

export async function publishDivision(state: {
  data: {
    division_id: number;
    season_id: number;
    league_id: number;
  };
  link: string;
}) {
  // Verify user session
  await verifySession();

  let publishSuccessful = false;

  try {
    // set check for whether user has permission to publish
    const { canEdit } = await canEditLeague(state.data.league_id);

    if (!canEdit) {
      // failed both user role check and league role check, shortcut out
      return {
        ...state,
        message: "You do not have permission to publish this division.",
        status: 401,
      };
    }

    // create delete sql statement
    const sql = `
      UPDATE league_management.divisions
      SET
        status = 'public'
      WHERE division_id = $1
    `;

    // query the database
    const { rowCount } = await db.query(sql, [state.data.division_id]);

    if (rowCount !== 1)
      throw new Error("Sorry, there was an issue publishing this division.");

    publishSuccessful = true;
  } catch (err) {
    if (err instanceof Error) {
      return {
        ...state,
        message: err.message,
        status: 400,
      };
    }
    return {
      ...state,
      message: "Something went wrong.",
      status: 500,
    };
  }

  if (publishSuccessful && state.link) redirect(state.link);
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

  try {
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

    const { rows } = await db.query<{ join_code: string }>(sql, [
      submittedData.join_code,
      submittedData.division_id,
    ]);

    if (!rows[0])
      throw new Error("Sorry, there was a problem updating the join code.");

    return {
      message: "Join code updated!",
      status: 200,
      data: {
        ...submittedData,
        join_code: rows[0].join_code,
      },
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

  try {
    const { canEdit } = await canEditLeague(submittedData.league_id);

    if (!canEdit) {
      return {
        message: "You do not have permission to add teams to this division.",
        status: 401,
        data: submittedData,
        link: state?.link,
      };
    }

    // Validate form fields
    const validatedFields = DivisionTeamSchema.safeParse(submittedData);

    // If any form fields are invalid, return early
    if (!validatedFields.success) {
      return {
        errors: validatedFields.error.flatten().fieldErrors,
        data: submittedData,
        link: state?.link,
      };
    }

    const sql = `
    INSERT INTO league_management.division_teams
      (division_id, team_id)
    VALUES
      ($1, $2)
  `;

    const { rowCount } = await db.query(sql, [
      submittedData.division_id,
      submittedData.team_id,
    ]);

    if (rowCount === 0)
      throw new Error("Sorry, there was a problem adding team to division.");
  } catch (err) {
    if (err instanceof Error) {
      return {
        message: err.message,
        status: 400,
        data: submittedData,
        link: state?.link,
      };
    }
    return {
      message: "Something went wrong.",
      status: 500,
      data: submittedData,
      link: state?.link,
    };
  }

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

  let successfullyAdded = false;

  try {
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

    const { rows: joinCodeRows } = await db.query<{ join_code: string }>(
      joinCodeSql,
      [submittedData.division_id],
    );

    if (!joinCodeRows[0])
      throw new Error("Sorry, unable to match join code to division.");

    // check if submitted join code matches division join code
    const joinCodesMatch =
      joinCodeRows[0].join_code === submittedData.join_code;

    // if join_codes do not match, short circuit
    if (!joinCodesMatch)
      throw new Error("Join code does not match the division's join code.");

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

    const { rows: divisionCheckRows } = await db.query<{ count: number }>(
      inDivisionCheckSql,
      [submittedData.team_id, submittedData.division_id],
    );

    // If the count is above zero, the team is already in the division
    if (divisionCheckRows[0].count > 0)
      throw new Error("Team is already a member of this division.");

    // add team to division
    const insertSql = `
      INSERT INTO league_management.division_teams
        (division_id, team_id)
      VALUES
        ($1, $2)
    `;

    const { rowCount } = await db.query(insertSql, [
      submittedData.division_id,
      submittedData.team_id,
    ]);

    if (!rowCount)
      throw new Error("Sorry, there was an issue joining division.");

    successfullyAdded = true;
  } catch (err) {
    if (err instanceof Error) {
      return {
        message: err.message,
        status: 400,
        data: submittedData,
        link: state?.link,
      };
    }
    return {
      message: "Something went wrong.",
      status: 500,
      data: submittedData,
      link: state?.link,
    };
  }

  if (state?.link && successfullyAdded) redirect(state.link);
}

/* ---------- DELETE ---------- */

export async function deleteDivision(state: {
  data: {
    division_id: number;
    league_id: number;
  };
  link: string;
}) {
  // Verify user session
  await verifySession();

  let deleteSuccessful = false;

  try {
    // set check for whether user has permission to delete
    const { canEdit: canDelete } = await canEditLeague(state.data.league_id);

    if (!canDelete) {
      // failed both user role check and league role check, shortcut out
      return {
        message: "You do not have permission to delete this division.",
        status: 401,
        link: state?.link,
        data: state.data,
      };
    }

    // create delete sql statement
    const sql = `
      DELETE FROM league_management.divisions
      WHERE division_id = $1
    `;

    // query the database
    const { rowCount } = await db.query(sql, [state.data.division_id]);

    if (rowCount === 0)
      throw new Error("Sorry, there was an issue deleting this division.");

    deleteSuccessful = true;
  } catch (err) {
    if (err instanceof Error) {
      return {
        message: err.message,
        status: 400,
        link: state?.link,
        data: state.data,
      };
    }
    return {
      message: "Something went wrong.",
      status: 500,
      link: state?.link,
      data: state.data,
    };
  }

  if (deleteSuccessful) redirect(state.link);
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

  try {
    const { canEdit } = await canEditLeague(submittedData.league_id);

    if (!canEdit) {
      return {
        message: "You do not have permission to add teams to this division.",
        status: 401,
        data: submittedData,
        link: state?.link,
      };
    }

    // Validate form fields
    const validatedFields = DivisionTeamSchema.safeParse(submittedData);

    // If any form fields are invalid, return early
    if (!validatedFields.success) {
      return {
        errors: validatedFields.error.flatten().fieldErrors,
        data: submittedData,
        link: state?.link,
      };
    }

    const sql = `
      DELETE FROM league_management.division_teams
      WHERE
        division_id = $1
        AND
        team_id = $2
    `;

    const { rowCount } = await db.query(sql, [
      submittedData.division_id,
      submittedData.team_id,
    ]);

    if (rowCount === 0)
      throw new Error(
        "Sorry, there was a problem removing team from division.",
      );
  } catch (err) {
    if (err instanceof Error) {
      return {
        message: err.message,
        status: 400,
        data: submittedData,
        link: state?.link,
      };
    }
    return {
      message: "Something went wrong.",
      status: 500,
      data: submittedData,
      link: state?.link,
    };
  }

  if (state?.link) redirect(state?.link);
}
