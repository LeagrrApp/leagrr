import { deleteFeedItem } from "@/actions/games";
import Icon from "@/components/ui/Icon/Icon";
import InitialsCircle from "@/components/ui/InitialsCircle/InitialsCircle";
import {
  addNumberOrdinals,
  createDashboardUrl,
  formatTimePeriod,
  nameDisplay,
} from "@/utils/helpers/formatting";
import { apply_classes } from "@/utils/helpers/html-attributes";
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
  if (item.type === "stats.goals" && empty_net) preText = "Empty net goal";
  if (item.type === "stats.goals" && empty_net && shorthanded)
    preText = "Shorthanded empty net goal";
  if (item.type === "stats.goals" && shorthanded) preText = "Shorthanded goal";
  if (item.type === "stats.goals" && power_play) preText = "Power play goal";
  if (item.type === "stats.goals" && empty_net && power_play)
    preText = "Power play empty net goal";

  // set icon
  const icon = {
    icon: "target",
    label: "Shot",
    highlight: false,
  };

  switch (item.type) {
    case "stats.goals":
      icon.icon = "e911_emergency";
      icon.label = "Goal";
      icon.highlight = true;
      break;
    case "stats.saves":
      icon.icon = "security";
      icon.label = "Save";
      break;
    case "stats.penalties":
      icon.icon = "gavel";
      icon.label = "Penalty";
      break;
    default:
      break;
  }

  return (
    <li className={apply_classes(classes)}>
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
        {item.type === "stats.shots" && (
          <>
            <Link href={createDashboardUrl({ u: username })}>
              {nameDisplay(first_name, last_name, "first_initial")}
            </Link>{" "}
            shot on goal
          </>
        )}
        {item.type === "stats.goals" && (
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
        {item.type === "stats.saves" && (
          <>
            Save by{" "}
            <Link href={createDashboardUrl({ u: username })}>
              {nameDisplay(first_name, last_name, "first_initial")}
            </Link>
            {!rebound && ", no rebound"}
          </>
        )}
        {item.type === "stats.penalties" && (
          <>
            <Link href={createDashboardUrl({ u: username })}>
              {nameDisplay(first_name, last_name, "first_initial")}
            </Link>{" "}
            penalty, {minutes} minutes for <strong>{infraction}</strong>
          </>
        )}
      </p>
      <div
        className={apply_classes(
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
              type: item.type,
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
