"use client";

import Badge from "@/components/ui/Badge/Badge";
import Icon from "@/components/ui/Icon/Icon";
import IconSport from "@/components/ui/Icon/IconSport";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import DHeader from "../../DHeader/DHeader";
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
