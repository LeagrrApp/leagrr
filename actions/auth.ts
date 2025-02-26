"use server";

import { db } from "@/db/pg";
import { createSession } from "@/lib/session";
import { isObjectEmpty } from "@/utils/helpers/objects";
import bcrypt from "bcrypt";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";
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

  // initialize errors
  let errors: UserErrorProps = {};

  // initialize success check
  let success = false;

  try {
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
      throw new Error("There were problems with submitted data.");
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
    const { rows: insertRows } = await db.query<UserData>(insertSql, [
      submittedData.username,
      submittedData.email,
      submittedData.first_name,
      submittedData.last_name,
      password_hash,
    ]);

    if (!insertRows[0])
      throw new Error("There was a problem creating new user, try again.");

    // If insert was a success, it will return data
    const { user_id, user_role, username, first_name, last_name, img } =
      insertRows[0];

    // create user session
    await createSession({
      user_id,
      user_role,
      username,
      first_name,
      last_name,
      img,
    });

    success = true;
  } catch (err) {
    if (err instanceof Error) {
      return {
        message: err.message,
        status: 400,
        errors,
        data: submittedData,
      };
    }
    return {
      message: "Something went wrong.",
      status: 500,
      errors,
      data: submittedData,
    };
  }

  if (success)
    // redirect user
    redirect(`/dashboard/`);
}

type UserSignInData = UserSessionData & {
  password_hash: string;
};

type SignInFormState = FormState<
  { identifier: string[] | undefined },
  { identifier: string; password?: string }
>;

export async function signIn(
  state: SignInFormState,
  formData: FormData,
): Promise<SignInFormState> {
  const identifier = formData.get("identifier") as string;
  const password = formData.get("password") as string;

  if (!identifier || !password) return;

  // initialize result status code
  let status = 400;

  // initialize success check
  let success = false;

  try {
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

    const { rows } = await db.query<UserSignInData>(selectSql, [identifier]);

    if (!rows[0]) {
      status = 401;
      throw new Error("Username or password was incorrect.");
    }

    const {
      user_id,
      user_role,
      username,
      first_name,
      last_name,
      password_hash,
      img,
    } = rows[0];

    if (!password_hash) {
      status = 401;
      throw new Error("Username or password was incorrect");
    }

    // compare provided password with password_hash from db
    const passwordsMatch = await bcrypt.compare(password, password_hash);

    // if passwords don't match, return result for front end alert
    if (!passwordsMatch) {
      status = 401;
      throw new Error("Username or password was incorrect");
    }

    // create user session
    await createSession({
      user_id,
      user_role,
      username,
      first_name,
      last_name,
      img,
    });

    success = true;
  } catch (err) {
    if (err instanceof Error) {
      return {
        ...state,
        message: err.message,
        status,
        data: {
          identifier,
          password,
        },
      };
    }
    return {
      ...state,
      message: "Something went wrong.",
      status: 500,
      data: {
        identifier,
        password,
      },
    };
  }
  // redirect user
  if (success) redirect(`/dashboard/`);
}

export async function logOut() {
  // remove the session
  (await cookies()).set("session", "", { expires: new Date(0) });
  redirect("/sign-in");
}
