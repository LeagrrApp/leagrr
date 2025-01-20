"use server";

import { db } from "@/db/pg";
import {
  SeasonErrorProps,
  SeasonFormSchema,
  SeasonFormState,
} from "@/lib/definitions";
import { verifySession } from "@/lib/session";
import { isObjectEmpty } from "@/utils/helpers/objects";
import { redirect } from "next/navigation";
import { canEditLeague, verifyLeagueAdminRole } from "./leagues";

export async function createSeason(
  state: SeasonFormState,
  formData: FormData
): Promise<SeasonFormState> {
  // Verify user session
  const { user_id } = await verifySession();

  // insert data from form into object to check for errors
  const seasonData = {
    name: formData.get("name"),
    description: formData.get("description"),
    league_id: parseInt(formData.get("league_id") as string),
    start_date: formData.get("start_date"),
    end_date: formData.get("end_date"),
  };

  let errors: SeasonErrorProps = {};

  // Validate form fields
  const validatedFields = SeasonFormSchema.safeParse(seasonData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    errors = validatedFields.error.flatten().fieldErrors;
  }

  // check if end_date is after start_date
  const start_date_as_date = new Date(seasonData.start_date as string);
  const end_date_as_date = new Date(seasonData.end_date as string);

  if (start_date_as_date > end_date_as_date) {
    if (errors.end_date) {
      errors.end_date.push("End date must be after start date!");
    } else {
      errors.end_date = ["End date must be after start date!"];
    }
  }

  // if there are any validation errors, return errors
  if (!isObjectEmpty(errors)) return { errors };

  // TODO: add check to see if the user is allowed to create a season for this league

  // build insert sql for season
  const sql = `
    INSERT INTO league_management.seasons AS s (name, description, league_id, start_date, end_date)
    VALUES ($1, $2, $3, $4, $5)
    RETURNING
      slug,
      (SELECT slug FROM leagues as l WHERE l.league_id = s.league_id) AS league_slug
  `;

  // query database
  const seasonInsertResult: ResultProps<SeasonData> = await db
    .query(sql, [
      seasonData.name,
      seasonData.description,
      seasonData.league_id,
      seasonData.start_date,
      seasonData.end_date,
    ])
    .then((res) => {
      return {
        message: "Season created!",
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

  if (seasonInsertResult?.data)
    redirect(
      `/dashboard/l/${seasonInsertResult?.data.league_slug}/s/${seasonInsertResult?.data.slug}`
    );

  return seasonInsertResult;
}

export async function getSeason(
  season_slug: string,
  league_slug: string,
  includeDivisions?: boolean
): Promise<ResultProps<SeasonData>> {
  // Verify user session
  await verifySession();

  // build the select statement to get the season information
  const seasonSql = `
    SELECT
      name,
      description,
      start_date,
      end_date,
      status,
      season_id,
      league_id
    FROM
      league_management.seasons AS s
    WHERE
      s.slug = $1
      AND
      (SELECT league_id FROM league_management.leagues AS l WHERE l.slug = $2) = s.league_id
  `;

  const seasonResult: ResultProps<SeasonData> = await db
    .query(seasonSql, [season_slug, league_slug])
    .then((res) => {
      if (!res.rowCount) {
        throw new Error("Season not found!");
      }

      return {
        message: "Season data retrieved!",
        status: 200,
        data: res.rows[0],
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 404,
      };
    });

  // if the league was not found, return error
  if (!seasonResult.data) return seasonResult;

  let response: ResultProps<SeasonData> = {
    ...seasonResult,
  };

  if (includeDivisions) {
    const divisionSql = `
      SELECT
        name,
        description,
        tier,
        slug,
        gender,
        season_id,
        status,
        join_code
      FROM league_management.divisions WHERE season_id = $1
      ORDER BY gender, tier
    `;

    const divisionResult: ResultProps<DivisionData[]> = await db
      .query(divisionSql, [seasonResult.data.season_id])
      .then((res) => {
        return {
          message: "Division data retrieved!",
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

    if (divisionResult.data) {
      response.data = {
        ...(response.data as SeasonData),
        divisions: divisionResult.data,
      };
    }
  }

  return response;
}

export async function editSeason(
  state: SeasonFormState,
  formData: FormData
): Promise<SeasonFormState> {
  // Verify user session
  await verifySession();

  // insert data from form into object to check for errors
  const seasonData = {
    name: formData.get("name"),
    description: formData.get("description"),
    league_id: parseInt(formData.get("league_id") as string),
    season_id: parseInt(formData.get("season_id") as string),
    start_date: formData.get("start_date"),
    end_date: formData.get("end_date"),
    status: formData.get("status"),
  };

  let errors: SeasonErrorProps = {};

  // Validate form fields
  const validatedFields = SeasonFormSchema.safeParse(seasonData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    errors = validatedFields.error.flatten().fieldErrors;
  }

  // check if end_date is after start_date
  const start_date_as_date = new Date(seasonData.start_date as string);
  const end_date_as_date = new Date(seasonData.end_date as string);

  if (start_date_as_date > end_date_as_date) {
    if (errors.end_date) {
      errors.end_date.push("End date must be after start date!");
    } else {
      errors.end_date = ["End date must be after start date!"];
    }
  }

  // if there are any validation errors, return errors
  if (!isObjectEmpty(errors)) return { errors };

  // Check to see if the user is allowed to edit a season for this league

  // check for site wide admin privileges
  const { canEdit } = await canEditLeague(seasonData.league_id);

  if (!canEdit) {
    return {
      message: "You do not have permission to edit this season.",
      status: 401,
    };
  }

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
  const seasonUpdateResult: ResultProps<SeasonData> = await db
    .query(updateSql, [
      seasonData.name,
      seasonData.description,
      seasonData.start_date,
      seasonData.end_date,
      seasonData.status,
      seasonData.season_id,
    ])
    .then((res) => {
      return {
        message: "Season updated!",
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

  if (seasonUpdateResult?.data)
    redirect(
      `/dashboard/l/${seasonUpdateResult?.data.league_slug}/s/${seasonUpdateResult?.data.slug}`
    );

  return seasonUpdateResult;
}

export async function deleteSeason(state: {
  season_id: number;
  league_id: number;
  backLink: string;
}) {
  // Verify user session
  await verifySession();

  // set check for whether user has permission to delete
  const { canEdit: canDelete } = await canEditLeague(state.league_id, true);

  if (!canDelete) {
    // failed both user role check and league role check, shortcut out
    return {
      message: "You do not have permission to delete this season.",
      status: 401,
    };
  }

  // create delete sql statement
  const sql = `
    DELETE FROM league_management.seasons
    WHERE season_id = $1
  `;

  // query the database
  const deleteResult = db
    .query(sql, [state.season_id])
    .then((res) => {
      return {
        message: "Season deleted",
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
