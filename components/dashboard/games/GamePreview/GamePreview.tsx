import Badge from "@/components/ui/Badge/Badge";
import Card from "@/components/ui/Card/Card";
import InitialsCircle from "@/components/ui/InitialsCircle/InitialsCircle";
import {
  applyAppropriateTextColor,
  createDashboardUrl,
} from "@/utils/helpers/formatting";
import { apply_classes_conditional } from "@/utils/helpers/html-attributes";
import Link from "next/link";
import { CSSProperties } from "react";
import css from "./gamePreview.module.css";

interface GamePreviewProps {
  game: GameData;
  currentTeam?: number;
}

interface GameStyles extends CSSProperties {
  "--color-home": string;
  "--color-away": string;
}

export default function GamePreview({ game, currentTeam }: GamePreviewProps) {
  const {
    home_team,
    home_team_id,
    home_team_slug,
    home_team_color,
    home_team_score,
    home_team_shots,
    away_team,
    away_team_id,
    away_team_slug,
    away_team_color,
    away_team_score,
    away_team_shots,
    date_time,
    venue,
    arena,
    status,
  } = game;

  const gameDate = date_time.toLocaleString("en-CA", {
    weekday: "short",
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  });

  const gameCompleted = status === "completed";

  const showStatus = status !== "public" && status !== "completed";
  let statusColor: ColorOptions = "grey";

  switch (status) {
    case "cancelled":
      statusColor = "danger";
      break;
    case "archived":
      statusColor = "caution";
      break;
    case "postponed":
      statusColor = "warning";
      break;
    default:
      break;
  }

  const styles: GameStyles = {
    "--color-home": home_team_color || "",
    "--color-away": away_team_color || "",
  };

  const isHomeTeam = currentTeam === home_team_id;
  const isAwayTeam = currentTeam === away_team_id;

  let winner = "none";
  if (home_team_score < away_team_score) winner = "away";
  if (home_team_score > away_team_score) winner = "home";

  let highlightClass = "";
  if (
    !currentTeam ||
    (winner === "home" && isHomeTeam) ||
    (winner === "away" && isAwayTeam)
  )
    highlightClass = css.game_preview_win;
  if ((winner === "away" && isHomeTeam) || (winner === "home" && isAwayTeam))
    highlightClass = css.game_preview_loss;

  return (
    <Card className={css.game_preview_card}>
      <section style={styles} className={css.game_preview}>
        <div
          className={apply_classes_conditional(
            [css.game_preview_team_info, css.game_preview_team_info_away],
            highlightClass,
            winner === "away" && status === "completed",
          )}
        >
          <div className={css.game_preview_team_wrap}>
            <InitialsCircle
              label={away_team}
              initialsStyle="first_word"
              hideLabel
              fontSize="h3"
              color={{
                bg: away_team_color,
                text: applyAppropriateTextColor(away_team_color),
                border: away_team_color === "white" ? "grey" : away_team_color,
              }}
            />
            <div>
              <h3 className={css.game_preview_team}>
                <Link href={createDashboardUrl({ t: away_team_slug })}>
                  {away_team}
                </Link>
              </h3>
              <p className={css.game_preview_sog}>
                <span className="srt">Away team shots on goal:</span>
                <span aria-hidden="true">SOG: </span>
                {away_team_shots}
              </p>
            </div>
          </div>
          <p className={css.game_preview_team_score}>{away_team_score}</p>
        </div>
        <div className={css.game_preview_info}>
          <time
            className={css.game_preview_date_time}
            dateTime={date_time.toISOString()}
          >
            {gameDate}
          </time>
          <p>
            {arena} - {venue}
          </p>
          {showStatus && <Badge text={status} type={statusColor} />}
        </div>

        <div
          className={apply_classes_conditional(
            [css.game_preview_team_info, css.game_preview_team_info_home],
            highlightClass,
            winner === "home" && status === "completed",
          )}
        >
          <div className={css.game_preview_team_wrap}>
            <InitialsCircle
              label={home_team}
              initialsStyle="first_word"
              hideLabel
              fontSize="h3"
              color={{
                bg: home_team_color,
                text: applyAppropriateTextColor(home_team_color),
                border: home_team_color === "white" ? "grey" : home_team_color,
              }}
            />
            <div>
              <h3 className={css.game_preview_team}>
                <Link href={createDashboardUrl({ t: home_team_slug })}>
                  {home_team}
                </Link>
              </h3>
              <p className={css.game_preview_sog}>
                <span className="srt">Home team shots on goal:</span>
                <span aria-hidden="true">SOG: </span>
                {home_team_shots}
              </p>
            </div>
          </div>
          <p className={css.game_preview_team_score}>{home_team_score}</p>
        </div>
      </section>
    </Card>
  );
}
