import { getDivision } from "@/actions/divisions";
import { getLeagueInfoForGames, getGame } from "@/actions/games";
import { canEditLeague } from "@/actions/leagues";
import EditGame from "@/components/dashboard/games/EditGame";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { notFound, redirect } from "next/navigation";

export default async function Page({
  params,
}: {
  params: Promise<{
    division: string;
    season: string;
    league: string;
    game_id: number;
  }>;
}) {
  const { division, season, league, game_id } = await params;

  const { data: divisionData } = await getDivision(division, season, league);

  if (!divisionData) notFound();

  const { canEdit } = await canEditLeague(league);

  const backLink = createDashboardUrl({
    l: league,
    s: season,
    d: division,
    g: game_id,
  });

  if (!canEdit) redirect(backLink);

  const { data: addGameData } = await getLeagueInfoForGames(
    division,
    season,
    league,
  );

  const { data: gameData } = await getGame(game_id);

  return (
    <>
      <h3 className="push">Edit game</h3>
      {addGameData && gameData ? (
        <EditGame
          addGameData={addGameData}
          gameData={gameData}
          league_id={divisionData.league_id}
          game_id={gameData.game_id}
          backLink={backLink}
        />
      ) : (
        <p>There was a problem loading the data needed to edit this game.</p>
      )}
    </>
  );
}
