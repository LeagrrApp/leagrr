"use client";

import Badge from "@/components/ui/Badge/Badge";
import Button from "@/components/ui/Button/Button";
import Dialog from "@/components/ui/Dialog/Dialog";
import Icon from "@/components/ui/Icon/Icon";
import {
  applyStatusColor,
  createDashboardUrl,
} from "@/utils/helpers/formatting";
import Link from "next/link";
import { useParams, usePathname } from "next/navigation";
import { useRef } from "react";
import css from "./divisionSelector.module.css";

interface DivisionSelectorProps {
  divisions?: DivisionData[];
  canEdit: boolean;
}

export default function DivisionSelector({
  divisions,
  canEdit,
}: DivisionSelectorProps) {
  const params = useParams();
  const pathname = usePathname();
  const dialogRef = useRef<HTMLDialogElement>(null);

  if (!divisions) return null;

  const { league, season, division } = params;
  const currentDivision = divisions.find((d) => d.slug === division);

  if (
    !currentDivision ||
    typeof league !== "string" ||
    typeof season !== "string" ||
    typeof division !== "string"
  )
    return null;

  return (
    <>
      <Button
        onClick={() => dialogRef?.current?.showModal()}
        outline
        size="xs"
        aria-label="Click to change division"
      >
        <Icon label="Division" icon="swap_horiz" gap="s" />
      </Button>

      <Dialog className={css.division_modal} ref={dialogRef} closeButton={true}>
        <h2>Select a Division</h2>
        <ol>
          {divisions?.map((division) => {
            const divUrl = createDashboardUrl({
              l: league,
              s: season,
              d: division.slug,
            });

            return (
              <li key={division.slug}>
                <Link
                  href={divUrl}
                  onClick={() => dialogRef?.current?.close()}
                  aria-current={pathname === divUrl ? "page" : undefined}
                >
                  {division.name}
                  {division.status !== "public" && (
                    <Badge
                      text={division.status}
                      fontSize="s"
                      type={applyStatusColor(division.status)}
                    />
                  )}
                </Link>
              </li>
            );
          })}
        </ol>
        {canEdit && (
          <>
            <p>or</p>
            <Link href={createDashboardUrl({ l: league }, "s")}>
              Add New Division
            </Link>
          </>
        )}
      </Dialog>
    </>
  );
}
