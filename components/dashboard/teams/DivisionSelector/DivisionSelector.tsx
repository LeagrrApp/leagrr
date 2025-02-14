"use client";

import Button from "@/components/ui/Button/Button";
import Dialog from "@/components/ui/Dialog/Dialog";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import Link from "next/link";
import { useParams, usePathname } from "next/navigation";
import { useRef } from "react";
import css from "./divisionSelector.module.css";

interface DivisionSelectorProps {
  canEdit: boolean;
  divisions: TeamDivisionsData[];
}

export default function DivisionSelector({
  divisions,
  canEdit,
}: DivisionSelectorProps) {
  const pathname = usePathname();
  const { team, id } = useParams();
  const dialogRef = useRef<HTMLDialogElement>(null);

  const division_id = parseInt(id as string);

  const currentDiv = divisions.find((d) => d.division_id === division_id);

  if (!currentDiv) return null;

  let hrefAddition: string | undefined = undefined;

  if (pathname.includes("roster")) hrefAddition = "roster";

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
            <li key={`${division.division_id}`}>
              <Link
                href={createDashboardUrl(
                  {
                    t: team as string,
                    d: division.division_id,
                  },
                  hrefAddition,
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
