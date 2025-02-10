import { canEditLeague } from "@/actions/leagues";
import { getSeason } from "@/actions/seasons";
import DivisionTabs from "@/components/dashboard/divisions/DivisionTabs/DivisionTabs";
import Container from "@/components/ui/Container/Container";
import { notFound } from "next/navigation";
import { PropsWithChildren } from "react";
import css from "./layout.module.css";
import { getDivision } from "@/actions/divisions";
import DivisionHeader from "@/components/dashboard/divisions/DivisionHeader/DivisionHeader";

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
  const { division, season, league, game_id } = await params;

  const { data: seasonData } = await getSeason(season, league, true);
  const { data: divisionData } = await getDivision(division, season, league);

  if (!seasonData || !divisionData) notFound();

  // check to see if user can edit this league
  const { canEdit } = await canEditLeague(seasonData.league_id);

  return (
    <Container>
      {seasonData.divisions && seasonData.divisions.length !== 0 && (
        <DivisionTabs divisions={seasonData.divisions} canAdd={canEdit} />
      )}

      <div className={css.division}>
        <DivisionHeader division={divisionData} canEdit={canEdit} />
        {children}
      </div>
    </Container>
  );
}
