"use server";

import { db } from "@/db/pg";

interface MenuItemData {
  slug: string;
  name: string;
  img?: string;
}

export async function getUserDashboardMenuData(
  user_id?: number
): Promise<UserDashboardMenuData> {
  if (!user_id)
    return {
      message: "Please provide a username",
      status: 400,
    };

  // get list of teams that the user is a part of
  const teamSql = `
    SELECT
      t.slug,
      t.name
    FROM
      league_management.teams AS t
    JOIN
      league_management.team_memberships as m
    ON
      m.team_id = t.team_id
    WHERE
      m.user_id = $1
    ORDER BY
      t.name ASC;
  `;

  const teamsResult: {
    message: string;
    status: number;
    data?: MenuItemData[];
  } = await db
    .query(teamSql, [user_id])
    .then((res) => {
      return {
        message: "User team data retrieved.",
        data: res.rows,
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  if (!teamsResult.data) {
    return {
      message: teamsResult.message,
      status: teamsResult.status,
    };
  }

  // get list of user run leagues
  const leagueSql = `
    SELECT
      l.name,
      l.slug,
      a.user_id
    FROM
      league_management.league_admins as a
    JOIN
      league_management.leagues as l
    ON
      l.league_id = a.league_id
    WHERE
      a.user_id = $1;
  `;

  const leaguesResult: {
    message: string;
    status: number;
    data?: MenuItemData[];
  } = await db
    .query(leagueSql, [user_id])
    .then((res) => {
      return {
        message: "User league data retrieved.",
        data: res.rows,
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  if (!leaguesResult.data) {
    return {
      message: leaguesResult.message,
      status: leaguesResult.status,
    };
  }

  return {
    message: "Dashboard data retrieved",
    status: 200,
    data: {
      teams: teamsResult.data,
      leagues: leaguesResult.data,
    },
  };
}

export async function getUserData(
  identifier: string,
  user_role: number = 3,
  currentUser: boolean = false
): Promise<UserSelectResultProps> {
  const sql = `
    SELECT
      u.user_id,
      u.username,
      u.email,
      u.first_name,
      u.last_name,
      u.user_role,
      (
        SELECT
          name
        FROM
          admin.user_roles AS r
        WHERE
          r.user_role_id = u.user_role
      ) AS role,
      (
        SELECT
          name
        FROM
          admin.genders AS g
        WHERE
          g.gender_id = u.gender_id
      ) AS gender
    FROM
      admin.users AS u
    WHERE
      u.username = $1
  `;

  const result: { message: string; status: number; data?: UserData } = await db
    .query(sql, [identifier])
    .then((res) => {
      if (!res.rowCount) {
        throw new Error("Could not find requested user.");
      }
      return {
        message: "User data retrieved.",
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

  console.log(result);

  return result;
}
