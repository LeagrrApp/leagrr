import { getDivisions } from "@/actions/divisions";
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

  console.log(data);

  if (!data) notFound();

  return (
    <Container>
      <h2>{data.name}</h2>
    </Container>
  );
}
