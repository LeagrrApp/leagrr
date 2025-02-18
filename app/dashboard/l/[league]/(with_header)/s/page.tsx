import { getLeague, getLeagueMetaData } from "@/actions/leagues";
import CreateSeason from "@/components/dashboard/seasons/CreateSeason";
import Container from "@/components/ui/Container/Container";
import { verifySession } from "@/lib/session";
import { notFound } from "next/navigation";

type PageProps = {
  params: Promise<{ league: string }>;
};

export async function generateMetadata({ params }: PageProps) {
  const { league } = await params;

  const { data: leagueMetaData } = await getLeagueMetaData(league, {
    prefix: "Create Season",
  });

  return leagueMetaData;
}

export default async function Page({ params }: PageProps) {
  await verifySession();

  const { league: slug } = await params;

  const { data: league } = await getLeague(slug);

  if (!league) notFound();

  return (
    <Container>
      <h2 className="push">New Season</h2>
      <CreateSeason league_id={league.league_id} />
    </Container>
  );
}
