"use client";

import Badge from "@/components/ui/Badge/Badge";
import Icon from "@/components/ui/Icon/Icon";
import { usePathname } from "next/navigation";
import DHeader from "../../DHeader/DHeader";
import SeasonSelector from "../../seasons/SeasonSelector/SeasonSelector";
import css from "./leagueHeader.module.css";

interface LeagueHeaderProps {
  league: LeagueData;
  canEdit: boolean;
}

export default function LeagueHeader({ league, canEdit }: LeagueHeaderProps) {
  const pathname = usePathname();

  let badgeColor: ColorOptions =
    league.status === "archived" ? "danger" : "warning";

  const editLink = `/dashboard/l/${league.slug}/edit`;

  return (
    <DHeader
      className={css.league_header}
      containerClassName={css.league_header_container}
      hideLine
    >
      <div className={css.league_header_unit}>
        <h1 className={css.league_header_headline}>
          {league.name}{" "}
          {league.status && league.status !== "public" && (
            <Badge text={league.status} type={badgeColor} fontSize="h4" />
          )}
          {canEdit && pathname !== editLink && (
            <Icon
              icon="edit_square"
              label="Edit League"
              hideLabel
              href={editLink}
              size="h3"
            />
          )}
        </h1>
        {league.description && <p>{league.description}</p>}
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
