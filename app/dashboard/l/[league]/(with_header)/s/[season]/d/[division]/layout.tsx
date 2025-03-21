import { getDivision } from "@/actions/divisions";
import { canEditLeague } from "@/actions/leagues";
import { getSeason } from "@/actions/seasons";
import DivisionHeader from "@/components/dashboard/divisions/DivisionHeader/DivisionHeader";
import Container from "@/components/ui/Container/Container";
import { notFound } from "next/navigation";
import { PropsWithChildren } from "react";

export default async function Layout({
  children,
  params,
}: PropsWithChildren<{
  params: Promise<{
    division: string;
    season: string;
    league: string;
    game_id: string;
  }>;
}>) {
  const { division, season, league } = await params;

  const { data: seasonData } = await getSeason(season, league, {
    includeDivisions: true,
  });
  const { data: divisionData } = await getDivision(division, season, league);

  if (!seasonData || !divisionData) notFound();

  // check to see if user can edit this league
  const { canEdit } = await canEditLeague(seasonData.league_id);

  return (
    <Container>
      {/* {seasonData.divisions && seasonData.divisions.length !== 0 && (
        <DivisionTabs divisions={seasonData.divisions} canAdd={canEdit} />
      )} */}

      <DivisionHeader
        divisions={seasonData.divisions}
        division={divisionData}
        canEdit={canEdit}
      />
      {children}
    </Container>
  );
}
