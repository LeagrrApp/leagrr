import { getTeams } from "@/actions/teams";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);

  const page = parseInt(searchParams.get("page") || "1");
  const perPage = parseInt(searchParams.get("perPage") || "25");
  let status: string | null | undefined = searchParams.get("status");
  const search = searchParams.get("search");

  if (status === "all") status = undefined;

  const result = await getTeams({
    limit: perPage,
    offset: perPage * (page - 1),
    search: search || undefined,
    status: status || undefined,
  });

  return Response.json(result);
}
