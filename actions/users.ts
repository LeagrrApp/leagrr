"use server";

import { db } from "@/db/pg";

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
      r.name AS role
    FROM
      admin.users AS u
    RIGHT JOIN
      admin.user_roles AS r
    ON
      u.user_role = r.user_role_id
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
