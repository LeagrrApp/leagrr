import { getDivision, getDivisionOptionsForGames } from "@/actions/divisions";
import { getGame, getGameMetaInfo } from "@/actions/games";
import { canEditLeague } from "@/actions/leagues";
import EditGame from "@/components/dashboard/games/EditGame";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { notFound, redirect } from "next/navigation";

interface PageProps {
  params: Promise<{
    division: string;
    season: string;
    league: string;
    game_id: number;
  }>;
}

export async function generateMetadata({ params }: PageProps) {
  const { game_id } = await params;

  const { data: gameData } = await getGame(game_id);

  if (!gameData) return null;

  const { data: gameMetaData } = await getGameMetaInfo(game_id, {
    prefix: "Edit",
  });

  return gameMetaData;
}

export default async function Page({ params }: PageProps) {
  const { division, season, league, game_id } = await params;

  const { data: divisionData } = await getDivision(division, season, league);

  if (!divisionData) notFound();

  const { canEdit } = await canEditLeague(divisionData.league_id);

  const backLink = createDashboardUrl({
    l: league,
    s: season,
    d: division,
    g: game_id,
  });

  if (!canEdit) redirect(backLink);

  const { data: addGameData } = await getDivisionOptionsForGames(
    divisionData.division_id,
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
