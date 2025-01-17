"use client";

import { PropsWithChildren } from "react";
import Container from "@/components/ui/Container/Container";
import css from "./dBHeader.module.css";
import Line from "@/components/ui/decorations/Line";
import Badge from "@/components/ui/Badge/Badge";
import { Url } from "next/dist/shared/lib/router/router";
import Icon from "@/components/ui/Icon/Icon";
import { usePathname } from "next/navigation";

interface DBHeaderProps {
  narrow?: boolean;
  headline: string;
  byline?: string;
  status?: string;
  editLink?: Url;
}

export default function DBHeader({
  children,
  narrow,
  headline,
  byline,
  status,
  editLink,
}: PropsWithChildren<DBHeaderProps>) {
  const pathname = usePathname();

  let badgeColor: ColorOptions = status === "archived" ? "danger" : "warning";

  return (
    <header className={css.dashboard_header}>
      <Container
        maxWidth={narrow ? "35rem" : ""}
        className={css.dashboard_container}
      >
        {editLink && (
          <div className={css.dashboard_header_admin_bar}>
            {pathname === editLink ? (
              <Icon
                icon="chevron_left"
                label="Back to league"
                size="h4"
                href={`./`}
              />
            ) : (
              <Icon icon="edit" label="Edit League" href={editLink} size="h4" />
            )}
          </div>
        )}
        <div className={css.dashboard_header_content}>
          <h1>
            {headline}{" "}
            {status && status !== "public" && (
              <Badge text={status} type={badgeColor} fontSize="h4" />
            )}
          </h1>
          {byline && <p>{byline}</p>}
        </div>

        {children}
        <Line marginStart="base" marginEnd="l" height="xs" />
      </Container>
    </header>
  );
}
