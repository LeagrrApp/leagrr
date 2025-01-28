import { getGameFeed, getGameTeamRosters } from "@/actions/games";
import Card from "@/components/ui/Card/Card";
import Icon from "@/components/ui/Icon/Icon";
import css from "./gameFeed.module.css";
import GameFeedAdd from "../GameFeedAdd/GameFeedAdd";
import GameFeedGoal from "./GameFeedGoal";
import GameFeedPenalty from "./GameFeedPenalty";
import GameFeedSave from "./GameFeedSave";
import GameFeedShot from "./GameFeedShot";

interface GameFeedProps {
  game: GameData;
  canEdit: boolean;
}

export default async function GameFeed({ game, canEdit }: GameFeedProps) {
  const { data: gameFeed } = await getGameFeed(game.game_id);

  const { data: teamRosters } = await getGameTeamRosters(
    game.away_team_id,
    game.home_team_id,
  );

  if (!teamRosters) return null;

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
            />
          ) : (
            <p>There are no items in this game feed yet.</p>
          )}
        </Card>
      </div>
    );
  }

  const periods: string[] = Object.keys(gameFeed);

  return (
    <section id="game-feed" className={css.game_feed}>
      <h3 className="push-ml type-scale-h4">Game Feed</h3>
      <Card padding="ml">
        <ol className={css.game_feed_periods}>
          {periods.map((p, i) => {
            if (gameFeed[p].length < 1) return null;

            return (
              <li key={p} className={css.game_feed_period}>
                <h4 className={css.game_feed_period_heading}>
                  <Icon icon="sports" label={`Period ${i + 1}`} labelFirst />
                </h4>
                <ol className={css.game_feed_feed}>
                  {gameFeed[p].map((item: GameFeedItemData) => {
                    const isHome = game.home_team_id === item.team_id;
                    switch (item.type) {
                      case "stats.shots":
                        return (
                          <GameFeedShot
                            key={`${item.type}-${item.period}-${item.period_time.minutes}-${item.period_time.seconds}`}
                            item={item}
                            isHome={isHome}
                            teamColor={
                              isHome
                                ? game.home_team_color
                                : game.away_team_color
                            }
                          />
                        );
                      case "stats.goals":
                        return (
                          <GameFeedGoal
                            key={`${item.type}-${item.period}-${item.period_time.minutes}-${item.period_time.seconds}`}
                            item={item}
                            isHome={isHome}
                            teamColor={
                              isHome
                                ? game.home_team_color
                                : game.away_team_color
                            }
                          />
                        );
                      case "stats.saves":
                        return (
                          <GameFeedSave
                            key={`${item.type}-${item.period}-${item.period_time.minutes}-${item.period_time.seconds}`}
                            item={item}
                            isHome={isHome}
                            teamColor={
                              isHome
                                ? game.home_team_color
                                : game.away_team_color
                            }
                          />
                        );
                      case "stats.penalties":
                        return (
                          <GameFeedPenalty
                            key={`${item.type}-${item.period}-${item.period_time.minutes}-${item.period_time.seconds}`}
                            item={item}
                            isHome={isHome}
                            teamColor={
                              isHome
                                ? game.home_team_color
                                : game.away_team_color
                            }
                          />
                        );
                      default:
                        return null;
                    }
                  })}
                </ol>
              </li>
            );
          })}
        </ol>
        {canEdit && (
          <GameFeedAdd
            game={game}
            canEdit={canEdit}
            teamRosters={teamRosters}
          />
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
