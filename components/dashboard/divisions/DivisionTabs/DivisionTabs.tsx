"use client";

import Icon from "@/components/ui/Icon/Icon";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { applyClasses } from "@/utils/helpers/html-attributes";
import Link from "next/link";
import { useParams, usePathname } from "next/navigation";
import css from "./divisionTabs.module.css";

type DivisionProps = {
  divisions: DivisionData[];
  canAdd: boolean;
};

export default function DivisionTabs({ divisions, canAdd }: DivisionProps) {
  const params = useParams();
  const pathname = usePathname();

  const { league, season, division } = params;

  if (typeof league !== "string" || typeof season !== "string") return null;

  const classes = [css.division_tabs];

  if (canAdd) classes.push(css.division_tabs_can_add);

  let tabLinkAddition: string | undefined = undefined;

  if (
    pathname ===
    createDashboardUrl(
      {
        l: league,
        s: season,
        d: division as string,
      },
      "teams",
    )
  )
    tabLinkAddition = "teams";

  return (
    <nav className={applyClasses(classes)}>
      <ol className={css.division_tabs_list}>
        {divisions.map((div) => {
          const url = createDashboardUrl(
            {
              l: league,
              s: season,
              d: div.slug,
            },
            tabLinkAddition,
          );

          let icon: string | undefined;

          if (div.gender !== "all") {
            icon = div.gender === "women" ? "female" : "male";
          }

          return (
            <li key={div.slug}>
              <Link
                className={css.division_tabs_item}
                href={url}
                aria-current={
                  `${pathname}/`.includes(`${url}/`) ? "page" : undefined
                }
              >
                <div className={css.division_tabs_item_inner}>
                  <span>{div.name}</span>
                  {icon && <i className="material-symbols-outlined">{icon}</i>}
                </div>
              </Link>
            </li>
          );
        })}
      </ol>
      {canAdd && (
        <Icon
          className={css.division_tabs_add}
          href={createDashboardUrl({ l: league, s: season }, "d")}
          icon="add_circle"
          label="Add division"
          hideLabel
        />
      )}
    </nav>
  );
}
