import { getLeagues } from "@/actions/leagues";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);

  const page = parseInt(searchParams.get("page") || "1");
  const perPage = parseInt(searchParams.get("perPage") || "25");
  let sport: string | undefined = searchParams.get("sport") || undefined;
  let status: string | null | undefined = searchParams.get("status");
  const search = searchParams.get("search");

  if (sport === "all") sport = undefined;
  if (status === "all") status = undefined;

  const result = await getLeagues({
    limit: perPage,
    offset: perPage * (page - 1),
    search: search || undefined,
    sport: sport || undefined,
    status: status || undefined,
  });

  return Response.json(result);
}
