"use server";

import { db } from "@/db/pg";

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
