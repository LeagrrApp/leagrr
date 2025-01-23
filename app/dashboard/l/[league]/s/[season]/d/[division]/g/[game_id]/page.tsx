import { getGame } from "@/actions/games";

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

  const { data: gameData } = await getGame(game_id);

  console.log(gameData);

  return (
    <>
      <h3>Game</h3>
    </>
  );
}
