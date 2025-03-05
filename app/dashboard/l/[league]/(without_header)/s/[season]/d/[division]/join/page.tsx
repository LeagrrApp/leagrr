import { getDivision, getDivisionMetaInfo } from "@/actions/divisions";
import { getLeague } from "@/actions/leagues";
import { getUserManagedTeamsForJoinDivision } from "@/actions/users";
import JoinDivision from "@/components/dashboard/divisions/JoinDivision/JoinDivision";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { notFound } from "next/navigation";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ division: string; season: string; league: string }>;
}) {
  const { division, season, league } = await params;

  const { data: divisionMetaData } = await getDivisionMetaInfo(
    division,
    season,
    league,
  );

  return divisionMetaData;
}

export default async function Page({
  params,
}: {
  params: Promise<{ division: string; season: string; league: string }>;
}) {
  const { division, season, league } = await params;

  const { data: divisionData } = await getDivision(division, season, league);
  const { data: leagueData } = await getLeague(league);

  if (!divisionData) notFound();

  const { data: teams } = await getUserManagedTeamsForJoinDivision(
    divisionData.division_id,
  );

  const backLink = createDashboardUrl({ l: league, s: season, d: division });

  return (
    <JoinDivision
      division={divisionData}
      league={leagueData}
      teams={teams}
      backLink={backLink}
    />
  );
}
