"use server";

import { db } from "@/db/pg";

export async function getPointLeadersByDivision(
  division_id: number,
  limit = 10,
) {
  try {
    const sql = `
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

    const { rows } = await db.query<StatLeaderBoardItem>(sql, [
      division_id,
      limit || 10,
    ]);

    return {
      message: "Point leaders retrieved",
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

export async function getGoalLeadersByDivision(
  division_id: number,
  limit = 10,
) {
  try {
    const sql = `
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

    const { rows } = await db.query<StatLeaderBoardItem>(sql, [
      division_id,
      limit || 10,
    ]);

    return {
      message: "Goal leaders retrieved",
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

export async function getAssistLeadersByDivision(
  division_id: number,
  limit = 10,
) {
  try {
    const sql = `
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

    const { rows } = await db.query<StatLeaderBoardItem>(sql, [
      division_id,
      limit || 10,
    ]);

    return {
      message: "Assist leaders retrieved",
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

export async function getShutoutLeadersByDivision(
  division_id: number,
  limit = 10,
) {
  try {
    const sql = `
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

    const { rows } = await db.query<StatLeaderBoardItem>(sql, [
      division_id,
      limit || 10,
    ]);

    return {
      message: "Shutout leaders retrieved",
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
