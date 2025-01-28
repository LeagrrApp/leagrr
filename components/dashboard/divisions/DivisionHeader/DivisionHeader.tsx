"use client";

import { useParams, usePathname } from "next/navigation";
import Badge from "@/components/ui/Badge/Badge";
import Icon from "@/components/ui/Icon/Icon";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import css from "./divisionHeader.module.css";

interface DivisionHeaderProps {
  division: DivisionData;
  canEdit: boolean;
}

export default function DivisionHeader({
  division,
  canEdit,
}: DivisionHeaderProps) {
  const pathname = usePathname();

  const {
    slug,
    name,
    description,
    gender,
    tier,
    join_code,
    status,
    season_slug,
    league_slug,
  } = division;

  const editLink = createDashboardUrl(
    { l: league_slug, s: season_slug, d: slug },
    "edit",
  );

  const showStatus = status !== undefined && status !== "public";
  const statusColor = status === "draft" ? "warning" : "danger";

  return (
    <div className={css.division_header}>
      <h2 className={css.division_name}>
        {name}
        {showStatus && <Badge text={status} type={statusColor} fontSize="h5" />}
        {canEdit && pathname !== editLink && (
          <Icon
            icon="edit_square"
            label="Edit division"
            hideLabel
            href={editLink}
            size="h4"
          />
        )}
      </h2>
      {description && <p>{description}</p>}
    </div>
  );
}
