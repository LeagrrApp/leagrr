"use client";

import { logOut } from "@/actions/auth";
import ModalConfirmAction from "@/components/dashboard/ModalConfirmAction/ModalConfirmAction";
import Icon from "@/components/ui/Icon/Icon";
import Toggle from "@/components/ui/Toggle/Toggle";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { applyClasses } from "@/utils/helpers/html-attributes";
import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";
import css from "./menu.module.css";

interface MenuProps {
  userData: UserSessionData;
  menuData: {
    teams: MenuItemData[];
    leagues: MenuItemData[];
  };
}

export default function Menu({ userData, menuData }: MenuProps) {
  const pathname = usePathname();
  const [menuOpen, setMenuOpen] = useState(false);

  useEffect(() => {
    setMenuOpen(false);
  }, [pathname]);

  const { username, first_name, last_name, user_role, img } = userData;

  const { teams, leagues } = menuData;

  const showLeaguesList = leagues.length > 0 || user_role <= 2;

  return (
    <header id="menu" className={css.menu}>
      <Link className={css.menu_logo} href="/dashboard">
        Leagrr
      </Link>

      <Link
        className={applyClasses(css.menu_item, css.menu_item_profile)}
        href={createDashboardUrl({ u: username })}
        aria-current={
          pathname.includes(createDashboardUrl({ u: username })) || undefined
        }
        // onClick={() => setMenuOpen(false)}
      >
        {img ? (
          <Image
            className={css.menu_item_pic}
            src={img}
            alt={`${first_name} ${last_name}`}
            width="50"
            height="50"
          />
        ) : (
          <span className={css.menu_item_letters}>
            {first_name?.substring(0, 1)}
            {last_name?.substring(0, 1)}
          </span>
        )}
        <span>
          {first_name} {last_name?.substring(0, 1)}.
        </span>
      </Link>

      <Toggle
        active={menuOpen}
        className={css.menu_toggle}
        onClick={() => setMenuOpen(!menuOpen)}
        aria-label="Click to open navigation"
      />

      <nav
        className={`${
          menuOpen ? `${css.menu_nav} ${css.menu_nav_open}` : css.menu_nav
        }`}
      >
        {showLeaguesList && (
          <>
            <h2 className={css.menu_heading}>Leagues</h2>
            <ul className={css.menu_list}>
              {leagues.map((league) => (
                <li key={league.slug}>
                  <Link
                    className={css.menu_item}
                    href={createDashboardUrl({ l: league.slug })}
                    aria-current={
                      pathname.includes(
                        createDashboardUrl({ l: league.slug }),
                      ) || undefined
                    }
                    // onClick={() => setMenuOpen(false)}
                  >
                    {league.img ? (
                      <Image
                        className={css.menu_item_pic}
                        src={league.img}
                        alt={league.name}
                        width="50"
                        height="50"
                      />
                    ) : (
                      <span className={css.menu_item_letters}>
                        {league.name.substring(0, 1)}
                      </span>
                    )}
                    <span>{league.name}</span>
                  </Link>
                </li>
              ))}
              {user_role <= 2 && (
                <li>
                  <Icon
                    className={css.menu_item}
                    icon="add_circle"
                    label="Create a league"
                    href="/dashboard/l/"
                    aria-current={pathname === `/dashboard/l` || undefined}
                    // onClick={() => setMenuOpen(false)}
                  />
                </li>
              )}
            </ul>
          </>
        )}

        <h2 className={css.menu_heading}>Teams</h2>
        <ul className={css.menu_list}>
          {teams.map((team) => (
            <li key={team.slug}>
              <Link
                className={css.menu_item}
                href={createDashboardUrl({ t: team.slug })}
                aria-current={
                  pathname.includes(createDashboardUrl({ t: team.slug })) ||
                  undefined
                }
                // onClick={() => setMenuOpen(false)}
              >
                {team.img ? (
                  <Image
                    className={css.menu_item_pic}
                    src={team.img}
                    alt={team.name}
                    width="50"
                    height="50"
                  />
                ) : (
                  <span className={css.menu_item_letters}>
                    {team.name.substring(0, 1)}
                  </span>
                )}
                <span>{team.name}</span>
              </Link>
            </li>
          ))}
          <li>
            <Icon
              className={css.menu_item}
              icon="add_circle"
              label="Add a team"
              href="/dashboard/t/"
              aria-current={pathname === `/dashboard/t` || undefined}
              // onClick={() => setMenuOpen(false)}
            />
          </li>
        </ul>

        <ul className={applyClasses([css.menu_list, css.menu_actions])}>
          {user_role === 1 && (
            <li>
              <Icon
                href="/dashboard/admin/"
                className={css.menu_item}
                label="Admin"
                icon="admin_panel_settings"
                aria-current={pathname === `/dashboard/admin` || undefined}
                // onClick={() => setMenuOpen(false)}
              />
            </li>
          )}
          {/* <li>
            <Icon
              href="/dashboard/settings"
              className={css.menu_item}
              label="Settings"
              icon="settings"
              aria-current={pathname === `/dashboard/settings` || undefined}
              onClick={() => setMenuOpen(false)}
            />
          </li> */}
          <li>
            <ModalConfirmAction
              actionFunction={logOut}
              confirmationHeading="Are you sure you want to log out?"
              trigger={{
                icon: "logout",
                label: "Sign Out",
                classes: css.menu_logout,
                buttonStyles: {
                  fullWidth: true,
                },
              }}
            />
          </li>
        </ul>
      </nav>
    </header>
  );
}
