import { getGame } from "@/actions/games";
import { canEditLeague } from "@/actions/leagues";
import GameHeader from "@/components/dashboard/games/GameHeader/GameHeader";
import GameTeamStats from "@/components/dashboard/games/GameTeamStats/GameTeamStats";
import Icon from "@/components/ui/Icon/Icon";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { notFound } from "next/navigation";
import css from "./page.module.css";
import GameFeed from "@/components/dashboard/games/GameFeed/GameFeed";

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

  if (!gameData) notFound();

  // console.log(gameData);

  const backLink = createDashboardUrl({ l: league, s: season, d: division });

  const { canEdit } = await canEditLeague(league);

  const homeTeam = {
    team_id: gameData.home_team_id,
    name: gameData.home_team,
    slug: gameData.home_team_slug,
    score: gameData.home_team_score,
  };

  const awayTeam = {
    team_id: gameData.away_team_id,
    name: gameData.away_team,
    slug: gameData.away_team_slug,
    score: gameData.away_team_score,
  };

  return (
    <>
      <Icon
        className="push"
        href={backLink}
        icon="chevron_left"
        label="Return to division"
      />

      <article className={css.game}>
        <GameHeader game={gameData} canEdit={canEdit} />
        <GameTeamStats game={gameData} team={awayTeam} />
        <GameTeamStats game={gameData} team={homeTeam} isHome />
        <GameFeed game={gameData} />
      </article>
    </>
  );
}
