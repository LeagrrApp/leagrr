"use server";
import { db } from "@/db/pg";
import { team_roles } from "@/lib/definitions";
import { verifySession } from "@/lib/session";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { check_string_is_color_hex } from "@/utils/helpers/validators";
import { redirect } from "next/navigation";
import { z } from "zod";
import { getDivisionStandings } from "./divisions";
import { verifyUserRole } from "./users";
import slugify from "slugify";

const CreateTeamSchema = z.object({
  user_id: z.number().min(1),
  name: z
    .string()
    .min(2, { message: "Name must be at least 2 characters long." })
    .trim(),
  description: z.string().trim().optional(),
  color: z.string().optional(),
  custom_color: z.string().refine(check_string_is_color_hex, {
    message: "Invalid color format.",
  }),
});

type TeamErrorProps = {
  team_id?: string[] | undefined;
  user_id?: string[] | undefined;
  name?: string[] | undefined;
  description?: string[] | undefined;
  color?: string[] | undefined;
  custom_color?: string[] | undefined;
  join_code?: string[] | undefined;
};

type TeamFormState =
  | {
      errors?: TeamErrorProps;
      message?: string;
      status?: number;
      data?: Partial<TeamData>;
    }
  | undefined;

export async function createTeam(
  state: TeamFormState,
  formData: FormData,
): Promise<TeamFormState> {
  // Confirmed logged in
  await verifySession();

  // get data from form
  const teamData = {
    user_id: parseInt(formData.get("user_id") as string),
    name: formData.get("name") as string,
    description: formData.get("description") as string,
    color: formData.get("color") as string,
    custom_color: (formData.get("custom_color") as string) || "#000",
  };

  const validatedFields = CreateTeamSchema.safeParse(teamData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      data: teamData,
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  // create insert statement
  const teamInsertSql = `
    INSERT INTO league_management.teams
      (name, description, color)
    VALUES
      ($1, $2, $3)
    RETURNING
      slug, team_id
  `;

  // Value clean up to insure they are null in database not empty strings
  let color: string | null =
    teamData.color !== "custom" ? teamData.color : teamData.custom_color;
  if (color === "") color = null;

  // query database
  const teamInsertResult: ResultProps<{ slug: string; team_id: number }> =
    await db
      .query(teamInsertSql, [teamData.name, teamData.description, color])
      .then((res) => {
        return {
          message: `${teamData.name} successfully created!`,
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

  if (!teamInsertResult.data) {
    return teamInsertResult;
  }
  // add user to team as manager (1)
  const teamMembershipSql = `
    INSERT INTO league_management.team_memberships
      (user_id, team_id, team_role)
    VALUES
      ($1, $2, 1)
  `;

  const teamMembershipInsertResult = await db
    .query(teamMembershipSql, [teamData.user_id, teamInsertResult.data.team_id])
    .then((res) => {
      if (res.rowCount === 0) {
        throw new Error("Unable to add user as team manager.");
      }

      return {
        message: `Team member added!`,
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  // Failed to add user as team admin, delete the team and return error
  if (teamMembershipInsertResult.status === 400) {
    // TODO: delete the league on this error

    const deleteSql = `
      DELETE FROM league_management.teams
      WHERE team_id = $1
    `;

    await db.query(deleteSql, [teamInsertResult.data.team_id]);

    return teamMembershipInsertResult;

    // return {
    //   message: "There was an error creating team. Try again.",
    //   status: 400,
    // };
  }

  // Success route, redirect to the new league page
  redirect(createDashboardUrl({ t: teamInsertResult.data.slug }));
}

export async function getTeamRole(team: string | number) {
  // verify logged in and get user_id
  const { user_id } = await verifySession();

  const sql = `
    SELECT 
      team_role,
      t.team_id
    FROM
      league_management.team_memberships AS tm
    JOIN
      league_management.teams AS T
    ON
      t.team_id = tm.team_id
    WHERE
      tm.user_id = $1
      AND
      ${typeof team === "string" ? "t.slug" : "t.team_id"} = $2
  `;

  const result: ResultProps<{ team_role: number }> = await db
    .query(sql, [user_id, team])
    .then((res) => {
      if (res.rowCount === 0) {
        return {
          message: "User does not have a role on this team.",
          status: 401,
        };
      }
      return {
        message: "User role found!",
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

  return result?.data?.team_role;
}

export async function verifyTeamRoleLevel(
  team: string | number,
  roleLevel: number,
) {
  const teamRole = await getTeamRole(team);

  if (!teamRole) return false;

  return teamRole <= roleLevel;
}

export async function canEditTeam(team: string | number): Promise<{
  canEdit: boolean;
  role: RoleData | undefined;
}> {
  // check if they are a site wide admin
  const isAdmin = await verifyUserRole(1);

  // set the role data if site wide admin
  let role: RoleData | undefined = isAdmin
    ? {
        role: 1,
        title: "Site Admin",
      }
    : undefined;

  // set initial canEdit to whether or not user is site wide admin
  let canEdit = isAdmin;

  // skip additional database query if we already know user has permission
  if (!canEdit) {
    // check for league admin privileges
    const teamRole = await getTeamRole(team);

    // verify which role the user has
    if (teamRole) {
      // set canEdit based on whether it is a commissionerOnly check or not
      canEdit = teamRole === 1;
      // set name of role
      role = team_roles.get(teamRole);
    }
  }

  return {
    canEdit,
    role,
  };
}

export async function getTeam(
  slug: string,
): Promise<ResultProps<TeamPageData>> {
  // verify logged in
  await verifySession();

  const teamSql = `
    SELECT
      team_id,
      slug,
      name,
      description,
      status,
      color,
      join_code
    FROM
      league_management.teams
    WHERE slug = $1
  `;

  const teamResult = await db
    .query(teamSql, [slug])
    .then((res) => {
      if (res.rowCount === 0) {
        throw new Error("Team not found!");
      }

      return {
        message: `Team data found!`,
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

  return teamResult;
}

export async function getDivisionTeamId(team_id: number, division_id: number) {
  // confirm logged in
  await verifySession();

  const sql = `
    SELECT
      division_team_id
    FROM
      league_management.division_teams AS dt
    WHERE
      team_id = $1 AND division_id = $2
  `;

  const result: ResultProps<number> = await db
    .query(sql, [team_id, division_id])
    .then((res) => {
      return {
        message: "Team list found",
        status: 200,
        data: res.rows[0].division_team_id,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  return result;
}

export async function getAllTeamMembers(team_id: number) {
  // confirm logged in
  await verifySession();

  const sql = `
    SELECT
      u.user_id,
      u.first_name,
      u.last_name,
      u.username,
      u.email,
      u.pronouns,
      u.gender,
      tm.team_membership_id,
      tm.created_on AS joined,
      tm.team_role
    FROM
      league_management.team_memberships AS tm
    JOIN
      admin.users AS u
    ON
      tm.user_id = u.user_id
    WHERE
      tm.team_id = $1
    ORDER BY
      u.last_name, u.first_name
  `;

  const result: ResultProps<TeamUserData[]> = await db
    .query(sql, [team_id])
    .then((res) => {
      return {
        message: "Team list found",
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

  return result;
}

export async function getTeamDivisionRoster(
  team_id: number,
  division_id: number,
) {
  // confirm logged in
  await verifySession();

  const sql = `
    SELECT
      u.user_id,
      u.first_name,
      u.last_name,
      u.username,
      u.email,
      u.pronouns,
      u.gender,
      dr.number,
      dr.position,
      dr.roster_role,
      tm.team_membership_id,
      dt.division_team_id,
      dr.division_roster_id
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
      dt.team_id = $1 AND dt.division_id = $2
    ORDER BY
      tm.team_id, u.last_name, u.first_name
  `;

  const result: ResultProps<TeamUserData[]> = await db
    .query(sql, [team_id, division_id])
    .then((res) => {
      return {
        message: "Division roster found",
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

  return result;
}

export async function getDivisionsByTeam(
  team_id: number,
): Promise<ResultProps<TeamDivisionsProps[]>> {
  // verify signed in
  await verifySession();

  const sql = `
    SELECT
      d.name AS division,
      d.division_id AS division_id,
      d.slug AS division_slug,
      s.name AS season,
      s.slug AS season_slug,
      s.start_date AS start_date,
      s.end_date AS end_date,
      l.name AS league,
      l.slug AS league_slug
    FROM
      league_management.division_teams AS dt
    JOIN
      league_management.divisions AS d
    ON
      dt.division_id = d.division_id
    JOIN
      league_management.seasons AS s
    ON
      s.season_id = d.season_id
    JOIN
      league_management.leagues AS l
    ON
      s.league_id = l.league_id
    WHERE
      dt.team_id = $1
      AND
      d.status = 'public'
      AND
      s.status = 'public'
      AND
      l.status = 'public'
  `;

  const result = await db
    .query(sql, [team_id])
    .then((res) => {
      return {
        message: `Divisions found!`,
        status: 200,
        data: res.rows,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
        data: [],
      };
    });

  return result;
}

export async function getTeamGamePreviews(
  team_id: number,
  division_id: number,
  pastGames = false,
  limit = 1,
) {
  const sql = `
    SELECT
      division_id,
      game_id,
      home_team_id,
      (SELECT name FROM league_management.teams WHERE team_id = g.home_team_id) AS home_team,
      (SELECT slug FROM league_management.teams WHERE team_id = g.home_team_id) AS home_team_slug,
      (SELECT color FROM league_management.teams WHERE team_id = g.home_team_id) AS home_team_color,
      (SELECT COUNT(*) FROM stats.shots AS sh WHERE sh.team_id = g.home_team_id AND sh.game_id = g.game_id)::int AS home_team_shots,
      home_team_score,
      away_team_id,
      (SELECT name FROM league_management.teams WHERE team_id = g.away_team_id) AS away_team,
      (SELECT slug FROM league_management.teams WHERE team_id = g.away_team_id) AS away_team_slug,
      (SELECT color FROM league_management.teams WHERE team_id = g.away_team_id) AS away_team_color,
      (SELECT COUNT(*) FROM stats.shots AS sh WHERE sh.team_id = g.away_team_id AND sh.game_id = g.game_id)::int AS away_team_shots,
      away_team_score,
      date_time,
      arena_id,
      (SELECT name FROM league_management.arenas WHERE arena_id = g.arena_id) AS arena,
      (SELECT name FROM league_management.venues WHERE venue_id = (
        SELECT venue_id FROM league_management.arenas WHERE arena_id = g.arena_id
      )) AS venue,
      status
    FROM
      league_management.games AS g
    WHERE
      status = ${pastGames ? "'completed'" : "'public'"}
      AND
      (
        home_team_id = $1
        OR
        away_team_id = $1
      )
      AND
      date_time ${pastGames ? "<" : ">"} now()
      AND
      division_id = $2
    ORDER BY
      date_time ${pastGames ? "DESC" : "ASC"}
    LIMIT $3
  `;

  const result = await db
    .query(sql, [team_id, division_id, limit])
    .then((res) => {
      return {
        message: `Games found!`,
        status: 200,
        data: res.rows,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
        data: [],
      };
    });

  // TODO: add better error handling
  return result;
}

export async function getTeamDivisionRosterStats(
  team_id: number,
  division_id: number,
) {
  // confirm logged in
  await verifySession();

  // new version, references team members of the specific division's roster, not all team members
  const sql = `
    SELECT 
      tm.team_id,
      u.user_id,
      u.first_name,
      u.last_name,
      u.username,
      u.pronouns,
      u.email,
      dr.position,
      dr.number,
      tm.team_role,
      (SELECT COUNT(*) FROM stats.goals AS g WHERE g.user_id = tm.user_id AND g.game_id IN (
        SELECT game_id FROM league_management.games WHERE (home_team_id = $1 OR away_team_id = $1) AND division_id = $2
      ))::int AS goals,
      (SELECT COUNT(*) FROM stats.assists AS a WHERE a.user_id = tm.user_id AND a.game_id IN (
        SELECT game_id FROM league_management.games WHERE (home_team_id = $1 OR away_team_id = $1) AND division_id = $2
      ))::int AS assists,
      (
        (SELECT COUNT(*) FROM stats.goals AS g WHERE g.user_id = tm.user_id AND g.game_id IN (
        SELECT game_id FROM league_management.games WHERE (home_team_id = $1 OR away_team_id = $1) AND division_id = $2
      )) +
        (SELECT COUNT(*) FROM stats.assists AS a WHERE a.user_id = tm.user_id AND a.game_id IN (
        SELECT game_id FROM league_management.games WHERE (home_team_id = $1 OR away_team_id = $1) AND division_id = $2
      ))	
      )::int AS points,
      (SELECT COUNT(*) FROM stats.shots AS s WHERE s.user_id = tm.user_id AND s.game_id IN (
        SELECT game_id FROM league_management.games WHERE (home_team_id = $1 OR away_team_id = $1) AND division_id = $2
      ))::int AS shots,
      (SELECT COALESCE(SUM(minutes), 0) FROM stats.penalties AS p WHERE p.user_id = tm.user_id AND p.game_id IN (
      SELECT game_id FROM league_management.games WHERE (home_team_id = $1 OR away_team_id = $1) AND division_id = $2
      ))::int AS penalties_in_minutes,
      (SELECT COUNT(*) FROM stats.saves AS sa WHERE sa.user_id = tm.user_id AND sa.game_id IN (
        SELECT game_id FROM league_management.games WHERE (home_team_id = $1 OR away_team_id = $1) AND division_id = $2
      ))::int AS saves,
      (SELECT COUNT(*) FROM stats.goals AS goal WHERE goal.team_id != 2 AND goal.game_id IN (
        SELECT game_id FROM league_management.games WHERE (home_team_id = $1 OR away_team_id = $1) AND division_id = $2
      ))::int AS goals_against,
      (SELECT COUNT(*) FROM stats.shots AS sh WHERE sh.team_id != 2 AND sh.game_id IN (
        SELECT game_id FROM league_management.games WHERE (home_team_id = $1 OR away_team_id = $1) AND division_id = $2
      ))::int AS shots_against
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
      dt.team_id = $1
      AND
      dt.division_id = $2
      AND
      dr.roster_role IN (2, 3, 4)
    ORDER BY points DESC, goals DESC, assists DESC, shots DESC, last_name ASC, first_name ASC
  `;

  const result = await db
    .query(sql, [team_id, division_id])
    .then((res) => {
      return {
        message: `Games found!`,
        status: 200,
        data: res.rows,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
        data: [],
      };
    });

  // TODO: add better error handling
  return result;
}

export async function getTeamDashboardData(
  team_id: number,
  division_id: number,
) {
  // confirm logged in
  await verifySession();

  // get next game
  const { data: nextGames } = await getTeamGamePreviews(team_id, division_id);

  // get previous game
  const { data: prevGames } = await getTeamGamePreviews(
    team_id,
    division_id,
    true,
  );

  // get team members
  const { data: teamMembers } = await getTeamDivisionRosterStats(
    team_id,
    division_id,
  );

  // get current div/season/league data
  const { data: divisionStandings } = await getDivisionStandings(division_id);

  return {
    nextGame: nextGames[0],
    prevGame: prevGames[0],
    teamMembers,
    divisionStandings,
  };
}

const EditTeamSchema = z.object({
  team_id: z.number().min(1),
  name: z
    .string()
    .min(2, { message: "Name must be at least 2 characters long." })
    .trim(),
  description: z.string().trim().optional(),
  color: z.string().optional(),
  custom_color: z.string().refine(check_string_is_color_hex, {
    message: "Invalid color format.",
  }),
});

export async function editTeam(
  state: TeamFormState,
  formData: FormData,
): Promise<TeamFormState> {
  // get data from form
  const teamData = {
    team_id: parseInt(formData.get("team_id") as string),
    name: formData.get("name") as string,
    description: formData.get("description") as string,
    color: formData.get("color") as string,
    custom_color: (formData.get("custom_color") as string) || "#000",
  };

  // Validate data
  const validatedFields = EditTeamSchema.safeParse(teamData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      data: teamData,
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  // Check if user can edit
  const { canEdit } = await canEditTeam(teamData.team_id);

  if (!canEdit) {
    // failed role check, shortcut out
    return {
      message: "You do not have permission to edit this team.",
      status: 401,
    };
  }

  let color: string | null =
    teamData.color !== "custom" ? teamData.color : teamData.custom_color;
  if (color === "") color = null;

  const sql = `
    UPDATE league_management.teams
    SET
      name = $1,
      description = $2,
      color = $3
    WHERE
      team_id = $4
    RETURNING
      slug
  `;

  // query database
  const result: ResultProps<{ slug: string }> = await db
    .query(sql, [teamData.name, teamData.description, color, teamData.team_id])
    .then((res) => {
      return {
        message: `${teamData.name} successfully created!`,
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

  if (result?.data?.slug)
    redirect(createDashboardUrl({ t: result?.data?.slug }));

  return result;
}

const TeamJoinCodeSchema = z.object({
  join_code: z
    .string()
    .min(6, { message: "Join code must be at least 6 characters long" })
    .regex(/[a-zA-Z0-9-]/, { message: "Fails regex" }),
  team_id: z.number().min(1),
});

export async function setTeamJoinCode(
  state: TeamFormState,
  formData: FormData,
): Promise<TeamFormState> {
  const teamData = {
    join_code: formData.get("join_code") as string,
    team_id: parseInt(formData.get("team_id") as string),
  };

  // Validate data
  const validatedFields = TeamJoinCodeSchema.safeParse(teamData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  // Check if user can edit
  const { canEdit } = await canEditTeam(teamData.team_id);

  if (!canEdit) {
    // failed role check, shortcut out
    return {
      message: "You do not have permission to edit this team.",
      status: 401,
    };
  }

  const sql = `
    UPDATE league_management.teams
    SET
      join_code = $1
    WHERE
      team_id = $2
    RETURNING
      join_code
  `;

  // query database
  const result: ResultProps<{ join_code: string }> = await db
    .query(sql, [teamData.join_code, teamData.team_id])
    .then((res) => {
      return {
        message: `Join code updated!`,
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

  return {
    data: result.data,
    message: result.message,
    status: result.status,
  };
}

const JoinTeamSchema = z.object({
  team_id: z.number().min(1),
  join_code: z.string().trim(),
  division_id: z.number().optional(),
  number: z.number().optional(),
  position: z.string().optional(),
});

type JoinTeamErrorProps = {
  team_id?: string[] | undefined;
  join_code?: string[] | undefined;
  division_id?: string[] | undefined;
  number?: string[] | undefined;
  position?: string[] | undefined;
};

type JoinTeamFormState =
  | {
      errors?: JoinTeamErrorProps;
      message?: string;
      status?: number;
      link?: string;
      data?: {
        team_id?: number;
        join_code?: string;
        division_id?: number;
        number?: number;
        position?: string;
      };
    }
  | undefined;

export async function joinTeam(
  state: JoinTeamFormState,
  formData: FormData,
): Promise<JoinTeamFormState> {
  // check user is logged in and get their user_id
  const { user_id } = await verifySession();

  const submittedData = {
    team_id: parseInt(formData.get("team_id") as string),
    join_code: formData.get("join_code") as string,
    division_id: formData.get("division_id")
      ? parseInt(formData.get("division_id") as string)
      : undefined,
    number: formData.get("number")
      ? parseInt(formData.get("number") as string)
      : undefined,
    position: formData.get("position")
      ? (formData.get("position") as string)
      : undefined,
  };

  // Validate data
  const validatedFields = JoinTeamSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      data: submittedData,
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  // get team join_code from database
  const teamDataSql = `
    SELECT
      join_code,
      slug
    FROM
      league_management.teams
    WHERE
      team_id = $1
  `;

  const teamDataResult: ResultProps<{ join_code: string; slug: string }> =
    await db
      .query(teamDataSql, [submittedData.team_id])
      .then((res) => {
        if (res.rowCount === 0) {
          throw new Error("Team not found!");
        }
        return {
          message: "Membership updated!",
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

  if (!teamDataResult?.data) {
    return teamDataResult;
  }

  // compare submitted join_code
  const joinCodesMatch =
    teamDataResult.data.join_code === submittedData.join_code;

  // if join_codes do not match, short circuit
  if (!joinCodesMatch)
    return {
      message: "Join code does not match team's join code!",
      status: 401,
    };

  // check if they are already a team member
  const membershipCheckSql = `
    SELECT
      count(*)
    FROM
      league_management.team_memberships 
    WHERE
      user_id = $1 AND team_id = $2
  `;

  const membershipCheckResult = await db
    .query(membershipCheckSql, [user_id, submittedData.team_id])
    .then((res) => {
      if (res.rows[0].count > 0) {
        throw new Error("You are already a member of this team!");
      }
      return {
        message: "User is not a team member.",
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  // User is not already a team member
  if (membershipCheckResult.status === 200) {
    // add user to team
    const teamSql = `
    INSERT INTO league_management.team_memberships
      (user_id, team_id, team_role)
    VALUES
      ($1, $2, 2)
  `;

    const teamResult = await db
      .query(teamSql, [user_id, submittedData.team_id])
      .then((res) => {
        return {
          message: "Membership updated!",
          status: 200,
        };
      })
      .catch((err) => {
        return {
          message: err.message,
          status: 400,
        };
      });

    if (teamResult.status === 400) return teamResult;
  }

  // if division_id is provided, also add user to team division roster
  if (submittedData.division_id) {
    // check if they are already a member of the division roster
    const rosterCheckSql = `
      SELECT
        count(*)
      FROM
        league_management.division_rosters
      WHERE
        team_membership_id = (SELECT team_membership_id FROM league_management.team_memberships WHERE user_id = $1 AND team_id = $2)
        AND
        division_team_id = (SELECT division_team_id FROM league_management.division_teams WHERE team_id = $2 AND division_id = $3)
    `;

    const rosterCheckResult = await db
      .query(rosterCheckSql, [
        user_id,
        submittedData.team_id,
        submittedData.division_id,
      ])
      .then((res) => {
        if (res.rows[0].count > 0) {
          throw new Error("You are already a member of this roster!");
        }
        return {
          message: "User is not a roster member.",
          status: 200,
        };
      })
      .catch((err) => {
        return {
          message: err.message,
          status: 400,
        };
      });

    if (rosterCheckResult.status === 200) {
      // add user to roster
      const rosterAddSql = `
        INSERT INTO league_management.division_rosters
          (team_membership_id, division_team_id, number, position)
        VALUES
          (
            (SELECT team_membership_id FROM league_management.team_memberships WHERE user_id = $1 AND team_id = $2),
            (SELECT division_team_id FROM league_management.division_teams WHERE team_id = $2 AND division_id = $3),
            $4,
            $5
          )
      `;

      const rosterAddResult = await db
        .query(rosterAddSql, [
          user_id,
          submittedData.team_id,
          submittedData.division_id,
          submittedData.number,
          submittedData.position,
        ])
        .then((res) => {
          return {
            message: "Membership updated!",
            status: 200,
          };
        })
        .catch((err) => {
          return {
            message: err.message,
            status: 400,
          };
        });

      if (rosterAddResult.status === 400) return rosterAddResult;

      // redirect to specific division if division_id provide
      redirect(
        createDashboardUrl({
          t: teamDataResult.data.slug,
          d: submittedData.division_id,
        }),
      );
    }

    // user was already on the roster
    return rosterCheckResult;
  }

  // if user was already a member of the team and
  // did not need to be added to a division roster
  if (membershipCheckResult.status === 400) return membershipCheckResult;

  // else redirect to team page
  if (teamDataResult.data.slug)
    redirect(createDashboardUrl({ t: teamDataResult.data.slug }));
}

const EditTeamMembershipSchema = z.object({
  team_role: z.number().min(1).max(2),
  team_membership_id: z.number().min(1),
});

type EditTeamMembershipErrorProps = {
  team_role?: string[] | undefined;
  team_membership_id?: string[] | undefined;
};

type EditTeamMembershipFormState =
  | {
      errors?: EditTeamMembershipErrorProps;
      message?: string;
      status?: number;
      link?: string;
      data?: {
        team_role?: string;
        team_membership_id?: number;
      };
    }
  | undefined;

export async function editTeamMembership(
  state: EditTeamMembershipFormState,
  formData: FormData,
) {
  const submittedData = {
    team_role: parseInt(formData.get("team_role") as string),
    team_membership_id: parseInt(formData.get("team_membership_id") as string),
    team_id: parseInt(formData.get("team_id") as string),
  };

  // Validate data
  const validatedFields = EditTeamMembershipSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      state,
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  // Check if user can edit
  const { canEdit } = await canEditTeam(submittedData.team_id);

  if (!canEdit) {
    // failed role check, shortcut out
    return {
      message:
        "You do not have permission to modify memberships for this team.",
      status: 401,
    };
  }

  const sql = `
    UPDATE league_management.team_memberships
    SET
      team_role = $1
    WHERE
      team_membership_id = $2
  `;

  const result = await db
    .query(sql, [submittedData.team_role, submittedData.team_membership_id])
    .then((res) => {
      return {
        message: "Membership updated!",
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  if (result.status === 200) {
    state?.link && redirect(state.link);
  }

  return state;
}

const RemoveTeamMembershipSchema = z.object({
  team_membership_id: z.number().min(1),
});

type RemoveTeamMembershipFormState =
  | {
      errors?: EditTeamMembershipErrorProps;
      message?: string;
      status?: number;
      link?: string;
      data?: {
        team_membership_id?: number;
      };
    }
  | undefined;

export async function removeTeamMembership(
  state: RemoveTeamMembershipFormState,
  formData: FormData,
) {
  const submittedData = {
    team_id: parseInt(formData.get("team_id") as string),
    team_membership_id: parseInt(formData.get("team_membership_id") as string),
  };

  // Validate data
  const validatedFields = RemoveTeamMembershipSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      state,
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  // Check if user can edit
  const { canEdit } = await canEditTeam(submittedData.team_id);

  if (!canEdit) {
    // failed role check, shortcut out
    return {
      message:
        "You do not have permission to modify memberships for this team.",
      status: 401,
    };
  }

  // TODO: add a check to see if the user who is being removed is a manager
  //       if so, make sure there is at least one other manager before removing

  const sql = `
    DELETE FROM league_management.team_memberships
    WHERE team_membership_id = $1
  `;

  const result = await db
    .query(sql, [submittedData.team_membership_id])
    .then((res) => {
      return {
        message: "Player removed from team!",
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  if (result.status === 200) {
    state?.link && redirect(state.link);
  }

  return state;
}

const AddPlayerToDivisionTeamSchema = z.object({
  division_team_id: z.number().min(1),
  team_membership_id: z.number().min(1),
  number: z.number().min(1).max(98).optional(),
  position: z.string().optional(),
  roster_role: z.number().min(1).max(5),
});

type AddPlayerToDivisionTeamErrorProps = {
  division_roster_id?: string[] | undefined;
  division_team_id?: string[] | undefined;
  team_membership_id?: string[] | undefined;
  number?: string[] | undefined;
  position?: string[] | undefined;
  roster_role?: string[] | undefined;
};

type AddPlayerToDivisionTeamFormState =
  | {
      errors?: AddPlayerToDivisionTeamErrorProps;
      message?: string;
      status?: number;
      link?: string;
      data?: {
        team_id?: number;
        division_team_id?: number;
        team_membership_id?: number;
        number?: number;
        position?: string;
        roster_role?: number;
      };
    }
  | undefined;

export async function addPlayerToDivisionTeam(
  state: AddPlayerToDivisionTeamFormState,
  formData: FormData,
): Promise<AddPlayerToDivisionTeamFormState> {
  const submittedData = {
    team_id: parseInt(formData.get("team_id") as string),
    division_team_id: parseInt(formData.get("division_team_id") as string),
    team_membership_id: parseInt(formData.get("team_membership_id") as string),
    number: formData.get("number")
      ? parseInt(formData.get("number") as string)
      : undefined,
    position: (formData.get("position") as string) || undefined,
    roster_role: formData.get("roster_role")
      ? parseInt(formData.get("roster_role") as string)
      : undefined,
  };

  // Validate data
  const validatedFields =
    AddPlayerToDivisionTeamSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      data: submittedData,
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  // Check if user can edit
  const { canEdit } = await canEditTeam(submittedData.team_id);

  if (!canEdit) {
    // failed role check, shortcut out
    return {
      message: "You do not have permission to modify rosters for this team.",
      status: 401,
    };
  }

  const sql = `
    INSERT INTO league_management.division_rosters
      (division_team_id, team_membership_id, number, position, roster_role)
    VALUES
      ($1, $2, $3, $4, $5)
  `;

  const result = await db
    .query(sql, [
      submittedData.division_team_id,
      submittedData.team_membership_id,
      submittedData.number,
      submittedData.position,
      submittedData.roster_role,
    ])
    .then((res) => {
      return {
        message: "Player added to division team!",
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  if (result.status === 200) {
    state?.link && redirect(state.link);
  }

  return state;
}

const EditPlayerOnDivisionTeamSchema = z.object({
  division_roster_id: z.number().min(1),
  number: z.number().min(1).max(98).optional(),
  position: z.string().optional(),
  roster_role: z.number().min(1).max(5),
});

export async function editPlayerOnDivisionTeam(
  state: AddPlayerToDivisionTeamFormState,
  formData: FormData,
) {
  const submittedData = {
    team_id: parseInt(formData.get("team_id") as string),
    division_roster_id: parseInt(formData.get("division_roster_id") as string),
    number: formData.get("number")
      ? parseInt(formData.get("number") as string)
      : undefined,
    position: (formData.get("position") as string) || undefined,
    roster_role: formData.get("roster_role")
      ? parseInt(formData.get("roster_role") as string)
      : undefined,
  };

  // Validate data
  const validatedFields =
    EditPlayerOnDivisionTeamSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      state,
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  // Check if user can edit
  const { canEdit } = await canEditTeam(submittedData.team_id);

  if (!canEdit) {
    // failed role check, shortcut out
    return {
      message: "You do not have permission to modify rosters for this team.",
      status: 401,
    };
  }

  const sql = `
    UPDATE league_management.division_rosters
    SET 
      number = $1,
      position = $2,
      roster_role = $3
    WHERE
      division_roster_id = $4
  `;

  const result = await db
    .query(sql, [
      submittedData.number,
      submittedData.position,
      submittedData.roster_role,
      submittedData.division_roster_id,
    ])
    .then((res) => {
      return {
        message: "Player information updated!",
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  if (result.status === 200) {
    state?.link && redirect(state.link);
  }

  return state;
}

const RemovePlayerFromDivisionTeamSchema = z.object({
  division_roster_id: z.number().min(1),
});

type RemovePlayerFromDivisionTeamFormState =
  | {
      errors?: AddPlayerToDivisionTeamErrorProps;
      message?: string;
      status?: number;
      link?: string;
      data?: {
        team_id?: number;
        division_team_id?: number;
      };
    }
  | undefined;

export async function removePlayerFromDivisionTeam(
  state: RemovePlayerFromDivisionTeamFormState,
  formData: FormData,
) {
  const submittedData = {
    team_id: parseInt(formData.get("team_id") as string),
    division_roster_id: parseInt(formData.get("division_roster_id") as string),
  };

  // Validate data
  const validatedFields =
    RemovePlayerFromDivisionTeamSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      state,
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  // Check if user can edit
  const { canEdit } = await canEditTeam(submittedData.team_id);

  if (!canEdit) {
    // failed role check, shortcut out
    return {
      message: "You do not have permission to modify rosters for this team.",
      status: 401,
    };
  }

  const sql = `
    DELETE FROM league_management.division_rosters
    WHERE division_roster_id = $1
  `;

  const result = await db
    .query(sql, [submittedData.division_roster_id])
    .then((res) => {
      return {
        message: "Player removed from team!",
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  if (result.status === 200) {
    state?.link && redirect(state.link);
  }

  return state;
}

export async function deleteTeam(state: { team_id: number }) {
  // Check if user can delete
  const siteAdmin = await verifyUserRole(1);

  // if not, short circuit
  if (!siteAdmin)
    return {
      state: {
        team_id: state.team_id,
        message: "You do not have permission to delete this team",
        status: 401,
      },
    };

  const sql = `
    DELETE FROM league_management.teams
    WHERE team_id = $1
  `;

  const result = await db
    .query(sql, [state.team_id])
    .then(() => {
      return {
        message: "League deleted",
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  if (result.status === 400) {
    return result;
  }

  redirect("/dashboard/t");
}
