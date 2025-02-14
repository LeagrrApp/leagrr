import { getDivision, getDivisionMetaInfo } from "@/actions/divisions";
import { getUserManagedTeamsForJoinDivision } from "@/actions/users";
import JoinDivision from "@/components/dashboard/divisions/JoinDivision/JoinDivision";
import Container from "@/components/ui/Container/Container";
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

  if (!divisionData) notFound();

  const { data: teams } = await getUserManagedTeamsForJoinDivision(
    divisionData.division_id,
  );

  const backLink = createDashboardUrl({ l: league, s: season, d: division });

  if (!teams || teams.length < 1) {
    return (
      <Container maxWidth="35rem">
        <h1>Sorry</h1>
        <p>
          You don&apos;t manage any teams or all of the teams you manage are
          already assigned to this division.
        </p>
      </Container>
    );
  }

  return (
    <JoinDivision division={divisionData} teams={teams} backLink={backLink} />
  );
}
