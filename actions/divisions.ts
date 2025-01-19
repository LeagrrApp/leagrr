"use server";

import { db } from "@/db/pg";
import { verifySession } from "@/lib/session";

type DivisionErrorProps = {
  name?: string[] | undefined;
  description?: string[] | undefined;
  league_id?: string[] | undefined;
  start_date?: string[] | undefined;
  end_date?: string[] | undefined;
  status?: string[] | undefined;
};

type DivisionFormState =
  | {
      errors?: DivisionErrorProps;
      message?: string;
      status?: number;
    }
  | undefined;

export async function createDivision(
  state: DivisionFormState,
  formData: FormData
): Promise<DivisionFormState> {
  // check user is logged in
  await verifySession();

  return {
    message: "Testing create division",
    status: 200,
  };
}

export async function getDivisions(season_id: number) {
  // check user is logged in
  const { user_id } = await verifySession();

  // build sql select statement
  const sql = `
    SELECT
    name,
    description,
    slug,
    gender,
    tier,
    join_code,
    season_id,
    status
  FROM
    divisions
  WHERE
    season_id = $1
  ORDER BY
    gender ASC, tier ASC
  `;

  const result: ResultProps<DivisionData[]> = await db
    .query(sql, [season_id])
    .then((res) => {
      return {
        message: "Divisions data loaded",
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
