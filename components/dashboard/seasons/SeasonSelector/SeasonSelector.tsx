"use client";

import { publishSeason } from "@/actions/seasons";
import Badge from "@/components/ui/Badge/Badge";
import Button from "@/components/ui/Button/Button";
import Dialog from "@/components/ui/Dialog/Dialog";
import HighlightBox from "@/components/ui/HighlightBox/HighlightBox";
import Icon from "@/components/ui/Icon/Icon";
import {
  applyStatusColor,
  createDashboardUrl,
} from "@/utils/helpers/formatting";
import { applyClasses } from "@/utils/helpers/html-attributes";
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
  const currentSeason = seasons.find((s) => s.slug === params.season);
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
      <div className={applyClasses(classes)}>
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
          // <Icon
          //   href={editLink}
          //   icon="edit_square"
          //   label="Edit Season"
          //   hideLabel
          // />
          <Button
            href={editLink}
            variant="grey"
            outline
            size="xs"
            padding={["em-m"]}
          >
            <Icon icon="edit_square" label="Edit Season" hideLabel />
          </Button>
        )}
        {currentSeason.status !== "public" && (
          <Badge
            text={currentSeason.status}
            fontSize="xs"
            type={applyStatusColor(currentSeason.status)}
          />
        )}{" "}
      </div>

      <Dialog className={css.season_modal} ref={dialogRef} closeButton={true}>
        <h2>Select a Season</h2>
        <ol>
          {seasons?.map((season) => {
            const seasonUrl = createDashboardUrl({ l: league, s: season.slug });

            return (
              <li key={season.slug}>
                <Link
                  href={seasonUrl}
                  onClick={() => dialogRef?.current?.close()}
                  aria-current={
                    params.season === season.slug ? "page" : undefined
                  }
                >
                  {season.name}
                  {season.status !== "public" && (
                    <Badge
                      text={season.status}
                      fontSize="s"
                      type={applyStatusColor(season.status)}
                    />
                  )}
                </Link>
              </li>
            );
          })}
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
