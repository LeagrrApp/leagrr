"use server";

import { db } from "@/db/pg";
import { verifySession } from "@/lib/session";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { redirect } from "next/navigation";
import { z } from "zod";
import { canEditTeam, verifyTeamRoleLevel } from "./teams";

/* ---------- CREATE ---------- */

type TeamMembershipErrorProps = {
  team_id?: string[] | undefined;
  join_code?: string[] | undefined;
  division_id?: string[] | undefined;
  number?: string[] | undefined;
  position?: string[] | undefined;
  team_role?: string[] | undefined;
  team_membership_id?: string[] | undefined;
  user_id?: string[] | undefined;
};

type TeamMembershipFormState = FormState<
  TeamMembershipErrorProps,
  {
    team_id?: number;
    join_code?: string;
    division_id?: number;
    number?: number;
    position?: string;
    team_role?: number;
    team_membership_id?: number;
    user_id?: number;
  }
>;

const JoinTeamSchema = z.object({
  team_id: z.number().min(1),
  join_code: z.string().trim(),
  division_id: z.number().optional(),
  number: z.number().optional(),
  position: z.string().optional(),
});

export async function joinTeam(
  state: TeamMembershipFormState,
  formData: FormData,
): Promise<TeamMembershipFormState> {
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

  // set default response status code
  let status = 400;

  // initialize redirectLink
  let redirectLink: string | undefined = undefined;

  try {
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

    const { rows: teamRows } = await db.query<{
      join_code: string;
      slug: string;
    }>(teamDataSql, [submittedData.team_id]);

    if (!teamRows[0]) {
      status = 404;
      throw new Error("Team not found!");
    }

    // compare submitted join_code
    const joinCodesMatch = teamRows[0].join_code === submittedData.join_code;

    // if join_codes do not match, short circuit
    if (!joinCodesMatch) {
      status = 401;
      throw new Error("Join code does not match team's join code!");
    }

    // check if they are already a team member
    const membershipCheckSql = `
      SELECT
        user_id
      FROM
        league_management.team_memberships 
      WHERE
        user_id = $1 AND team_id = $2
    `;

    const { rowCount: membershipRowCount } = await db.query(
      membershipCheckSql,
      [user_id, submittedData.team_id],
    );

    if (
      !submittedData.division_id &&
      membershipRowCount &&
      membershipRowCount > 0
    ) {
      // User is not looking to join a division
      // and is already a member of the team
      // therefore error out.
      throw new Error("You are already a member of this team!");
    }

    if (!membershipRowCount || membershipRowCount === 0) {
      // User is not already a team member
      // add user to team
      const teamSql = `
        INSERT INTO league_management.team_memberships
          (user_id, team_id, team_role)
        VALUES
          ($1, $2, 2)
      `;

      const { rowCount: teamAddRowCount } = await db.query(teamSql, [
        user_id,
        submittedData.team_id,
      ]);

      // throw an error if not properly added to the team
      if (teamAddRowCount !== 1)
        throw new Error("Sorry, there was a problem joining team.");
    }

    // if division_id is provided, also add user to team division roster
    if (submittedData.division_id) {
      // check if they are already a member of the division roster
      const rosterCheckSql = `
        SELECT
          division_roster_id
        FROM
          league_management.division_rosters
        WHERE
          team_membership_id = (SELECT team_membership_id FROM league_management.team_memberships WHERE user_id = $1 AND team_id = $2)
          AND
          division_team_id = (SELECT division_team_id FROM league_management.division_teams WHERE team_id = $2 AND division_id = $3)
      `;

      const { rowCount: rosterCheckRowCount } = await db.query(rosterCheckSql, [
        user_id,
        submittedData.team_id,
        submittedData.division_id,
      ]);

      // if a count is returned, that means they are already a division roster member
      // therefore should be errored out
      if (rosterCheckRowCount !== 0)
        throw new Error("You are already a member of this roster!");

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

      const { rowCount: rosterAddRowCount } = await db.query(rosterAddSql, [
        user_id,
        submittedData.team_id,
        submittedData.division_id,
        submittedData.number,
        submittedData.position,
      ]);

      // no rowCount means they were not added properly,
      // throw an error if this is the case
      if (rosterAddRowCount === 0)
        throw new Error(
          "Sorry, there was a problem adding you to this roster!",
        );

      // successfully added to the division roster
      // redirect to specific division if division_id provide
      redirectLink = createDashboardUrl({
        t: teamRows[0].slug,
        d: submittedData.division_id,
      });
    }

    // if user was just joining a team, not a division roster,
    // redirect to team page
    redirectLink = createDashboardUrl({ t: teamRows[0].slug });
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

  if (redirectLink) redirect(redirectLink);
}

type DivisionTeamErrorProps = {
  division_roster_id?: string[] | undefined;
  division_team_id?: string[] | undefined;
  team_membership_id?: string[] | undefined;
  number?: string[] | undefined;
  position?: string[] | undefined;
  roster_role?: string[] | undefined;
};

type DivisionTeamFormState = FormState<
  DivisionTeamErrorProps,
  {
    team_id?: number;
    division_team_id?: number;
    team_membership_id?: number;
    number?: number;
    position?: string;
    roster_role?: number;
  }
>;

const AddPlayerToDivisionTeamSchema = z.object({
  division_team_id: z.number().min(1),
  team_membership_id: z.number().min(1),
  number: z.number().min(1).max(98).optional(),
  position: z.string().optional(),
  roster_role: z.number().min(1).max(5),
});

export async function addPlayerToDivisionTeam(
  state: DivisionTeamFormState,
  formData: FormData,
): Promise<DivisionTeamFormState> {
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

  // initialize result status code
  let status = 400;

  // initialize success check
  let success = false;

  try {
    // Check if user can edit
    const { canEdit } = await canEditTeam(submittedData.team_id);

    if (!canEdit) {
      // failed role check, shortcut out
      status = 401;
      throw new Error(
        "You do not have permission to modify rosters for this team.",
      );
    }

    const sql = `
    INSERT INTO league_management.division_rosters
      (division_team_id, team_membership_id, number, position, roster_role)
    VALUES
      ($1, $2, $3, $4, $5)
  `;

    const { rowCount } = await db.query(sql, [
      submittedData.division_team_id,
      submittedData.team_membership_id,
      submittedData.number,
      submittedData.position,
      submittedData.roster_role,
    ]);

    if (rowCount !== 1)
      throw new Error("Sorry, there was a problem adding user to roster.");

    success = true;
  } catch (err) {
    if (err instanceof Error) {
      return {
        ...state,
        message: err.message,
        status,
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

  if (state?.link && success) redirect(state.link);
}

type JoinTeamByCodeFormState = FormState<
  TeamMembershipErrorProps,
  {
    join_code?: string;
  }
>;

const JoinTeamByCodeSchema = z.object({
  join_code: z.string().trim(),
});

export async function joinTeamByCode(
  state: JoinTeamByCodeFormState,
  formData: FormData,
): Promise<JoinTeamByCodeFormState> {
  // check user is logged in and get their user_id
  const { user_id } = await verifySession();

  const submittedData = {
    join_code: formData.get("join_code") as string,
  };

  // Validate data
  const validatedFields = JoinTeamByCodeSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      data: submittedData,
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  // initialize redirect link
  let redirectLink: string | undefined = undefined;

  // initialize error status code
  let status = 400;

  try {
    // get team by join_code, returning team_id and slug
    const selectTeamSql = `
      SELECT
        team_id,
        slug
      FROM
        league_management.teams
      WHERE
        join_code = $1
    `;

    const { rows: teamRows } = await db.query<{
      team_id: number;
      slug: string;
    }>(selectTeamSql, [submittedData.join_code]);

    // if no team found, error out
    if (!teamRows[0]) {
      status = 404;
      throw new Error("Sorry, join code does not match any teams!");
    }

    // create new team membership
    const insertTMSql = `
      INSERT INTO league_management.team_memberships
        (team_id, user_id)
      VALUES
        ($1, $2)
    `;

    const { rowCount } = await db.query(insertTMSql, [
      teamRows[0].team_id,
      user_id,
    ]);

    // no row count indicates and error occurred.
    if (rowCount === 0) {
      throw new Error("Sorry, there was a problem joining team.");
    }

    // set redirect url
    redirectLink = createDashboardUrl({ t: teamRows[0].slug });
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

  // redirect to team page
  if (redirect) redirect(redirectLink);
}

/* ---------- READ ---------- */

export async function getAllTeamMembers(team_id: number) {
  // confirm logged in
  await verifySession();

  try {
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

    const { rows } = await db.query<TeamUserData>(sql, [team_id]);

    return {
      message: "Team list found",
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

export async function getTeamDivisionRoster(
  team_id: number,
  division_id: number,
) {
  // confirm logged in
  await verifySession();

  try {
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

    const { rows } = await db.query<TeamUserData>(sql, [team_id, division_id]);
    return {
      message: "Division roster found",
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

/* ---------- UPDATE ---------- */

const EditTeamMembershipSchema = z.object({
  team_role: z.number().min(1).max(2),
  team_membership_id: z.number().min(1),
  user_id: z.number().min(1),
});

export async function editTeamMembership(
  state: TeamMembershipFormState,
  formData: FormData,
): Promise<TeamMembershipFormState> {
  const submittedData = {
    team_role: parseInt(formData.get("team_role") as string),
    team_membership_id: parseInt(formData.get("team_membership_id") as string),
    team_id: parseInt(formData.get("team_id") as string),
    user_id: parseInt(formData.get("user_id") as string),
  };

  // Validate data
  const validatedFields = EditTeamMembershipSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      data: submittedData,
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  // initialize result status code
  let status = 400;

  // initialize success check
  let success = false;

  try {
    // Check if user can edit
    const { canEdit } = await canEditTeam(submittedData.team_id);

    if (!canEdit) {
      // failed role check, shortcut out

      status = 401;
      throw new Error(
        "You do not have permission to modify memberships for this team.",
      );
    }

    // Check if they are a team manager
    const isManager = await verifyTeamRoleLevel(submittedData.team_id, 1, {
      user_id: submittedData.user_id,
    });

    // if manager, confirm there is one other manager before removing the user from team
    if (isManager) {
      const sql = `
        SELECT
          team_role
        FROM
          league_management.team_memberships
        WHERE
          team_id = $1
          AND
          team_role = 1
      `;

      const { rowCount } = await db.query(sql, [submittedData.team_id]);

      if (!rowCount || rowCount <= 1) {
        throw new Error(
          "This team member cannot be edited because there must always be at least one team manager.",
        );
      }
    }

    const sql = `
      UPDATE league_management.team_memberships
      SET
        team_role = $1
      WHERE
        team_membership_id = $2
    `;

    const { rowCount } = await db.query(sql, [
      submittedData.team_role,
      submittedData.team_membership_id,
    ]);

    if (rowCount === 1) {
      success = true;
    } else {
      throw new Error("Sorry, unable to update team membership.");
    }
  } catch (err) {
    if (err instanceof Error) {
      return {
        ...state,
        message: err.message,
        status,
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

  if (state?.link && success) redirect(state.link);
}

const EditPlayerOnDivisionTeamSchema = z.object({
  division_roster_id: z.number().min(1),
  number: z.number().min(1).max(98).optional(),
  position: z.string().optional(),
  roster_role: z.number().min(1).max(5),
});

export async function editPlayerOnDivisionTeam(
  state: DivisionTeamFormState,
  formData: FormData,
): Promise<DivisionTeamFormState> {
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
      data: submittedData,
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  // initialize success check
  let success = false;

  // initialize result status code
  let status = 400;

  try {
    // Check if user can edit
    const { canEdit } = await canEditTeam(submittedData.team_id);

    if (!canEdit) {
      // failed role check, shortcut out
      status = 401;
      throw new Error(
        "You do not have permission to modify rosters for this team.",
      );
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

    const { rowCount } = await db.query(sql, [
      submittedData.number,
      submittedData.position,
      submittedData.roster_role,
      submittedData.division_roster_id,
    ]);

    if (rowCount !== 1)
      throw new Error("Sorry, there was a problem updating player in roster.");

    success = true;
  } catch (err) {
    if (err instanceof Error) {
      return {
        ...state,
        message: err.message,
        status,
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

  if (state?.link && success) redirect(state.link);
}

/* ---------- DELETE ---------- */

const RemoveTeamMembershipSchema = z.object({
  team_membership_id: z.number().min(1),
  user_id: z.number().min(1),
});

export async function removeTeamMembership(
  state: TeamMembershipFormState,
  formData: FormData,
): Promise<TeamMembershipFormState> {
  const submittedData = {
    team_id: parseInt(formData.get("team_id") as string),
    team_membership_id: parseInt(formData.get("team_membership_id") as string),
    user_id: parseInt(formData.get("user_id") as string),
  };

  // Validate data
  const validatedFields = RemoveTeamMembershipSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      data: submittedData,
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  // initialize success
  let success = false;

  // initialize response status code
  let status = 400;

  try {
    // Check if user can edit
    const { canEdit } = await canEditTeam(submittedData.team_id);

    if (!canEdit) {
      // failed role check, shortcut out
      status = 401;
      throw new Error(
        "You do not have permission to modify memberships for this team.",
      );
    }

    // Check if they are a team manager
    const isManager = await verifyTeamRoleLevel(submittedData.team_id, 1, {
      user_id: submittedData.user_id,
    });

    // if manager, confirm there is one other manager before removing the user from team
    if (isManager) {
      const sql = `
        SELECT
          team_role
        FROM
          league_management.team_memberships
        WHERE
          team_id = $1
          AND
          team_role = 1
      `;

      const { rowCount } = await db.query(sql, [submittedData.team_id]);

      if (!rowCount || rowCount <= 1) {
        throw new Error(
          "This team member cannot be removed because there must always be at least one team manager.",
        );
      }
    }

    const sql = `
      DELETE FROM league_management.team_memberships
      WHERE team_membership_id = $1
    `;

    const { rowCount } = await db.query(sql, [
      submittedData.team_membership_id,
    ]);

    if (rowCount !== 1)
      throw new Error("Sorry, there was a problem removing team member.");

    success = true;
  } catch (err) {
    if (err instanceof Error) {
      return {
        ...state,
        message: err.message,
        status,
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

  if (state?.link && success) redirect(state.link);
}

const RemovePlayerFromDivisionTeamSchema = z.object({
  division_roster_id: z.number().min(1),
});

export async function removePlayerFromDivisionTeam(
  state: DivisionTeamFormState,
  formData: FormData,
): Promise<DivisionTeamFormState> {
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
      data: submittedData,
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  // initialize success check
  let success = false;

  // initialize result status code
  let status = 400;

  try {
    // Check if user can edit
    const { canEdit } = await canEditTeam(submittedData.team_id);

    if (!canEdit) {
      // failed role check, shortcut out
      status = 401;
      throw new Error(
        "You do not have permission to modify rosters for this team.",
      );
    }

    const sql = `
      DELETE FROM league_management.division_rosters
      WHERE division_roster_id = $1
    `;

    const { rowCount } = await db.query(sql, [
      submittedData.division_roster_id,
    ]);

    if (rowCount !== 1)
      throw new Error(
        "Sorry, there was a problem removing player from roster.",
      );

    success = true;
  } catch (err) {
    if (err instanceof Error) {
      return {
        ...state,
        message: err.message,
        status,
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

  if (state?.link && success) redirect(state.link);
}
