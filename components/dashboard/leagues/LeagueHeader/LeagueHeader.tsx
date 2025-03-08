"use client";

import { publishLeague } from "@/actions/leagues";
import Badge from "@/components/ui/Badge/Badge";
import HighlightBox from "@/components/ui/HighlightBox/HighlightBox";
import Icon from "@/components/ui/Icon/Icon";
import IconSport from "@/components/ui/Icon/IconSport";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import DHeader from "../../DHeader/DHeader";
import ModalConfirmAction from "../../ModalConfirmAction/ModalConfirmAction";
import SeasonSelector from "../../seasons/SeasonSelector/SeasonSelector";
import css from "./leagueHeader.module.css";

interface LeagueHeaderProps {
  league: LeagueData;
  canEdit: boolean;
}

export default function LeagueHeader({ league, canEdit }: LeagueHeaderProps) {
  const badgeColor: ColorOptions =
    league.status === "archived" ? "danger" : "warning";

  const settingsLink = createDashboardUrl({ l: league.slug }, "settings");

  return (
    <DHeader
      className={css.league_header}
      containerClassName={css.league_header_container}
    >
      {league.status === "draft" && (
        <HighlightBox type="warning" padding={["m", "base"]}>
          Ready to publish this league?
          <ModalConfirmAction
            defaultState={{
              data: { league_id: league.league_id },
            }}
            actionFunction={publishLeague}
            confirmationHeading={`Are you sure you want to publish ${league.name}?`}
            confirmationByline={`This will make your league viewable by members of teams within your league.`}
            confirmationButtonVariant="primary"
            trigger={{
              icon: "publish",
              label: "Publish League",
              buttonStyles: {
                variant: "warning",
              },
            }}
          />
        </HighlightBox>
      )}
      <div className={css.league_header_grid}>
        <h1 className={css.league_header_headline}>
          <IconSport
            sport={league.sport}
            label={league.name}
            labelFirst
            gap="m"
          />
          {league.status && league.status !== "public" && (
            <Badge text={league.status} type={badgeColor} fontSize="h4" />
          )}
        </h1>

        {league.description && <p>{league.description}</p>}
        <div className={css.league_header_actions}>
          {canEdit && (
            <Icon
              icon="settings"
              label="League Settings"
              hideLabel
              href={settingsLink}
              size="h3"
            />
          )}
        </div>
      </div>

      {league.seasons && (
        <SeasonSelector
          className={css.league_header_unit}
          seasons={league.seasons}
          hasAdminRole={canEdit}
        />
      )}
    </DHeader>
  );
}
