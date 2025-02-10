import { getDivision } from "@/actions/divisions";
import { getLeagueInfoForGames } from "@/actions/games";
import { canEditLeague } from "@/actions/leagues";
import CreateGame from "@/components/dashboard/games/CreateGame";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { notFound, redirect } from "next/navigation";

export default async function Page({
  params,
}: {
  params: Promise<{ division: string; season: string; league: string }>;
}) {
  const { division, season, league } = await params;

  const { data: divisionData } = await getDivision(division, season, league);

  if (!divisionData) notFound();

  const { canEdit } = await canEditLeague(league);

  const backLink = createDashboardUrl({ l: league, s: season, d: division });

  if (!canEdit) redirect(backLink);

  const { data: addGameData } = await getLeagueInfoForGames(
    division,
    season,
    league,
  );

  return (
    <>
      <h3 className="push">Add game</h3>
      {addGameData ? (
        <CreateGame
          addGameData={addGameData}
          league_id={divisionData.league_id}
          division_id={divisionData.division_id}
          backLink={backLink}
        />
      ) : (
        <p>There was a problem loading the data needed to create a game.</p>
      )}
    </>
  );
}
