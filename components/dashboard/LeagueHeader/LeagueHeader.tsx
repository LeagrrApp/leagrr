"use client";

import { PropsWithChildren } from "react";
import Container from "@/components/ui/Container/Container";
import css from "./leagueHeader.module.css";
import Line from "@/components/ui/decorations/Line";
import Badge from "@/components/ui/Badge/Badge";
import { Url } from "next/dist/shared/lib/router/router";
import Icon from "@/components/ui/Icon/Icon";
import { usePathname } from "next/navigation";
import SeasonSelector from "../SeasonSelector/SeasonSelector";
import DHeader from "../DHeader/DHeader";

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
      {canEdit && (
        <div className={css.league_header_admin_bar}>
          {pathname === editLink ? (
            <Icon
              icon="chevron_left"
              label="Back to league"
              size="h4"
              href={`./`}
            />
          ) : (
            <Icon icon="edit" label="Edit League" href={editLink} size="h4" />
          )}
        </div>
      )}
      <h1 className={css.league_header_headline}>
        {league.name}{" "}
        {league.status && league.status !== "public" && (
          <Badge text={league.status} type={badgeColor} fontSize="h4" />
        )}
      </h1>
      <div className={css.league_header_unit}>
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
