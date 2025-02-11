"use server";

import bcrypt from "bcrypt";
import { db } from "@/db/pg";
import { createSession } from "@/lib/session";
import { isObjectEmpty } from "@/utils/helpers/objects";
import { redirect } from "next/navigation";
import { cookies } from "next/headers";
import { z } from "zod";

const SignupFormSchema = z.object({
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
  password: z
    .string()
    .min(8, { message: "Be at least 8 characters long" })
    .regex(/[a-zA-Z]/, { message: "Contain at least one letter." })
    .regex(/[0-9]/, { message: "Contain at least one number." })
    .regex(/[^a-zA-Z0-9]/, {
      message: "Contain at least one special character.",
    })
    .trim(),
});

export async function signUp(state: UserFormState, formData: FormData) {
  const submittedData = {
    email: formData.get("email") as string,
    username: formData.get("username") as string,
    first_name: formData.get("first_name") as string,
    last_name: formData.get("last_name") as string,
    password: formData.get("password") as string,
  };

  let errors: UserErrorProps = {};

  // Validate form fields
  const validatedFields = SignupFormSchema.safeParse(submittedData);

  // If any form fields are invalid, add errors to list
  if (!validatedFields.success) {
    errors = validatedFields.error.flatten().fieldErrors;
  }

  // check if passwords match
  if (submittedData.password !== formData.get("password_confirm")) {
    errors.password_confirm = ["Passwords must match!"];
  }

  // If there are any errors, return the errors
  if (!isObjectEmpty(errors)) {
    return {
      errors,
      data: submittedData,
    };
  }

  // hash password with bcrypt
  const password_hash = await bcrypt.hash(submittedData.password, 10);

  // create PostgreSQL insert statement
  const insertSql: string = `
    INSERT INTO
    admin.users (username, email, first_name, last_name, password_hash)
    VALUES
    ($1, $2, $3, $4, $5)
    RETURNING
      user_id,
      user_role,
      username,
      first_name,
      last_name,
      img
    `;

  // run PostgreSql query with pg
  const insertResult: ResultProps<UserData> = await db
    .query(insertSql, [
      submittedData.username,
      submittedData.email,
      submittedData.first_name,
      submittedData.last_name,
      password_hash,
    ])
    .then((res) => {
      return { message: `Sign up successful!`, status: 200, data: res.rows[0] };
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

  // If insert was a success, it will return data
  if (insertResult.data) {
    const { user_id, user_role, username, first_name, last_name, img } =
      insertResult.data;

    // create user session
    await createSession({
      user_id,
      user_role,
      username,
      first_name,
      last_name,
      img,
    });

    // redirect user
    redirect(`/dashboard/`);
  }

  // if it failed, return message and status
  return {
    ...insertResult,
    data: submittedData,
  };
}

type UserSignInData = UserSessionData & {
  password_hash: string;
};

export async function signIn(state: UserFormState, formData: FormData) {
  const identifier = formData.get("identifier") as string;
  const password = formData.get("password") as string;

  if (!identifier || !password) return;

  // Get user data from database based on identifier, select user_id, user_role, and password_hash
  const selectSql = `
    SELECT
      user_id,
      user_role,
      username,
      first_name,
      last_name,
      img,
      password_hash
    FROM
      admin.users
    WHERE
      username=$1 OR email=$1
  `;

  const selectResult: ResultProps<UserSignInData> = await db
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
    const {
      user_id,
      user_role,
      username,
      first_name,
      last_name,
      password_hash,
      img,
    } = selectResult.data;

    if (!password_hash) {
      return {
        message: "Username or password was incorrect",
        status: 401,
        data: {
          identifier,
        },
      };
    }

    // compare provided password with password_hash from db
    const passwordsMatch = await bcrypt.compare(password, password_hash);

    // if passwords don't match, return result for front end alert
    if (!passwordsMatch)
      return {
        message: "Username or password was incorrect",
        status: 401,
        data: {
          identifier,
        },
      };

    // create user session
    await createSession({
      user_id,
      user_role,
      username,
      first_name,
      last_name,
      img,
    });

    // redirect user
    redirect(`/dashboard/`);
  }

  // user not found, return result for front end alerts
  return {
    ...selectResult,
    data: {
      identifier,
    },
  };
}

export async function logOut() {
  // remove the session
  (await cookies()).set("session", "", { expires: new Date(0) });
  redirect("/sign-in");
}
