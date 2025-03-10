"use client";

import { publishSeason } from "@/actions/seasons";
import Badge from "@/components/ui/Badge/Badge";
import Button from "@/components/ui/Button/Button";
import Dialog from "@/components/ui/Dialog/Dialog";
import HighlightBox from "@/components/ui/HighlightBox/HighlightBox";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { apply_classes } from "@/utils/helpers/html-attributes";
import Link from "next/link";
import { useParams, usePathname } from "next/navigation";
import { useRef } from "react";
import ModalConfirmAction from "../../ModalConfirmAction/ModalConfirmAction";
import css from "./seasonSelector.module.css";

interface SeasonSelectorProps {
  seasons: SeasonData[];
  hasAdminRole: boolean;
  className?: string;
}

export default function SeasonSelector({
  seasons,
  hasAdminRole,
  className,
}: SeasonSelectorProps) {
  const params = useParams();
  const pathName = usePathname();
  const currentSeason = seasons.filter((s) => s.slug === params.season)[0];
  const dialogRef = useRef<HTMLDialogElement>(null);

  const { league, season } = params;

  if (
    !currentSeason ||
    typeof league !== "string" ||
    typeof season !== "string"
  )
    return null;

  const classes = className ? [css.season_info, className] : css.season_info;

  const editLink = createDashboardUrl({ l: league, s: season }, "edit");

  return (
    <>
      <div className={apply_classes(classes)}>
        <p>Current season:</p>
        <Button
          onClick={() => dialogRef?.current?.showModal()}
          outline
          size="xs"
          aria-label="Click to change seasons"
        >
          {currentSeason.name}
        </Button>
        {hasAdminRole && pathName !== editLink && (
          <Button href={editLink} variant="grey" outline size="xs">
            Edit Season
          </Button>
        )}
        {currentSeason.status !== "public" && (
          <Badge
            text={currentSeason.status}
            fontSize="xs"
            type={currentSeason.status === "archived" ? "danger" : "warning"}
          />
        )}{" "}
      </div>

      <Dialog className={css.season_modal} ref={dialogRef} closeButton={true}>
        <h2>Select a Season</h2>
        <ol>
          {seasons?.map((season) => (
            <li key={season.slug}>
              <Link
                href={createDashboardUrl({ l: league, s: season.slug })}
                onClick={() => dialogRef?.current?.close()}
              >
                {season.name}
                {season.status !== "public" && (
                  <Badge
                    text={season.status}
                    fontSize="s"
                    type={season.status === "draft" ? "warning" : "danger"}
                  />
                )}
              </Link>
            </li>
          ))}
        </ol>
        {hasAdminRole && (
          <>
            <p>or</p>
            <Link href={createDashboardUrl({ l: league }, "s")}>
              Add New Season
            </Link>
          </>
        )}
      </Dialog>

      {hasAdminRole && currentSeason.status === "draft" && (
        <HighlightBox type="warning" padding={["m", "base"]}>
          Ready to publish this season?
          <ModalConfirmAction
            defaultState={{
              link: createDashboardUrl({ l: league, s: season }),
              data: {
                league_id: currentSeason.league_id,
                season_id: currentSeason.season_id,
              },
            }}
            actionFunction={publishSeason}
            confirmationHeading={`Are you sure you want to publish ${currentSeason.name}?`}
            confirmationByline={`This will publish both the current season and the league that it belongs to.`}
            confirmationButtonVariant="primary"
            trigger={{
              icon: "publish",
              label: "Publish Season",
              buttonStyles: {
                variant: "warning",
                size: "xs",
              },
            }}
          />
        </HighlightBox>
      )}
    </>
  );
}
