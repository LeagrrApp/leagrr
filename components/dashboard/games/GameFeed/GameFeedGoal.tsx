import { apply_classes } from "@/utils/helpers/html-attributes";
import css from "./gameFeed.module.css";
import {
  addNumberOrdinals,
  formatTimePeriod,
} from "@/utils/helpers/formatting";
import Icon from "@/components/ui/Icon/Icon";
import InitialsCircle from "@/components/ui/InitialsCircle/InitialsCircle";
import Link from "next/link";

interface GameFeedGoalProps {
  item: GameFeedItemData;
  isHome: boolean;
  teamColor: string;
}

export default function GameFeedGoal({
  item,
  isHome,
  teamColor,
}: GameFeedGoalProps) {
  const {
    period,
    period_time,
    user_last_name,
    username,
    assists,
    empty_net,
    team,
  } = item;
  const classes: string[] = [css.game_feed_item, css.game_feed_item_penalty];

  if (isHome) classes.push(css.game_feed_home);

  return (
    <div className={apply_classes(classes)}>
      <div className={css.game_feed_item_time}>
        <h5 className={css.game_feed_item_period_time}>
          {formatTimePeriod(period_time)}
        </h5>
        <span className={css.game_feed_item_period}>
          {addNumberOrdinals(period)}
        </span>
      </div>
      <div className={css.game_feed_item_team}>
        <InitialsCircle
          color={{
            bg: teamColor,
            text: teamColor === "white" ? "black" : "white",
          }}
          fontSize="h5"
          label={team}
          initialsStyle="first_word"
          hideLabel
        />
      </div>
      <p className={css.game_feed_item_player_info}>
        {empty_net ? "Empty net goal" : "Goal"} by{" "}
        <Link href={`/dashboard/u/${username}`}>{user_last_name}</Link>{" "}
        <span style={{ fontStyle: "italic" }}>
          {assists && assists.length > 0 ? (
            <>
              assisted by{" "}
              {assists.map((a, i) =>
                i === 0 ? a.user_last_name : `, ${a.user_last_name}`,
              )}
            </>
          ) : (
            "Unassisted"
          )}
        </span>
      </p>
      <div
        className={apply_classes(
          css.game_feed_item_type,
          css.game_feed_item_type_goal,
        )}
      >
        <Icon icon="e911_emergency" label="Goal" hideLabel size="h4" />
      </div>
    </div>
  );
}
