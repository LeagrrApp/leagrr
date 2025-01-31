"use client";

import { useParams, useSearchParams } from "next/navigation";
import css from "./divisionSelector.module.css";
import { useRef } from "react";
import Button from "@/components/ui/Button/Button";
import Dialog from "@/components/ui/Dialog/Dialog";
import Link from "next/link";
import { createDashboardUrl } from "@/utils/helpers/formatting";

interface DivisionSelectorProps {
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

export default function DivisionSelector({
  divisions,
  canEdit,
}: DivisionSelectorProps) {
  const params = useParams();
  const searchParams = useSearchParams();
  const dialogRef = useRef<HTMLDialogElement>(null);

  const queryDiv = searchParams.get("div");
  let currentDiv = divisions[0];

  if (queryDiv !== null) {
    const foundQueryDiv = divisions.find(
      (d) => d.division_id === parseInt(queryDiv),
    );
    if (foundQueryDiv) currentDiv = foundQueryDiv;
  }

  return (
    <>
      <div className={css.division_info}>
        <p>Current division:</p>
        <Button
          onClick={() => dialogRef?.current?.showModal()}
          outline
          size="xs"
          aria-label="Click to change division"
        >
          {currentDiv.division} - {currentDiv.league}
        </Button>
      </div>
      <Dialog className={css.division_modal} ref={dialogRef} closeButton={true}>
        <h2>Select a Division</h2>
        <ol>
          {divisions?.map((division) => (
            <li key={division.division_slug}>
              <Link
                href={createDashboardUrl(
                  { t: params.team as string },
                  `?div=${division.division_id}`,
                )}
                onClick={() => dialogRef?.current?.close()}
              >
                {division.division}{" "}
                <span
                  style={{
                    fontSize: "var(--type-scale-s)",
                    display: "block",
                    color: "var(--color-black)",
                  }}
                >
                  ({division.season} - {division.league})
                </span>
              </Link>
            </li>
          ))}
        </ol>
        {canEdit && (
          <>
            <p>or</p>
            <Link href="#">Join a division</Link>
          </>
        )}
      </Dialog>
    </>
  );
}
