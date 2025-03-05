import { getLeagueIdFromSlug, getLeagueMetaData } from "@/actions/leagues";
import CreateSeason from "@/components/dashboard/seasons/CreateSeason";
import Card from "@/components/ui/Card/Card";
import Container from "@/components/ui/Container/Container";
import { verifySession } from "@/lib/session";
import { createDashboardUrl } from "@/utils/helpers/formatting";
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

  const { league } = await params;

  const { data } = await getLeagueIdFromSlug(league);

  if (!data) notFound();

  const backLink = createDashboardUrl({ l: league });

  return (
    <Container>
      <Card padding="l">
        <h2 className="push">New Season</h2>
        <CreateSeason league_id={data.league_id} backLink={backLink} />
      </Card>
    </Container>
  );
}
