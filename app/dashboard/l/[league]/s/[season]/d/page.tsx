import { getDivisions } from "@/actions/divisions";
import { getLeagueData } from "@/actions/leagues";
import { getSeason } from "@/actions/seasons";
import CreateDivision from "@/components/dashboard/divisions/CreateDivision";
import Container from "@/components/ui/Container/Container";
import { verifySession } from "@/lib/session";
import { notFound } from "next/navigation";

export default async function Page({
  params,
}: {
  params: Promise<{ league: string; season: string }>;
}) {
  await verifySession();

  const { league, season } = await params;

  const { data: seasonData } = await getSeason(season, league);

  if (!seasonData) notFound();

  return (
    <Container>
      <h2 className="push">New division</h2>
      <CreateDivision season_id={seasonData?.season_id} />
    </Container>
  );
}
