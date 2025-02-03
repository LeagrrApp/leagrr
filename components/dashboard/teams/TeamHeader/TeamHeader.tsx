"use client";

import Badge from "@/components/ui/Badge/Badge";
import Icon from "@/components/ui/Icon/Icon";
import { usePathname } from "next/navigation";
import css from "./teamHeader.module.css";
import DHeader from "../../DHeader/DHeader";
import IconSport from "@/components/ui/Icon/IconSport";
import DivisionSelector from "../DivisionSelector/DivisionSelector";

interface TeamHeaderProps {
  team: TeamData;
  canEdit: boolean;
  divisions: {
    division: string;
    division_id: number;
    division_slug: string;
    season: string;
    season_slug: string;
    league: string;
    league_slug: string;
  }[];
}

export default function TeamHeader({
  team,
  canEdit,
  divisions,
}: TeamHeaderProps) {
  const pathname = usePathname();

  const { slug, name, status, description, color } = team;

  let badgeColor: ColorOptions = "warning";

  if (status === "suspended") badgeColor = "caution";
  if (status === "banned") badgeColor = "danger";

  const editLink = `/dashboard/t/${slug}/edit`;

  return (
    <DHeader
      className={css.team_header}
      containerClassName={css.team_header_container}
      hideLine
    >
      <div className={css.team_header_unit}>
        <h1 className={css.team_header_headline}>
          {name}{" "}
          {status && status !== "active" && (
            <Badge text={status} type={badgeColor} fontSize="h4" />
          )}
          {canEdit && pathname !== editLink && (
            <Icon
              icon="edit_square"
              label="Edit Team"
              hideLabel
              href={editLink}
              size="h3"
            />
          )}
        </h1>
        {description && <p>{description}</p>}
      </div>

      {divisions?.length > 0 && (
        <DivisionSelector divisions={divisions} canEdit={canEdit} />
      )}
    </DHeader>
  );
}
