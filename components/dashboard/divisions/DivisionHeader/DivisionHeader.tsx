"use client";

import { publishDivision } from "@/actions/divisions";
import Badge from "@/components/ui/Badge/Badge";
import HighlightBox from "@/components/ui/HighlightBox/HighlightBox";
import Icon from "@/components/ui/Icon/Icon";
import {
  applyStatusColor,
  createDashboardUrl,
} from "@/utils/helpers/formatting";
import { usePathname } from "next/navigation";
import ModalConfirmAction from "../../ModalConfirmAction/ModalConfirmAction";
import DivisionSelector from "../DivisionSelector/DivisionSelector";
import css from "./divisionHeader.module.css";

interface DivisionHeaderProps {
  divisions?: DivisionData[];
  division: DivisionData;
  canEdit: boolean;
}

export default function DivisionHeader({
  divisions,
  division,
  canEdit,
}: DivisionHeaderProps) {
  const pathname = usePathname();

  const {
    division_id,
    slug,
    name,
    description,
    status,
    season_slug,
    league_slug,
    league_id,
    season_id,
  } = division;

  const editLink = createDashboardUrl(
    { l: league_slug, s: season_slug, d: slug },
    "edit",
  );

  const showStatus = status && status !== "public";

  return (
    <>
      {canEdit && division.status === "draft" && (
        <HighlightBox type="warning" marginEnd="base" padding={["m", "base"]}>
          Ready to publish this division?
          <ModalConfirmAction
            defaultState={{
              link: createDashboardUrl({
                l: league_slug,
                s: season_slug,
                d: slug,
              }),
              data: {
                league_id: league_id,
                season_id: season_id,
                division_id: division_id,
              },
            }}
            actionFunction={publishDivision}
            confirmationHeading={`Are you sure you want to publish ${name}?`}
            confirmationByline={`This will also publish the season and the league that this division belongs to.`}
            confirmationButtonVariant="primary"
            trigger={{
              icon: "publish",
              label: "Publish Division",
              buttonStyles: {
                variant: "warning",
                size: "xs",
              },
            }}
          />
        </HighlightBox>
      )}
      <div className={css.division_header}>
        <h2 className={css.division_name}>
          {name}
          {showStatus && (
            <Badge
              text={status}
              type={applyStatusColor(status)}
              fontSize="h5"
            />
          )}
        </h2>
        {description && <p className={css.division_desc}>{description}</p>}
        <div className={css.division_options}>
          <DivisionSelector divisions={divisions} canEdit={canEdit} />
          {canEdit && pathname !== editLink && (
            <Icon
              icon="edit_square"
              label="Edit division"
              hideLabel
              href={editLink}
              size="h4"
            />
          )}
        </div>
      </div>
    </>
  );
}
