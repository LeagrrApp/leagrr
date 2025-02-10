import endGame, { getGameFeed, getGameTeamRosters } from "@/actions/games";
import Card from "@/components/ui/Card/Card";
import Icon from "@/components/ui/Icon/Icon";
import Grid from "@/components/ui/layout/Grid";
import ModalConfirmAction from "../../ModalConfirmAction/ModalConfirmAction";
import GameFeedAdd from "../GameFeedAdd/GameFeedAdd";
import css from "./gameFeed.module.css";
import GameFeedItem from "./GameFeedItem";
import { addNumberOrdinals } from "@/utils/helpers/formatting";
import { apply_classes } from "@/utils/helpers/html-attributes";

interface GameFeedProps {
  game: GameData;
  canEdit: boolean;
  backLink: string;
}

export default async function GameFeed({
  game,
  canEdit,
  backLink,
}: GameFeedProps) {
  const { data: gameFeed } = await getGameFeed(game.game_id);

  const { data: teamRosters } = await getGameTeamRosters(
    game.away_team_id,
    game.home_team_id,
    game.division_id,
  );

  if (
    !teamRosters ||
    teamRosters.away_roster.length === 0 ||
    teamRosters.home_roster.length === 0
  )
    return null;

  const currentTime = {
    period: 1,
    minutes: 0,
    seconds: 0,
  };

  if (
    !gameFeed ||
    (gameFeed?.period1?.length < 1 &&
      gameFeed?.period2?.length < 1 &&
      gameFeed?.period3?.length < 1)
  ) {
    return (
      <div className={css.game_feed}>
        <h3>Game Feed</h3>
        <Card className={css.game_feed} padding="ml">
          {canEdit ? (
            <GameFeedAdd
              game={game}
              canEdit={canEdit}
              teamRosters={teamRosters}
              currentTime={currentTime}
            />
          ) : (
            <p>There are no items in this game feed yet.</p>
          )}
        </Card>
      </div>
    );
  }

  const periods: string[] = Object.keys(gameFeed);

  periods.forEach((p) => {
    if (gameFeed[p].length) {
      const lastItem = gameFeed[p][gameFeed[p].length - 1];
      if (lastItem.period > currentTime.period) {
        currentTime.period = lastItem.period || 0;
        currentTime.minutes = lastItem.period_time.minutes || 0;
        currentTime.seconds = lastItem.period_time.seconds + 1 || 0;
      }
      if (lastItem.period_time.minutes > currentTime.minutes) {
        currentTime.minutes = lastItem.period_time.minutes || 0;
        currentTime.seconds = lastItem.period_time.seconds + 1 || 0;
      }
      if (lastItem.period_time.seconds > currentTime.seconds) {
        currentTime.seconds = lastItem.period_time.seconds + 1 || 0;
      }
    }
  });

  let running_away_team_score = 0;
  let running_home_team_score = 0;

  let game_end_highlight_class = css.tie_game;

  if (game.home_team_score > game.away_team_score)
    game_end_highlight_class = css.home_team_win;
  if (game.home_team_score < game.away_team_score)
    game_end_highlight_class = css.away_team_win;

  return (
    <section id="game-feed" className={css.game_feed}>
      <h3 className="push-ml type-scale-h4">Game Feed</h3>
      <Card padding="ml">
        <ol className={css.game_feed_periods}>
          {periods.map((p, i) => {
            // if this period is empty, but later periods are not,
            // return no events message
            let laterPeriodsHaveItems = false;
            periods.forEach((period, index) => {
              if (i < index && gameFeed[period].length > 0) {
                laterPeriodsHaveItems = true;
              }
            });
            // if this period is empty and so are periods after it, return null
            if (!laterPeriodsHaveItems && gameFeed[p].length === 0) return null;

            return (
              <li key={p} className={css.game_feed_period}>
                <h4 className={css.game_feed_period_heading}>
                  <Icon
                    icon="sports"
                    label={`Period ${i + 1}`}
                    gap="ml"
                    labelFirst
                  />
                </h4>
                {gameFeed[p].length >= 1 ? (
                  <ol className={css.game_feed_feed}>
                    {gameFeed[p].map((item: StatsData) => {
                      const isHome = game.home_team_id === item.team_id;

                      if (item.type === "stats.goals") {
                        if (item.team_id === game.home_team_id) {
                          running_home_team_score++;
                        } else {
                          running_away_team_score++;
                        }
                      }

                      return (
                        <GameFeedItem
                          key={`${item.type}-${item.period}-${item.period_time.minutes}-${item.period_time.seconds}`}
                          item={item}
                          isHome={isHome}
                          teamColor={
                            isHome ? game.home_team_color : game.away_team_color
                          }
                          canEdit={canEdit}
                          backLink={backLink}
                        />
                      );
                    })}
                  </ol>
                ) : (
                  <p>No events this period!</p>
                )}
                {i !== 2 && currentTime.period !== i + 1 && (
                  <div className={css.game_feed_summary}>
                    <h5>{addNumberOrdinals(i + 1)} Period Score</h5>
                    <p>
                      {game.away_team}{" "}
                      <strong>{running_away_team_score}</strong> —{" "}
                      <strong>{running_home_team_score}</strong>{" "}
                      {game.home_team}
                    </p>
                  </div>
                )}
              </li>
            );
          })}
        </ol>
        {canEdit && (
          <Grid cols={1} gap="base">
            <GameFeedAdd
              game={game}
              canEdit={canEdit}
              teamRosters={teamRosters}
              currentTime={currentTime}
            />
            {game.status !== "completed" && (
              <ModalConfirmAction
                defaultState={{
                  canEdit,
                  game_id: game.game_id,
                  backLink,
                }}
                actionFunction={endGame}
                confirmationHeading={`Confirm End Game`}
                confirmationByline={`This will publish the game score into the standings, schedule, and stats.`}
                confirmationButtonVariant="primary"
                trigger={{
                  icon: "trophy",
                  label: "End Game",
                  buttonStyles: {
                    variant: "grey",
                    size: "h5",
                  },
                }}
              />
            )}
          </Grid>
        )}
        {game.status === "completed" && (
          <div
            className={apply_classes([
              css.game_feed_summary,
              css.game_feed_completed,
              game_end_highlight_class,
            ])}
          >
            <h4 className={css.game_feed_summary_heading}>Final Score</h4>
            <p>
              <span
                className={
                  game.away_team_score > game.home_team_score
                    ? css.game_feed_winner
                    : undefined
                }
              >
                {game.away_team} <strong>{game.away_team_score}</strong>
              </span>{" "}
              —{" "}
              <span
                className={
                  game.home_team_score > game.away_team_score
                    ? css.game_feed_winner
                    : undefined
                }
              >
                <strong>{game.home_team_score}</strong> {game.home_team}
              </span>
            </p>
          </div>
        )}
      </Card>
    </section>
  );
}
