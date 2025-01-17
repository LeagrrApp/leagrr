"use client";

import Button from "@/components/ui/Button/Button";
import Dialog from "@/components/ui/Dialog/Dialog";
import Link from "next/link";
import { useParams, usePathname } from "next/navigation";
import { useRef } from "react";
import css from "./seasonSelector.module.css";
import Badge from "@/components/ui/Badge/Badge";

interface SeasonSelectorProps {
  seasons: SeasonData[];
  hasAdminRole: boolean;
}

export default function SeasonSelector({
  seasons,
  hasAdminRole,
}: SeasonSelectorProps) {
  const params = useParams();
  const pathName = usePathname();
  const currentSeason = seasons.filter((s) => s.slug === params.season)[0];
  const dialogRef = useRef<HTMLDialogElement>(null);

  if (!currentSeason) return null;

  const editLink = `/dashboard/l/${params.league}/s/${params.season}/edit`;

  return (
    <>
      <p className={css.season_info}>
        Current season: <strong>{currentSeason.name}</strong>
        {currentSeason.status && currentSeason.status !== "public" && (
          <Badge
            text={currentSeason.status}
            fontSize="xs"
            type={currentSeason.status === "archived" ? "danger" : "warning"}
          />
        )}{" "}
        <Button
          onClick={() => dialogRef?.current?.showModal()}
          outline
          size="xs"
        >
          Change Season
        </Button>
        {hasAdminRole && pathName !== editLink && (
          <Button href={editLink} variant="grey" outline size="xs">
            Edit Season
          </Button>
        )}
      </p>

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
