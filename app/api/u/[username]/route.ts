import { db } from "@/db/pg";
import { NextRequest } from "next/server";

interface GetResultProps extends ResultProps {
  data?: UserData;
}

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ username: string }> }
) {
  const searchParams = request.nextUrl.searchParams;
  const for_session = searchParams.get("for_session") === "true";
  const username = (await params).username;

  let columns: string[] = ["user_id", "user_role"];

  if (!for_session) {
    columns = [
      ...columns,
      "first_name",
      "last_name",
      "username",
      "email",
      "pronouns",
    ];
  }

  const sql = `
    SELECT
      ${columns.join(", ")}
    FROM
      admin.users
    WHERE
      username=$1
  `;

  const { message, status, data }: GetResultProps = await db
    .query(sql, [username])
    .then((res) => {
      if (!res.rowCount) {
        // no user found
        throw new Error("Sorry, user not found.");
      }
      // successfully found user
      return {
        message: for_session
          ? "User data for session retrieved."
          : "User data successfully retrieved",
        data: res.rows[0],
        status: 200,
      };
    })
    .catch((err) => {
      console.log(err);
      return {
        message: err.message,
        status: 400,
      };
    });

  return Response.json({ message, data, status });
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ username: string }> }
) {
  console.log(request);

  const username = (await params).username;

  const sql = `
    DELETE FROM
      admin.users
    WHERE
      username=$1
  `;

  const result = await db.query(sql, [username]);

  return Response.json(result);
}
