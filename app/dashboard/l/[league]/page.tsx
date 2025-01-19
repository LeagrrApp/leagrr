import { getLeagueData } from "@/actions/leagues";
import Button from "@/components/ui/Button/Button";
import Container from "@/components/ui/Container/Container";
import { notFound, redirect } from "next/navigation";

export default async function Page({
  params,
}: {
  params: Promise<{ league: string }>;
}) {
  const { league: slug } = await params;

  const { data: league } = await getLeagueData(slug);

  if (!league) notFound();

  if (league.seasons && league.seasons.length > 0) {
    // redirect to first season that has a start_date before today and an end_date after today.
    const currentSeasons = league.seasons.filter((s) => {
      if (!s.start_date || !s.end_date) {
        return;
      }

      const now = new Date(Date.now());
      const start_date = new Date(s.start_date);
      const end_date = new Date(s.end_date);
      return start_date < now && now < end_date;
    });

    if (currentSeasons[0])
      redirect(`/dashboard/l/${slug}/s/${currentSeasons[0].slug}`);

    redirect(`/dashboard/l/${slug}/s/${league.seasons[0].slug}`);
  }

  return (
    <Container>
      <h2>It looks like this league doesn't have any seasons yet...</h2>
      <Button href={`./${slug}/s/`}>Add Season</Button>
    </Container>
  );
}
