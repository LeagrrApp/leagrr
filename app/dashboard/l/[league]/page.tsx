import { getLeagueData } from "@/actions/leagues";
import Button from "@/components/ui/Button/Button";
import Container from "@/components/ui/Container/Container";
import { redirect } from "next/navigation";

export default async function Page({
  params,
}: {
  params: Promise<{ league: string }>;
}) {
  const { league: slug } = await params;

  const { data: league } = await getLeagueData(slug);

  if (!league) return null;

  if (league.seasons && league.seasons.length > 0) {
    // redirect to first season
    redirect(`/dashboard/l/${slug}/s/${league.seasons[0].slug}`);
  }

  return (
    <Container>
      <h2>It looks like this league doesn't have any seasons yet...</h2>
      <Button href={`./${slug}/s/`}>Add Season</Button>
    </Container>
  );
}
