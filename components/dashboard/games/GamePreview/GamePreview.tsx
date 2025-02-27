import { getGameUrl } from "@/actions/games";
import { getUserTeams } from "@/actions/users";
import Badge from "@/components/ui/Badge/Badge";
import Card from "@/components/ui/Card/Card";
import Indicator from "@/components/ui/Indicator/Indicator";
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
  includeGameLink?: boolean;
}

interface GameStyles extends CSSProperties {
  "--color-home": string;
  "--color-away": string;
}

export default async function GamePreview({
  game,
  currentTeam,
  includeGameLink,
}: GamePreviewProps) {
  const {
    division_id,
    game_id,
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

  const gameUrlResult = await getGameUrl(game_id);

  const { data: gameUrl } = gameUrlResult;

  const gameDate = date_time.toLocaleString("en-CA", {
    weekday: "short",
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  });

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

  let confirmedCurrentTeam = currentTeam;

  if (!confirmedCurrentTeam) {
    const { data: userTeams } = await getUserTeams();

    if (userTeams) {
      confirmedCurrentTeam = userTeams?.find(
        (t) =>
          t.team_id === game.away_team_id || t.team_id === game.home_team_id,
      )?.team_id;
    }
  }

  const isHomeTeam = confirmedCurrentTeam === home_team_id;
  const isAwayTeam = confirmedCurrentTeam === away_team_id;

  let winner = "none";
  if (home_team_score < away_team_score) winner = "away";
  if (home_team_score > away_team_score) winner = "home";

  let highlightClass = "";
  if (
    !confirmedCurrentTeam ||
    (winner === "home" && isHomeTeam) ||
    (winner === "away" && isAwayTeam)
  )
    highlightClass = css.game_preview_win;
  if ((winner === "away" && isHomeTeam) || (winner === "home" && isAwayTeam))
    highlightClass = css.game_preview_loss;

  return (
    <Card className={css.game_preview_card}>
      {includeGameLink && typeof gameUrl === "string" && (
        <Link className={css.game_preview_link} href={gameUrl}>
          <span className="srt">
            View game between {away_team} and {home_team} taking place{" "}
            {date_time.toLocaleString("en-CA", {
              weekday: "long",
              month: "long",
              day: "numeric",
              hour: "numeric",
              minute: "2-digit",
            })}{" "}
            at {venue} arena {arena}.
          </span>
        </Link>
      )}
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
                <Link
                  href={createDashboardUrl({
                    t: away_team_slug,
                    d: division_id,
                  })}
                >
                  {away_team}
                </Link>
                {isAwayTeam && <Indicator />}
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
                <Link
                  href={createDashboardUrl({
                    t: home_team_slug,
                    d: division_id,
                  })}
                >
                  {home_team}
                </Link>
                {isHomeTeam && <Indicator />}
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
