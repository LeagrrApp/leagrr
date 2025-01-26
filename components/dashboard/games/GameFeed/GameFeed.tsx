import Card from "@/components/ui/Card/Card";
import css from "./gameFeed.module.css";
import { getGameFeed } from "@/actions/games";

interface GameFeedProps {
  game: GameData;
}

export default async function GameFeed({ game }: GameFeedProps) {
  const { data: gameFeed, message } = await getGameFeed(game.game_id);

  console.log(message);
  console.log(gameFeed);

  return (
    <Card className={css.game_feed} padding="ml">
      <h3>Game Feed</h3>
      {gameFeed ? (
        <ol>
          <li>
            <h4>Period 1</h4>
            <ol>
              {gameFeed.period1.map((item) => (
                <FeedItem item={item} />
              ))}
            </ol>
          </li>
          <li>
            <h4>Period 2</h4>
            <ol>
              {gameFeed.period2.map((item) => (
                <FeedItem item={item} />
              ))}
            </ol>
          </li>
          <li>
            <h4>Period 3</h4>
            <ol>
              {gameFeed.period3.map((item) => (
                <FeedItem item={item} />
              ))}
            </ol>
          </li>
        </ol>
      ) : (
        <p>{message}</p>
      )}
    </Card>
  );
}

function FeedItem({ item }: { item: GameFeedItemData }) {
  switch (item.type) {
    case "stats.shots":
      return (
        <li
          key={`${item.type}-${item.period}-${item.period_time.minutes}-${item.period_time.seconds}`}
        >
          {item.period_time.minutes}:
          {item.period_time.seconds > 9
            ? item.period_time.seconds
            : `0${item.period_time.seconds}`}{" "}
          - {item.user_last_name} - Shot
        </li>
      );
    case "stats.goals":
      return (
        <li
          key={`${item.type}-${item.period}-${item.period_time.minutes}-${item.period_time.seconds}`}
        >
          {item.period_time.minutes}:
          {item.period_time.seconds > 9
            ? item.period_time.seconds
            : `0${item.period_time.seconds}`}{" "}
          - {item.user_last_name} - Goal (
          {item.assists && item.assists.length > 0
            ? item.assists.map((a, i) =>
                i === 0 ? a.user_last_name : `, ${a.user_last_name}`
              )
            : "Unassisted"}
          )
        </li>
      );
    case "stats.saves":
      return (
        <li
          key={`${item.type}-${item.period}-${item.period_time.minutes}-${item.period_time.seconds}`}
        >
          {item.period_time.minutes}:
          {item.period_time.seconds > 9
            ? item.period_time.seconds
            : `0${item.period_time.seconds}`}{" "}
          - {item.user_last_name} - Save
        </li>
      );
    case "stats.penalties":
      return (
        <li
          key={`${item.type}-${item.period}-${item.period_time.minutes}-${item.period_time.seconds}`}
        >
          {item.period_time.minutes}:
          {item.period_time.seconds > 9
            ? item.period_time.seconds
            : `0${item.period_time.seconds}`}{" "}
          - {item.user_last_name} - Penalty
        </li>
      );
    default:
      return null;
  }
}
