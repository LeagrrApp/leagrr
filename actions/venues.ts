"use server";

import { db } from "@/db/pg";
import { redirect } from "next/navigation";
import { z } from "zod";

/* ---------- CREATE ---------- */

const VenueCreateSchema = z.object({
  venue_name: z
    .string()
    .min(2, { message: "Name must be a least 2 characters long." }),
  venue_description: z
    .string()
    .min(2, { message: "Description must be a least 2 characters long." })
    .optional(),
  venue_address: z
    .string()
    .min(2, { message: "Address must be a least 2 characters long." })
    .optional(),
  arenas: z.array(z.string()).optional(),
  league_id: z.number().min(1),
});

type VenueErrorProps = {
  venue_name?: string[] | undefined;
  venue_description?: string[] | undefined;
  venue_address?: string[] | undefined;
  arenas?: string[] | undefined;
  league_id?: string[] | undefined;
};

type VenueFormState = FormState<
  VenueErrorProps,
  {
    venue_name?: string;
    venue_description?: string;
    venue_address?: string;
    arenas?: string[];
    league_id?: number;
  }
>;

export async function createVenue(
  state: VenueFormState,
  formData: FormData,
): Promise<VenueFormState> {
  const submittedData = {
    venue_name: formData.get("venue_name") as string,
    venue_description: formData.get("venue_description") as string,
    venue_address: formData.get("venue_address") as string,
    arenas: formData.getAll("arenas") as string[],
    league_id: parseInt(formData.get("league_id") as string),
  };

  const validatedFields = VenueCreateSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      data: submittedData,
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  let success = false;

  try {
    // create insert sql statement for venue
    const venueSql = `
      INSERT INTO league_management.venues
        (name, description, address)
      VALUES
        ($1, $2, $3)
      RETURNING
        venue_id
    `;

    // query database
    const { rows: venueRows } = await db.query<{ venue_id: number }>(venueSql, [
      submittedData.venue_name,
      submittedData.venue_description,
      submittedData.venue_address,
    ]);

    if (!venueRows[0])
      throw new Error("Sorry, there was a problem saving the venue.");

    // get returned venue_id from new venue
    const { venue_id } = venueRows[0];

    // loop through provided arenas and add to database
    for (const arena of submittedData.arenas) {
      if (arena) {
        const arenaSql = `
          INSERT INTO league_management.arenas
            (name, venue_id)
          VALUES
            ($1, $2)
        `;

        await db.query<{ arena_id: number }>(arenaSql, [arena, venue_id]);
      }
    }

    // add venue as a league venue
    const leagueVenueSql = `
      INSERT INTO league_management.league_venues
        (venue_id, league_id)
      VALUES
        ($1, $2)
    `;

    // query database to insert league venue
    const { rowCount } = await db.query(leagueVenueSql, [
      venue_id,
      submittedData.league_id,
    ]);

    if (rowCount !== 1) {
      // there was an issue inserting the league venue
      // delete the venue & arenas to avoid bloating database

      const deleteVenueSql = `
        DELETE FROM league_management.venues
        WHERE venue_id = $1;
      `;

      await db.query(deleteVenueSql, [venue_id]);

      throw new Error(
        "Sorry, there was a problem adding venue to list of league venues.",
      );
    }

    success = true;
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

  if (success && state?.link) redirect(state.link);
}

/* ---------- READ ---------- */

export async function getVenuesByLeagueId(league_id: number) {
  try {
    const sql = `
      SELECT
        lv.league_venue_id,
        lv.venue_id,
        v.name AS venue,
        v.address AS address,
        STRING_AGG(a.name, ', ' ORDER BY a.name) AS arenas
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
        lv.league_id = $1
      GROUP BY lv.league_venue_id, lv.venue_id, v.name, v.address
      ORDER BY v.name ASC
    `;

    const { rows } = await db.query<LeagueVenueData>(sql, [league_id]);

    return {
      message: "League venues loaded.",
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

export async function getVenuesByDivisionId(division_id: number) {
  try {
    const sql = `
      SELECT
        v.slug AS venue_slug,
        v.name AS venue,
        a.name AS arena,
        CONCAT(a.name, ' - ', v.name) AS location,
        a.arena_id AS arena_id
      FROM
        league_management.arenas AS a
      LEFT JOIN
        league_management.venues AS v
      ON
        a.venue_id = v.venue_id
      LEFT JOIN
        league_management.league_venues AS lv
      ON
        v.venue_id = lv.venue_id
      LEFT JOIN
        league_management.leagues AS l
      ON
        lv.league_id = l.league_id
      LEFT JOIN
        league_management.seasons AS s
      ON
        l.league_id = s.league_id
      LEFT JOIN
        league_management.divisions AS d
      ON
        s.season_id = d.season_id
      WHERE
        d.division_id = $1
        ORDER BY v.name ASC, a.name ASC
    `;

    const { rows } = await db.query<LocationData>(sql, [division_id]);

    return {
      message: "Venues loaded",
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

/* ---------- DELETE ---------- */

const RemoveLeagueVenueSchema = z.object({
  league_venue_id: z.number().min(1),
});

type RemoveLeagueVenueErrorProps = {
  league_venue_id?: string[] | undefined;
};

type RemoveLeagueVenueFormState = FormState<
  RemoveLeagueVenueErrorProps,
  {
    league_venue_id?: number;
  }
>;

export async function removeLeagueVenue(
  state: RemoveLeagueVenueFormState,
  formData: FormData,
): Promise<RemoveLeagueVenueFormState> {
  console.log("getting things started");

  const submittedData = {
    league_venue_id: parseInt(formData.get("league_venue_id") as string),
  };

  const validatedFields = RemoveLeagueVenueSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      data: submittedData,
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  let success = false;

  try {
    // create delete sql statement for venue
    const venueSql = `
      DELETE FROM league_management.league_venues
      WHERE league_venue_id = $1
    `;

    // query database
    const { rowCount } = await db.query<{ venue_id: number }>(venueSql, [
      submittedData.league_venue_id,
    ]);

    if (rowCount !== 1)
      throw new Error("Sorry, there was an error removing league venue.");

    success = true;
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

  if (success && state?.link) redirect(state.link);
}
