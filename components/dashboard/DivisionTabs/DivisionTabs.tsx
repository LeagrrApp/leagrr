"use client";

import Link from "next/link";
import css from "./divisionTabs.module.css";
import { useParams, usePathname } from "next/navigation";

type DivisionProps = {
  divisions: DivisionData[];
};

export default function DivisionTabs({ divisions }: DivisionProps) {
  const params = useParams();
  const pathname = usePathname();

  return (
    <nav className={css.division_tabs}>
      <ul className={css.division_tabs_list}>
        {divisions.map((div) => {
          const url = `/dashboard/l/${params.league}/s/${params.season}/d/${div.slug}`;

          let icon: string | undefined;

          if (div.gender !== "All") {
            icon = div.gender === "Women" ? "female" : "male";
          }

          return (
            <li key={div.slug}>
              <Link
                className={css.division_tabs_item}
                href={url}
                aria-current={url === pathname ? "page" : undefined}
              >
                <div className={css.division_tabs_item_inner}>
                  <span>{div.name}</span>
                  {icon && <i className="material-symbols-outlined">{icon}</i>}
                </div>
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
