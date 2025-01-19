import { getSeason } from "@/actions/seasons";
import Container from "@/components/ui/Container/Container";
import { notFound } from "next/navigation";

export default async function Page({
  params,
}: {
  params: Promise<{ season: string; league: string }>;
}) {
  const { season, league } = await params;

  const { data } = await getSeason(season, league, true);

  if (!data) notFound();

  return (
    <Container>
      <h2>Team Page</h2>
    </Container>
  );
}
