import { getUsers } from "@/actions/users";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);

  const page = parseInt(searchParams.get("page") || "1");
  const perPage = parseInt(searchParams.get("perPage") || "25");
  const user_role = parseInt(searchParams.get("user_role") || "0");
  let status: string | null | undefined = searchParams.get("status");
  const search = searchParams.get("search");

  if (status === "all") status = undefined;

  const result = await getUsers({
    limit: perPage,
    offset: perPage * (page - 1),
    search: search || undefined,
    user_role: user_role !== 0 ? user_role : undefined,
    status: status || undefined,
  });

  return Response.json(result);
}
