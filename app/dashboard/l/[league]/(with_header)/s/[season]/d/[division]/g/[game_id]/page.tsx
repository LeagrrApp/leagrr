import { getGame, getGameMetaInfo } from "@/actions/games";
import { canEditLeague } from "@/actions/leagues";
import GameControls from "@/components/dashboard/games/GameControls/GameControls";
import GameFeed from "@/components/dashboard/games/GameFeed/GameFeed";
import GamePreview from "@/components/dashboard/games/GamePreview/GamePreview";
import GameTeamStats from "@/components/dashboard/games/GameTeamStats/GameTeamStats";
import Icon from "@/components/ui/Icon/Icon";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { notFound } from "next/navigation";
import { CSSProperties } from "react";
import css from "./page.module.css";
import { apply_classes_conditional } from "@/utils/helpers/html-attributes";
import BackButton from "@/components/ui/BackButton/BackButton";

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

  const { data: gameMetaData } = await getGameMetaInfo(game_id);

  return gameMetaData;
}

interface GameStyles extends CSSProperties {
  "--color-home": string;
  "--color-away": string;
}

export default async function Page({ params }: PageProps) {
  const { division, season, league, game_id } = await params;

  const { data: gameData } = await getGame(game_id);

  if (!gameData) notFound();

  const backLink = createDashboardUrl({ l: league, s: season, d: division });
  const gameLink = createDashboardUrl({
    l: league,
    s: season,
    d: division,
    g: game_id,
  });

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

  const styles: GameStyles = {
    "--color-home": gameData.home_team_color || "",
    "--color-away": gameData.away_team_color || "",
  };

  return (
    <>
      <BackButton label="Back to division" href={backLink} />

      <article
        style={styles}
        className={apply_classes_conditional(
          css.game,
          css.game_can_edit,
          canEdit,
        )}
      >
        {canEdit && <GameControls game={gameData} />}
        <GamePreview game={gameData} />
        <GameTeamStats game={gameData} team={awayTeam} />
        <GameTeamStats game={gameData} team={homeTeam} isHome />
        <GameFeed game={gameData} canEdit={canEdit} backLink={gameLink} />
      </article>
    </>
  );
}
