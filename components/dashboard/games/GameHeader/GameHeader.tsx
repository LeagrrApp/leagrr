import Card from "@/components/ui/Card/Card";
import css from "./gameHeader.module.css";
import { apply_classes } from "@/utils/helpers/html-attributes";
import Button from "@/components/ui/Button/Button";
import GameScoreInput from "./GameScoreInput/GameScoreInput";
import Link from "next/link";
import { createDashboardUrl } from "@/utils/helpers/formatting";

interface GameHeaderProps {
  game: GameData;
  canEdit: boolean;
}

export default function GameHeader({ game, canEdit }: GameHeaderProps) {
  const gameDateTime = new Date(game.date_time);

  const gameDate = gameDateTime.toLocaleString("en-CA", {
    weekday: "short",
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  });

  const gameCompleted = game.status === "completed";

  return (
    <Card className={css.game_header_card} padding="base">
      <header className={css.game_header}>
        <div
          className={apply_classes(
            [css.game_header_team_info, css.game_header_team_info_away],
            gameCompleted && game.away_team_score > game.home_team_score
              ? css.game_header_team_info_winner
              : undefined
          )}
        >
          <div className={css.game_header_team_wrap}>
            <h3 className={css.game_header_team}>
              <Link href={createDashboardUrl({ t: game.away_team_slug })}>
                {game.away_team}
              </Link>
            </h3>
            {gameCompleted && (
              <p className={css.game_header_sog}>
                <span className="srt">Away team shots on goal:</span>
                <span aria-hidden="true">SOG: </span>
                {game.away_team_shots}
              </p>
            )}
          </div>
          <p className={css.game_header_team_score}>{game.away_team_score}</p>
        </div>
        <div className={css.game_header_info}>
          <time
            className={css.game_header_date_time}
            dateTime={game.date_time as string}
          >
            {gameDate}
          </time>
          <p>{game.venue}</p>
          {canEdit && <GameScoreInput game={game} />}
        </div>

        <div
          className={apply_classes(
            [css.game_header_team_info, css.game_header_team_info_home],
            gameCompleted && game.home_team_score > game.away_team_score
              ? css.game_header_team_info_winner
              : undefined
          )}
        >
          <div className={css.game_header_team_wrap}>
            <h3 className={css.game_header_team}>
              <Link href={createDashboardUrl({ t: game.home_team_slug })}>
                {game.home_team}
              </Link>
            </h3>
            {gameCompleted && (
              <p className={css.game_header_sog}>
                <span className="srt">Home team shots on goal:</span>
                <span aria-hidden="true">SOG: </span>
                {game.home_team_shots}
              </p>
            )}
          </div>
          <p className={css.game_header_team_score}>{game.home_team_score}</p>
        </div>
      </header>
    </Card>
  );
}
