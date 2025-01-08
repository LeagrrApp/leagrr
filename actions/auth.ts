"use server";

import bcrypt from "bcrypt";
import { SignupFormSchema, FormState } from "@/lib/definitions";
import { db } from "@/db/pg";
import { createSession, getSession } from "@/lib/session";
import { isObjectEmpty } from "@/utils/helpers/objects";
import { redirect } from "next/navigation";
import { cookies } from "next/headers";

interface ErrorProps {
  email?: string[] | undefined;
  username?: string[] | undefined;
  first_name?: string[] | undefined;
  last_name?: string[] | undefined;
  password?: string[] | undefined;
  password_confirm?: string[] | undefined;
}

export async function signUp(state: FormState, formData: FormData) {
  const userData = {
    email: formData.get("email"),
    username: formData.get("username"),
    first_name: formData.get("first_name"),
    last_name: formData.get("last_name"),
    password: formData.get("password") as string,
  };

  let errors: ErrorProps = {};

  // Validate form fields
  const validatedFields = SignupFormSchema.safeParse(userData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    errors = validatedFields.error.flatten().fieldErrors;
  }

  // check if passwords match
  if (userData.password !== formData.get("password_confirm")) {
    errors.password_confirm = ["Passwords must match!"];
  }

  // If there are any errors, return the errors
  if (!isObjectEmpty(errors)) {
    return {
      errors,
    };
  }

  // hash password with bcrypt
  const password_hash = await bcrypt.hash(userData.password, 10);

  // create PostgreSQL insert statement
  const insertSql: string = `
    INSERT INTO
    admin.users (username, email, first_name, last_name, password_hash)
    VALUES
    ($1, $2, $3, $4, $5)
    `;

  // run PostgreSql query with pg
  const insertResult: ResultProps = await db
    .query(insertSql, [
      userData.username,
      userData.email,
      userData.first_name,
      userData.last_name,
      password_hash,
    ])
    .then(() => {
      return { message: `Sign up successful!`, status: 200 };
    })
    .catch((err) => {
      console.log(err);

      // TODO: add proper error handling function based on PostgreSQL error codes
      // handle user creation errors

      return {
        message: "There was a problem creating new user, try again.",
        status: 400,
      };
    });

  if (insertResult.status !== 200) {
    // Insert failed, return error message
    return { ...insertResult };
  }

  const selectSql = `
    SELECT
      user_id,
      user_role
    FROM
      admin.users
    WHERE
      username=$1
  `;

  const selectResult: SelectResultProps = await db
    .query(selectSql, [userData.username])
    .then((res) => {
      if (!res.rowCount) {
        // no user found
        throw new Error("Sorry, user not found.");
      }
      // successfully found user
      return {
        message: "User data for session retrieved.",
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

  if (selectResult.data) {
    const { user_id, user_role } = selectResult.data;

    // create user session
    await createSession(user_id as number, user_role as number);

    // redirect user
    redirect(`/u/${userData.username}`);
  }

  return {
    ...selectResult,
  };
}

export async function signIn(state: FormState, formData: FormData) {
  const identifier = formData.get("identifier") as string;
  const password = formData.get("password") as string;

  if (!identifier || !password) return;

  // Get user data from database based on identifier, select user_id, user_role, and password_hash
  const selectSql = `
    SELECT
      user_id,
      user_role,
      username,
      password_hash
    FROM
      admin.users
    WHERE
      username=$1 OR email=$1
  `;

  const selectResult: SelectResultProps = await db
    .query(selectSql, [identifier])
    .then((res) => {
      if (!res.rowCount) {
        throw new Error("Username or password was incorrect.");
      }
      return {
        message: "User data for session retrieved.",
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

  // If user was found, continue sign in steps
  if (selectResult.data) {
    const { user_id, user_role, username, password_hash } = selectResult.data;

    // compare provided password with password_hash from db
    const passwordsMatch = await bcrypt.compare(password, password_hash);

    // if passwords don't match, return result for front end alert
    if (!passwordsMatch)
      return {
        message: "Username or password was incorrect",
        status: 401,
      };

    // create user session
    await createSession(user_id as number, user_role as number);

    // redirect user
    redirect(`/u/${username}`);
  }

  // user not found, return result for front end alerts
  return {
    ...selectResult,
  };
}

export async function logOut() {
  // remove the session
  (await cookies()).set("session", "", { expires: new Date(0) });
}

export async function isLoggedIn() {
  const session = await getSession();

  if (!session) redirect("/sign-in");
}
