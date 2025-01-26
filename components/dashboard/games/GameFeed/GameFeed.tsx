import Card from "@/components/ui/Card/Card";
import css from "./gameFeed.module.css";
import { getGameFeed } from "@/actions/games";
import GameFeedPenalty from "./GameFeedPenalty";
import GameFeedSave from "./GameFeedSave";
import GameFeedGoal from "./GameFeedGoal";
import GameFeedShot from "./GameFeedShot";
import Icon from "@/components/ui/Icon/Icon";

interface GameFeedProps {
  game: GameData;
}

export default async function GameFeed({ game }: GameFeedProps) {
  const { data: gameFeed, message } = await getGameFeed(game.game_id);

  console.log(message);
  console.log(gameFeed);

  if (!gameFeed) {
    return (
      <div className={css.game_feed}>
        <h3>Game Feed</h3>
        <Card className={css.game_feed} padding="ml">
          <p>{message}</p>
        </Card>
      </div>
    );
  }

  if (
    gameFeed.period1.length < 1 &&
    gameFeed.period1.length < 1 &&
    gameFeed.period1.length < 1
  ) {
    return (
      <div className={css.game_feed}>
        <h3>Game Feed</h3>
        <Card className={css.game_feed} padding="ml">
          <p>This game has no items in its game feed!</p>
        </Card>
      </div>
    );
  }

  const periods: string[] = Object.keys(gameFeed);

  return (
    <div className={css.game_feed}>
      <h3 className="push-ml type-scale-h4">Game Feed</h3>
      <Card padding="ml">
        <ol className={css.game_feed_periods}>
          {periods.map((p, i) => {
            return (
              <li key={p} className={css.game_feed_period}>
                <h4 className={css.game_feed_period_heading}>
                  <Icon icon="sports" label={`Period ${i + 1}`} labelFirst />
                </h4>
                <ol className={css.game_feed_feed}>
                  {gameFeed[p].map((item: GameFeedItemData) => {
                    switch (item.type) {
                      case "stats.shots":
                        return (
                          <GameFeedShot
                            key={`${item.type}-${item.period}-${item.period_time.minutes}-${item.period_time.seconds}`}
                            item={item}
                            isHome={game.home_team_id === item.team_id}
                          />
                        );
                      case "stats.goals":
                        return (
                          <GameFeedGoal
                            key={`${item.type}-${item.period}-${item.period_time.minutes}-${item.period_time.seconds}`}
                            item={item}
                            isHome={game.home_team_id === item.team_id}
                          />
                        );
                      case "stats.saves":
                        return (
                          <GameFeedSave
                            key={`${item.type}-${item.period}-${item.period_time.minutes}-${item.period_time.seconds}`}
                            item={item}
                            isHome={game.home_team_id === item.team_id}
                          />
                        );
                      case "stats.penalties":
                        return (
                          <GameFeedPenalty
                            key={`${item.type}-${item.period}-${item.period_time.minutes}-${item.period_time.seconds}`}
                            item={item}
                            isHome={game.home_team_id === item.team_id}
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
        {game.status === "completed" && (
          <div className={css.game_feed_completed}>
            <h4 className={css.game_feed_completed_heading}>Final Score:</h4>
            <p>
              <span
                className={
                  game.away_team_stats_goals > game.home_team_stats_goals
                    ? css.game_feed_winner
                    : undefined
                }
              >
                {game.away_team} <strong>{game.away_team_stats_goals}</strong>
              </span>{" "}
              -{" "}
              <span
                className={
                  game.home_team_stats_goals > game.away_team_stats_goals
                    ? css.game_feed_winner
                    : undefined
                }
              >
                <strong>{game.home_team_stats_goals}</strong> {game.home_team}
              </span>
            </p>
          </div>
        )}
      </Card>
    </div>
  );
}
