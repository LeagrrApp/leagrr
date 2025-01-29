import endGame, { getGameFeed, getGameTeamRosters } from "@/actions/games";
import Card from "@/components/ui/Card/Card";
import Icon from "@/components/ui/Icon/Icon";
import Grid from "@/components/ui/layout/Grid";
import ModalConfirmAction from "../../ModalConfirmAction/ModalConfirmAction";
import GameFeedAdd from "../GameFeedAdd/GameFeedAdd";
import css from "./gameFeed.module.css";
import GameFeedItem from "./GameFeedItem";

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
  );

  if (!teamRosters) return null;

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
                  <Icon icon="sports" label={`Period ${i + 1}`} labelFirst />
                </h4>
                {gameFeed[p].length > 1 ? (
                  <ol className={css.game_feed_feed}>
                    {gameFeed[p].map((item: StatsData) => {
                      const isHome = game.home_team_id === item.team_id;

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
          <div className={css.game_feed_completed}>
            <h4 className={css.game_feed_completed_heading}>Final Score</h4>
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
