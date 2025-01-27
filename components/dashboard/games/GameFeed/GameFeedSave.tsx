import { apply_classes } from "@/utils/helpers/html-attributes";
import css from "./gameFeed.module.css";
import {
  addNumberOrdinals,
  formatTimePeriod,
} from "@/utils/helpers/formatting";
import InitialsCircle from "@/components/ui/InitialsCircle/InitialsCircle";
import Icon from "@/components/ui/Icon/Icon";
import Link from "next/link";

interface GameFeedSaveProps {
  item: GameFeedItemData;
  isHome: boolean;
  teamColor: string;
}

export default function GameFeedSave({
  item,
  isHome,
  teamColor,
}: GameFeedSaveProps) {
  const { period, period_time, user_last_name, username, team, rebound } = item;

  const classes: string[] = [css.game_feed_item, css.game_feed_item_penalty];

  if (isHome) classes.push(css.game_feed_home);

  return (
    <div className={apply_classes(classes)}>
      <div className={css.game_feed_item_time}>
        <span className={css.game_feed_item_period_time}>
          {formatTimePeriod(period_time)}
        </span>
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
      <div className={css.game_feed_item_player_info}>
        Save by <Link href={`/dashboard/u/${username}`}>{user_last_name}</Link>
        {!rebound && ", no rebound"}
      </div>
      <div className={css.game_feed_item_type}>
        <Icon icon="security" label="Save" hideLabel size="h4" />
      </div>
    </div>
  );
}
