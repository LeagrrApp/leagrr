import { NextRequest } from "next/server";
import bcrypt from "bcrypt";
import { db } from "@/db/pg";

export async function GET(request: NextRequest) {
  const sql = `
    SELECT
      first_name,
      last_name,
      username,
      email,
      pronouns
    FROM
      admin.users
    ORDER BY
      user_id ASC
    LIMIT 20
  `;

  const { rows, rowCount } = await db.query(sql);

  return Response.json({ data: { userCount: rowCount, users: rows } });
}

export async function POST(request: NextRequest) {
  // Get values from the request body
  const { username, email, first_name, last_name, password } =
    await request.json();

  // hash password with bcrypt
  const password_hash = await bcrypt.hash(password, 10);

  // create PostgreSQL insert statement
  const sql: string = `
  INSERT INTO
  admin.users (username, email, first_name, last_name, password_hash)
  VALUES
  ($1, $2, $3, $4, $5)
  `;

  // run PostgreSQL query with pg
  const { message, status } = await db
    .query(sql, [username, email, first_name, last_name, password_hash])
    .then(() => {
      return { message: `Sign up successful!`, status: 200 };
    })
    .catch((err) => {
      console.log(err);

      // TODO: add proper error handling based on PostgreSQL error codes
      // handle user creation errors

      return {
        message: "There was a problem creating new user, try again.",
        status: 400,
      };
    });

  // sign user into session

  // return confirmation message
  return Response.json({ message }, { status });
}
