import { getDivision, getDivisionOptionsForGames } from "@/actions/divisions";
import {
  canEditGame,
  deleteGame,
  getGame,
  getGameMetaInfo,
} from "@/actions/games";
import EditGame from "@/components/dashboard/games/EditGame";
import ModalConfirmAction from "@/components/dashboard/ModalConfirmAction/ModalConfirmAction";
import BackButton from "@/components/ui/BackButton/BackButton";
import Grid from "@/components/ui/layout/Grid";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { notFound, redirect } from "next/navigation";

interface PageProps {
  params: Promise<{
    division: string;
    season: string;
    league: string;
    game_id: string;
  }>;
}

export async function generateMetadata({ params }: PageProps) {
  const { game_id: game_id_string } = await params;

  const game_id = parseInt(game_id_string);

  const { data: gameData } = await getGame(game_id);

  if (!gameData) return null;

  const { data: gameMetaData } = await getGameMetaInfo(game_id, {
    prefix: "Edit",
  });

  return gameMetaData;
}

export default async function Page({ params }: PageProps) {
  const { division, season, league, game_id: game_id_string } = await params;

  const game_id = parseInt(game_id_string);

  const { data: divisionData } = await getDivision(division, season, league);

  if (!divisionData) notFound();

  const { canEdit } = await canEditGame(game_id);

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
      <BackButton href={backLink} label="Back to game" />
      <h3 className="push">Edit game</h3>
      <Grid gap="base">
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
        <ModalConfirmAction
          defaultState={{
            data: {
              game_id,
            },
            link: createDashboardUrl({
              l: league,
              s: season,
              d: division,
            }),
          }}
          actionFunction={deleteGame}
          confirmationHeading={`Are you sure you want to delete this game?`}
          confirmationByline={`This action is permanent cannot be undone. Consider setting the game's status to "Archived" instead.`}
          trigger={{
            icon: "delete",
            label: "Delete Game",
            buttonStyles: {
              variant: "danger",
              fullWidth: true,
            },
          }}
        />
      </Grid>
    </>
  );
}
