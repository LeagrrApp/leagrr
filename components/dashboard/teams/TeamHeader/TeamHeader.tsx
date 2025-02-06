"use client";

import Badge from "@/components/ui/Badge/Badge";
import Button from "@/components/ui/Button/Button";
import Icon from "@/components/ui/Icon/Icon";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { usePathname } from "next/navigation";
import DHeader from "../../DHeader/DHeader";
import DivisionSelector from "../DivisionSelector/DivisionSelector";
import css from "./teamHeader.module.css";

interface TeamHeaderProps {
  team: TeamData;
  canEdit: boolean;
  divisions: TeamDivisionsProps[];
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

  const editLink = createDashboardUrl({ t: slug }, "edit");
  const membersLink = createDashboardUrl({ t: slug }, "members");

  return (
    <DHeader
      className={css.team_header}
      containerClassName={css.team_header_container}
      color={color}
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

      <div className={css.team_header_controls}>
        {divisions?.length > 0 && (
          <DivisionSelector divisions={divisions} canEdit={canEdit} />
        )}
        {membersLink !== pathname && (
          <Button href={membersLink} size="xs">
            <Icon
              label={canEdit ? "Manage Team Members" : "View Team Members"}
              icon="groups"
            />
          </Button>
        )}
      </div>
    </DHeader>
  );
}
