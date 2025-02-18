import { getLeagueData, getLeagueMetaData } from "@/actions/leagues";
import Button from "@/components/ui/Button/Button";
import Container from "@/components/ui/Container/Container";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { notFound, redirect } from "next/navigation";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ league: string }>;
}) {
  const { league } = await params;

  const { data: leagueMetaData } = await getLeagueMetaData(league);

  console.log(leagueMetaData);

  if (leagueMetaData) return leagueMetaData;
}

export default async function Page({
  params,
}: {
  params: Promise<{ league: string }>;
}) {
  const { league } = await params;

  const { data: leagueData } = await getLeagueData(league);

  if (!leagueData) notFound();

  if (leagueData.seasons && leagueData.seasons.length > 0) {
    // redirect to first season that has a start_date before today and an end_date after today.
    const currentSeasons = leagueData.seasons.filter((s) => {
      if (!s.start_date || !s.end_date) {
        return false;
      }

      const now = new Date(Date.now());
      const start_date = new Date(s.start_date);
      const end_date = new Date(s.end_date);

      return start_date < now && now < end_date;
    });

    if (currentSeasons[0])
      redirect(
        createDashboardUrl({
          l: league,
          s: currentSeasons[0].slug,
        }),
      );

    redirect(
      createDashboardUrl({
        l: league,
        s: leagueData.seasons[0].slug,
      }),
    );
  }

  return (
    <Container>
      <h2>It looks like this league doesn&apos;t have any seasons yet...</h2>
      <Button href={`./${league}/s/`}>Add Season</Button>
    </Container>
  );
}
