import { getLeagueData } from "@/actions/leagues";
import CreateSeason from "@/components/dashboard/seasons/CreateSeason";
import Container from "@/components/ui/Container/Container";
import { verifySession } from "@/lib/session";
import { notFound } from "next/navigation";

export default async function Page({
  params,
}: {
  params: Promise<{ league: string }>;
}) {
  await verifySession();

  const { league: slug } = await params;

  const { data: league } = await getLeagueData(slug);

  if (!league) notFound();

  return (
    <Container>
      <h2 className="push">New Season</h2>
      <CreateSeason league_id={league.league_id} />
    </Container>
  );
}
