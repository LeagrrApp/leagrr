"use server";

import { db } from "@/db/pg";
import { verifySession } from "@/lib/session";
import {
  createDashboardUrl,
  createMetaTitle,
} from "@/utils/helpers/formatting";
import { isObjectEmpty } from "@/utils/helpers/objects";
import { redirect } from "next/navigation";
import { z } from "zod";
import { getDivisionsBySeason } from "./divisions";
import { canEditLeague } from "./leagues";

const SeasonFormSchema = z.object({
  name: z
    .string()
    .min(2, { message: "Name must be at least 2 characters long." })
    .trim(),
  description: z.string().trim().optional(),
  league_id: z.number(),
  start_date: z.string().date(),
  end_date: z.string().date(),
  status: z.enum(["draft", "public", "archived"]).optional(),
});

interface SeasonErrorProps {
  name?: string[] | undefined;
  description?: string[] | undefined;
  league_id?: string[] | undefined;
  start_date?: string[] | undefined;
  end_date?: string[] | undefined;
  status?: string[] | undefined;
}

type SeasonFormState = FormState<
  SeasonErrorProps,
  {
    name: string;
    description: string;
    league_id: number;
    start_date: Date | string;
    end_date: Date | string;
    season_id?: number;
    status?: string;
  }
>;

export async function createSeason(
  state: SeasonFormState,
  formData: FormData,
): Promise<SeasonFormState> {
  // Verify user session
  await verifySession();

  // insert data from form into object to check for errors
  const submittedData = {
    name: formData.get("name") as string,
    description: formData.get("description") as string,
    league_id: parseInt(formData.get("league_id") as string),
    start_date: formData.get("start_date") as string,
    end_date: formData.get("end_date") as string,
  };

  let errors: SeasonErrorProps = {};

  // Validate form fields
  const validatedFields = SeasonFormSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    errors = validatedFields.error.flatten().fieldErrors;
  }

  // check if end_date is after start_date
  const start_date_as_date = new Date(submittedData.start_date as string);
  const end_date_as_date = new Date(submittedData.end_date as string);

  if (start_date_as_date > end_date_as_date) {
    if (errors.end_date) {
      errors.end_date.push("End date must be after start date!");
    } else {
      errors.end_date = ["End date must be after start date!"];
    }
  }

  // if there are any validation errors, return errors
  if (!isObjectEmpty(errors)) return { errors, data: submittedData };

  // Check to see if the user is allowed to create a season for this league
  const { canEdit } = await canEditLeague(submittedData.league_id);

  if (!canEdit) {
    return {
      message: "You do not have permission to create a season for this league",
      status: 400,
      data: submittedData,
    };
  }

  // initialize redirect link
  let redirectLink: string | undefined = undefined;

  try {
    // build insert sql for season
    const sql = `
      INSERT INTO league_management.seasons AS s (name, description, league_id, start_date, end_date)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING
        slug,
        (SELECT slug FROM leagues as l WHERE l.league_id = s.league_id) AS league_slug
    `;

    // query database
    const { rows } = await db.query<SeasonData>(sql, [
      submittedData.name,
      submittedData.description,
      submittedData.league_id,
      submittedData.start_date,
      submittedData.end_date,
    ]);

    if (!rows[0])
      throw new Error("Sorry, there was an error creating the season.");

    // set redirect link
    redirectLink = createDashboardUrl({
      l: rows[0].league_slug,
      s: rows[0].slug,
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

  // Redirect to the new season page
  if (redirectLink) redirect(redirectLink);
}

export async function getSeason(
  season_slug: string,
  league_slug: string,
  options?: { includeDivisions?: boolean },
): Promise<ResultProps<SeasonData>> {
  // Verify user session
  await verifySession();

  try {
    // build the select statement to get the season information
    const seasonSql = `
      SELECT
        s.name,
        s.description,
        s.start_date,
        s.end_date,
        s.status,
        s.season_id,
        l.league_id,
        l.slug AS league_slug,
        l.name AS league
      FROM
        league_management.seasons AS s
      JOIN
        league_management.leagues AS l
      ON
        s.league_id = l.league_id
      WHERE
        s.slug = $1
        AND
        l.slug = $2
    `;

    const { rows: seasonRows } = await db.query<SeasonData>(seasonSql, [
      season_slug,
      league_slug,
    ]);

    // if the league was not found, return error
    if (!seasonRows[0]) throw new Error("Team not found!");

    const season = seasonRows[0];

    if (options?.includeDivisions) {
      const { data: divisions } = await getDivisionsBySeason(season.season_id);

      if (divisions && divisions.length > 0) {
        season.divisions = divisions;
      }
    }

    return {
      message: "Season data loaded!",
      status: 200,
      data: season,
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

export async function getSeasonMetaData(
  season: string,
  league: string,
  options?: {
    prefix?: string;
  },
) {
  try {
    const sql = `
      SELECT
        s.name AS season,
        s.description,
        l.name AS league
      FROM
        league_management.seasons AS s
      JOIN
        league_management.leagues AS l
      ON
        s.league_id = l.league_id
      WHERE
        s.slug = $1
        AND
        l.slug = $2
    `;

    const { rows } = await db.query<{
      season: string;
      description: string;
      league: string;
    }>(sql, [season, league]);

    let title = createMetaTitle([rows[0].season, rows[0].league]);

    if (options?.prefix)
      title = createMetaTitle([options.prefix, rows[0].season, rows[0].league]);

    return {
      message: "Season meta data loaded.",
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
      message: "Something went wrong",
      status: 500,
    };
  }
}

export async function getSeasonsByLeague(
  league: string | number,
): Promise<ResultProps<SeasonData[]>> {
  try {
    // build select statement to get all seasons for associated league
    const seasonsSql = `
      SELECT
        s.slug,
        s.name,
        s.status,
        s.start_date,
        s.end_date
      FROM
        league_management.seasons AS s
      JOIN
        league_management.leagues AS l
      ON
        s.league_id = l.league_id
      WHERE
        ${typeof league === "string" ? `l.slug` : `l.league_id`} = $1
      ORDER BY s.end_date DESC
    `;

    // make request to database for seasons
    const { rows } = await db.query<SeasonData>(seasonsSql, [league]);

    return {
      message: "Seasons retrieved",
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
      message: "Something went wrong",
      status: 500,
    };
  }
}

export async function editSeason(
  state: SeasonFormState,
  formData: FormData,
): Promise<SeasonFormState> {
  // Verify user session
  await verifySession();

  // insert data from form into object to check for errors
  const submittedData = {
    name: formData.get("name") as string,
    description: formData.get("description") as string,
    league_id: parseInt(formData.get("league_id") as string),
    season_id: parseInt(formData.get("season_id") as string),
    start_date: formData.get("start_date") as string,
    end_date: formData.get("end_date") as string,
    status: formData.get("status") as string,
  };

  let errors: SeasonErrorProps = {};

  // Validate form fields
  const validatedFields = SeasonFormSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    errors = validatedFields.error.flatten().fieldErrors;
  }

  // check if end_date is after start_date
  const start_date_as_date = new Date(submittedData.start_date as string);
  const end_date_as_date = new Date(submittedData.end_date as string);

  if (start_date_as_date > end_date_as_date) {
    if (errors.end_date) {
      errors.end_date.push("End date must be after start date!");
    } else {
      errors.end_date = ["End date must be after start date!"];
    }
  }

  // if there are any validation errors, return errors
  if (!isObjectEmpty(errors)) return { errors, data: submittedData };

  // Check to see if the user is allowed to edit a season for this league
  const { canEdit } = await canEditLeague(submittedData.league_id);

  if (!canEdit) {
    return {
      message: "You do not have permission to edit this season.",
      status: 401,
      data: submittedData,
    };
  }

  // Initialize redirect link
  let redirectLink: string | undefined = undefined;

  try {
    // build insert sql for season
    const updateSql = `
      UPDATE
        league_management.seasons AS s
      SET
        name = $1,
        description = $2,
        start_date = $3,
        end_date = $4,
        status = $5
      WHERE
        season_id = $6
      RETURNING
        slug,
        (SELECT slug FROM leagues as l WHERE l.league_id = s.league_id) AS league_slug
    `;

    // query database
    const { rows } = await db.query<SeasonData>(updateSql, [
      submittedData.name,
      submittedData.description,
      submittedData.start_date,
      submittedData.end_date,
      submittedData.status,
      submittedData.season_id,
    ]);

    if (!rows[0]) throw new Error("There was a problem editing the season.");

    // set redirect link
    redirectLink = createDashboardUrl({
      l: rows[0].league_slug,
      s: rows[0].slug,
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
      message: "Something went wrong",
      status: 500,
      data: submittedData,
    };
  }

  // Redirect to the season page
  if (redirectLink) redirect(redirectLink);
}

export async function deleteSeason(state: {
  data: {
    season_id: number;
    league_id: number;
    backLink: string;
  };
}) {
  // Verify user session
  await verifySession();

  try {
    if (!state.data) throw new Error("Sorry, unable to delete season.");

    // set check for whether user has permission to delete
    const { canEdit: canDelete } = await canEditLeague(state.data.league_id);

    if (!canDelete) {
      // failed both user role check and league role check, shortcut out
      return {
        message: "You do not have permission to delete this season.",
        status: 401,
        data: state.data,
      };
    }
    // create delete sql statement
    const sql = `
      DELETE FROM league_management.seasons
      WHERE season_id = $1
    `;

    // query the database
    const { rowCount } = await db.query(sql, [state.data.season_id]);

    if (rowCount !== 1)
      throw new Error("There was a problem deleting the season.");
  } catch (err) {
    if (err instanceof Error) {
      return {
        message: err.message,
        status: 400,
        data: state.data,
      };
    }
    return {
      message: "Something went wrong",
      status: 500,
      data: state.data,
    };
  }

  redirect(state.data.backLink);
}
