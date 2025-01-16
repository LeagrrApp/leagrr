"use client";

import { PropsWithChildren } from "react";
import Container from "@/components/ui/Container/Container";
import css from "./dBHeader.module.css";
import Line from "@/components/ui/decorations/Line";
import Badge from "@/components/ui/Badge/Badge";
import { Url } from "next/dist/shared/lib/router/router";
import Icon from "@/components/ui/Icon/Icon";
import { usePathname, useRouter } from "next/navigation";
import ButtonInvis from "@/components/ui/ButtonInvis/ButtonInvis";

interface DBHeaderProps {
  narrow?: boolean;
  headline: string;
  byline?: string;
  status?: string;
  settingsLink?: Url;
}

export default function DBHeader({
  children,
  narrow,
  headline,
  byline,
  status,
  settingsLink,
}: PropsWithChildren<DBHeaderProps>) {
  const pathname = usePathname();
  const router = useRouter();

  let badgeColor: ColorOptions = status === "archived" ? "danger" : "warning";

  return (
    <header className={css.dashboard_header}>
      <Container
        maxWidth={narrow ? "35rem" : ""}
        className={css.dashboard_container}
      >
        {settingsLink && (
          <div className={css.dashboard_header_admin_bar}>
            {pathname.includes("settings") ? (
              <ButtonInvis
                onClick={() => router.back()}
                aria-label="Click to return to league page"
              >
                <Icon icon="chevron_left" label="Back to league" size="h4" />
              </ButtonInvis>
            ) : (
              <Icon
                icon="settings"
                label="Edit settings"
                href={settingsLink}
                size="h4"
              />
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
