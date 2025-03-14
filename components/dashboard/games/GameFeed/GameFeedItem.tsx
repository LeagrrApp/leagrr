import { deleteFeedItem } from "@/actions/games";
import Icon from "@/components/ui/Icon/Icon";
import InitialsCircle from "@/components/ui/InitialsCircle/InitialsCircle";
import {
  addNumberOrdinals,
  createDashboardUrl,
  formatTimePeriod,
  nameDisplay,
} from "@/utils/helpers/formatting";
import { applyClasses } from "@/utils/helpers/html-attributes";
import Link from "next/link";
import ModalConfirmAction from "../../ModalConfirmAction/ModalConfirmAction";
import css from "./gameFeed.module.css";

interface GameFeedItemProps {
  item: StatsData;
  isHome: boolean;
  teamColor: string;
  canEdit: boolean;
  backLink: string;
}

export default function GameFeedItem({
  item,
  isHome,
  teamColor,
  canEdit,
  backLink,
}: GameFeedItemProps) {
  const {
    type,
    item_id,
    period,
    period_time,
    first_name,
    last_name,
    username,
    assists,
    empty_net,
    shorthanded,
    power_play,
    team,
    rebound,
    minutes,
    infraction,
  } = item;

  const classes: string[] = [css.game_feed_item];

  if (isHome) classes.push(css.game_feed_home);

  // build text string
  let preText: string | undefined = undefined;

  // Goal specific pre-text
  if (type === "goals" && empty_net) preText = "Empty net goal";
  if (type === "goals" && empty_net && shorthanded)
    preText = "Shorthanded empty net goal";
  if (type === "goals" && shorthanded) preText = "Shorthanded goal";
  if (type === "goals" && power_play) preText = "Power play goal";
  if (type === "goals" && empty_net && power_play)
    preText = "Power play empty net goal";

  // set icon
  const icon = {
    icon: "target",
    label: "Shot",
    highlight: false,
  };

  switch (type) {
    case "goals":
      icon.icon = "e911_emergency";
      icon.label = "Goal";
      icon.highlight = true;
      break;
    case "saves":
      icon.icon = "security";
      icon.label = "Save";
      break;
    case "penalties":
      icon.icon = "gavel";
      icon.label = "Penalty";
      break;
    default:
      break;
  }

  return (
    <li id={`game-feed-${type}-${item_id}`} className={applyClasses(classes)}>
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
        {type === "shots" && (
          <>
            <Link href={createDashboardUrl({ u: username })}>
              {nameDisplay(first_name, last_name, "first_initial")}
            </Link>{" "}
            shot on goal
          </>
        )}
        {type === "goals" && (
          <>
            {preText ? preText : "Goal"} by{" "}
            <Link href={createDashboardUrl({ u: username })}>
              {nameDisplay(first_name, last_name, "first_initial")}
            </Link>
            <span style={{ fontStyle: "italic" }}>
              {assists && assists.length > 0 ? (
                <>
                  {" ("}
                  {assists.map((a, i) =>
                    i === 0 ? a.last_name : `, ${a.last_name}`,
                  )}
                  {")"}
                </>
              ) : (
                " (unassisted)"
              )}
            </span>
          </>
        )}
        {type === "saves" && (
          <>
            Save by{" "}
            <Link href={createDashboardUrl({ u: username })}>
              {nameDisplay(first_name, last_name, "first_initial")}
            </Link>
            {!rebound && ", no rebound"}
          </>
        )}
        {type === "penalties" && (
          <>
            <Link href={createDashboardUrl({ u: username })}>
              {nameDisplay(first_name, last_name, "first_initial")}
            </Link>{" "}
            penalty, {minutes} minutes for <strong>{infraction}</strong>
          </>
        )}
      </p>
      <div
        className={applyClasses(
          css.game_feed_item_type,
          icon.highlight ? css.game_feed_item_type_highlight : "",
        )}
      >
        <Icon icon={icon.icon} label={icon.label} hideLabel size="h4" />
      </div>
      {canEdit && (
        <ModalConfirmAction
          defaultState={{
            data: {
              id: item.item_id,
              type: type,
            },
            link: backLink,
          }}
          actionFunction={deleteFeedItem}
          confirmationHeading={`Are you sure you want to delete this feed item?`}
          trigger={{
            classes: css.game_feed_item_delete,
            icon: "delete",
            label: "Delete Item",
            hideLabel: true,
            buttonStyles: {
              variant: "danger",
              padding: ["xs"],
            },
          }}
        />
      )}
    </li>
  );
}
