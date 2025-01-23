"use client";

import Button from "@/components/ui/Button/Button";
import Dialog from "@/components/ui/Dialog/Dialog";
import Link from "next/link";
import { useParams, usePathname } from "next/navigation";
import { useRef } from "react";
import css from "./seasonSelector.module.css";
import Badge from "@/components/ui/Badge/Badge";
import { apply_classes } from "@/utils/helpers/html-attributes";

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

  if (!currentSeason) return null;

  const classes = className ? [css.season_info, className] : css.season_info;

  const editLink = `/dashboard/l/${params.league}/s/${params.season}/edit`;

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
        {currentSeason.status && currentSeason.status !== "public" && (
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
                href={`/dashboard/l/${params.league}/s/${season.slug}`}
                onClick={() => dialogRef?.current?.close()}
              >
                {season.name}
              </Link>
            </li>
          ))}
        </ol>
        {hasAdminRole && (
          <>
            <p>or</p>
            <Link href="./">Add New Season</Link>
          </>
        )}
      </Dialog>
    </>
  );
}
