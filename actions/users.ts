"use server";

import bcrypt from "bcrypt";
import { db } from "@/db/pg";
import { verifySession } from "@/lib/session";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { wait } from "@/utils/helpers/general";
import { isObjectEmpty } from "@/utils/helpers/objects";
import { redirect } from "next/navigation";
import { z } from "zod";

export async function getDashboardMenuData(): Promise<
  ResultProps<{
    teams: MenuItemData[];
    leagues: MenuItemData[];
  }>
> {
  const { user_id } = await verifySession();

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
      a.user_id = $1
    ORDER BY
      l.name ASC
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

export async function getUser(
  identifier: string,
): Promise<ResultProps<UserData>> {
  const { user_id } = await verifySession();

  const sql = `
    SELECT
      user_id,
      username,
      email,
      first_name,
      last_name,
      gender,
      pronouns,
      user_role,
      img,
      status
    FROM
      admin.users
    WHERE
      username = $1
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

  return result;
}

export async function getUserRole(): Promise<number> {
  const { user_id } = await verifySession();

  const sql = `
    SELECT
      user_role
    FROM
      admin.users as u
    WHERE
      user_id = $1
  `;

  const result: number = await db
    .query(sql, [user_id])
    .then((res) => {
      if (!res.rowCount) {
        throw new Error("User not found.");
      }

      return res.rows[0].user_role;
    })
    .catch((err) => {
      // TODO: add more comprehensive error handling
      return 0;
    });

  return result;
}

export async function verifyUserRole(roleType: number) {
  const user_role = await getUserRole();

  return user_role === roleType;
}

export async function canEditUser(user_to_edit: number | string) {
  // get logged in user_id
  const { user_id: logged_user_id } = await verifySession();

  // Check if logged in user is site wide admin
  const isAdmin = await verifyUserRole(1);

  // if username is provided, look up users user_id in database
  let user_to_edit_id =
    typeof user_to_edit === "number" ? user_to_edit : undefined;

  if (typeof user_to_edit === "string") {
    const userIdSql = `
      SELECT
        user_id
      FROM
        admin.users
      WHERE
        username = $1
    `;

    await db.query(userIdSql, [user_to_edit]).then((res) => {
      if (res.rowCount === 0) {
        throw new Error("User not found");
      }
      user_to_edit_id = res.rows[0].user_id;
    });
  }

  const isCurrentUser = logged_user_id === user_to_edit_id;

  return {
    canEdit: isAdmin || isCurrentUser,
    isAdmin,
    isCurrentUser,
  };
}

export async function getUserManagedTeams(
  user_id?: number,
): Promise<ResultProps<TeamData[]>> {
  // verify session
  const { user_id: logged_user_id } = await verifySession();

  let id = user_id || logged_user_id;

  const sql = `
    SELECT 
      t.team_id,
      t.name,
      t.slug,
      tm.team_role
    FROM
      league_management.team_memberships AS tm
    JOIN
      league_management.teams AS t
    ON
      tm.team_id = t.team_id
    WHERE
      tm.user_id = $1
      AND
      tm.team_role = 1
    ORDER BY t.name
  `;

  const result = await db
    .query(sql, [id])
    .then((res) => {
      return {
        message: `Managed teams found!`,
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

export async function getUserManagedTeamsForJoinDivision(
  division_id: number,
  user_id?: number,
): Promise<ResultProps<TeamData[]>> {
  // verify session
  const { user_id: logged_user_id } = await verifySession();

  let id = user_id || logged_user_id;

  const sql = `
    SELECT 
      t.team_id,
      t.name,
      t.slug,
      tm.team_role
    FROM
      league_management.team_memberships AS tm
    JOIN
      league_management.teams AS t
    ON
      tm.team_id = t.team_id
    WHERE
      tm.user_id = $1
      AND
      tm.team_role = 1
      AND
      t.team_id NOT IN (SELECT team_id FROM league_management.division_teams WHERE division_id = $2)
    ORDER BY t.name
  `;

  const result = await db
    .query(sql, [id, division_id])
    .then((res) => {
      console.log(res);
      return {
        message: `Managed teams found!`,
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

const EditUserSchema = z.object({
  username: z
    .string()
    .min(2, { message: "Name must be at least 2 characters long." })
    .trim(),
  email: z.string().email({ message: "Please enter a valid email." }).trim(),
  first_name: z
    .string()
    .min(2, { message: "Name must be at least 2 characters long." })
    .trim(),
  last_name: z
    .string()
    .min(2, { message: "Name must be at least 2 characters long." })
    .trim(),
  gender: z.string().optional(),
  pronouns: z.string().optional(),
});

export async function editUser(
  state: UserFormState,
  formData: FormData,
): Promise<UserFormState> {
  // organize submitted data
  const submittedData = {
    user_id: parseInt(formData.get("user_id") as string),
    username: formData.get("username") as string,
    email: formData.get("email") as string,
    first_name: formData.get("first_name") as string,
    last_name: formData.get("last_name") as string,
    gender: formData.get("gender") as string,
    pronouns: formData.get("pronouns") as string,
  };

  // Validate data
  const validatedFields = EditUserSchema.safeParse(submittedData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    return {
      data: submittedData,
      errors: validatedFields.error.flatten().fieldErrors,
    };
  }

  // check if user can edit the user
  const { canEdit } = await canEditUser(submittedData.user_id);

  if (!canEdit) {
    return {
      message: "You do not have permission to edit this user!",
      status: 401,
      data: submittedData,
    };
  }

  const sql = `
    UPDATE admin.users
    SET
      username = $1,
      email = $2,
      first_name = $3,
      last_name = $4,
      gender = $5,
      pronouns = $6
    WHERE
      user_id = $7
    RETURNING
      username
  `;

  const result: ResultProps<{ username: string }> = await db
    .query(sql, [
      submittedData.username,
      submittedData.email,
      submittedData.first_name,
      submittedData.last_name,
      submittedData.gender,
      submittedData.pronouns,
      submittedData.user_id,
    ])
    .then((res) => {
      return {
        message: "User updated!",
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

  if (!result.data) {
    return {
      ...result,
      data: submittedData,
    };
  }

  redirect(createDashboardUrl({ u: result.data.username }, "edit"));
}

const PasswordSchema = z.object({
  current_password: z.string().trim(),
  new_password: z
    .string()
    .min(8, { message: "Be at least 8 characters long" })
    .regex(/[a-zA-Z]/, { message: "Contain at least one letter." })
    .regex(/[0-9]/, { message: "Contain at least one number." })
    .regex(/[^a-zA-Z0-9]/, {
      message: "Contain at least one special character.",
    })
    .trim(),
  confirm_password: z.string().trim(),
  user_id: z.number().min(1),
});

type PasswordFormErrors = {
  current_password?: string[] | undefined;
  new_password?: string[] | undefined;
  confirm_password?: string[] | undefined;
  user_id?: string[] | undefined;
};

type PasswordFormState = FormState<
  PasswordFormErrors,
  {
    current_password: string;
    new_password: string;
    confirm_password: string;
    user_id: number;
  }
>;

export async function updatePassword(
  state: PasswordFormState,
  formData: FormData,
): Promise<PasswordFormState> {
  const submittedData = {
    current_password: formData.get("current_password") as string,
    new_password: formData.get("new_password") as string,
    confirm_password: formData.get("confirm_password") as string,
    user_id: parseInt(formData.get("user_id") as string),
  };

  const { isCurrentUser } = await canEditUser(submittedData.user_id);

  if (!isCurrentUser) {
    return {
      message:
        "You are only permitted to change your own password. If a user needs their password reset, use the reset password functionality.",
      status: 401,
      data: submittedData,
    };
  }

  let errors: PasswordFormErrors = {};

  // Validate data
  const validatedFields = PasswordSchema.safeParse(submittedData);

  // If any form fields are invalid, add errors to list
  if (!validatedFields.success) {
    errors = validatedFields.error.flatten().fieldErrors;
  }

  // check if passwords match
  if (submittedData.new_password !== submittedData.confirm_password) {
    errors.confirm_password = ["Passwords must match!"];
  }

  // If there are any errors, return the errors
  if (!isObjectEmpty(errors)) {
    return {
      errors,
      data: submittedData,
    };
  }

  // get user's current password from DB
  const selectSql = `
    SELECT
      password_hash
    FROM
      admin.users
    WHERE
      user_id = $1
  `;

  const selectResult: ResultProps<{ password_hash: string }> = await db
    .query(selectSql, [submittedData.user_id])
    .then((res) => {
      if (res.rowCount === 0) {
        throw new Error("User not found.");
      }
      return {
        message: "Password retrieved.",
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

  if (!selectResult.data) {
    return {
      ...selectResult,
      data: submittedData,
    };
  }

  // compare passwords
  const passwordsMatch = await bcrypt.compare(
    submittedData.current_password,
    selectResult.data.password_hash,
  );

  if (!passwordsMatch) {
    return {
      errors: {
        current_password: ["Password is incorrect"],
      },
      data: submittedData,
    };
  }

  // hash new_password
  const hashed_new_password = await bcrypt.hash(submittedData.new_password, 10);

  // build update sql statement
  // this statement automatically confirms the current_password matches
  // by including it in the WHERE clause with the user_id
  const updateSql = `
    UPDATE admin.users
    SET
      password_hash = $1
    WHERE
      user_id = $2
  `;

  // query the database
  const updateResult = await db
    .query(updateSql, [hashed_new_password, submittedData.user_id])
    .then((res) => {
      console.log(res);
      return {
        message: "Password successfully updated.",
        status: 200,
      };
    })
    .catch((err) => {
      return {
        message: err.message,
        status: 400,
      };
    });

  return {
    ...updateResult,
    data: submittedData,
  };
}
