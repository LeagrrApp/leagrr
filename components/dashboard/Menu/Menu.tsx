"use client";

import Link from "next/link";
import css from "./menu.module.css";
import Icon from "@/components/ui/Icon/Icon";
import { apply_classes } from "@/utils/helpers/html-attributes";
import Image from "next/image";
import Alert from "@/components/ui/Alert/Alert";
import { PropsWithChildren, useState } from "react";
import Toggle from "@/components/ui/Toggle/Toggle";
import { logOut } from "@/actions/auth";
import ModalConfirmAction from "@/components/dashboard/ModalConfirmAction/ModalConfirmAction";
import { usePathname } from "next/navigation";

interface MenuProps {
  userData: UserData;
  menuData: {
    teams: MenuItemData[];
    leagues: MenuItemData[];
  };
}

export default function Menu({ userData, menuData }: MenuProps) {
  const pathname = usePathname();
  const [menuOpen, setMenuOpen] = useState(false);

  const imgUrl = null;

  const { teams, leagues } = menuData;

  return (
    <header id="menu" className={css.menu}>
      <Link className={css.menu_logo} href="/dashboard">
        Leagrr
      </Link>

      <Link
        className={css.menu_item}
        href={`/dashboard/u/${userData?.username}`}
        aria-current={pathname.includes(`/dashboard/u/${userData?.username}`)}
      >
        {imgUrl ? (
          <Image
            className={css.menu_item_pic}
            src={imgUrl}
            alt={`${userData?.first_name} ${userData?.last_name}`}
            width="50"
            height="50"
          />
        ) : (
          <span className={css.menu_item_letters}>
            {userData?.first_name?.substring(0, 1)}
            {userData?.last_name?.substring(0, 1)}
          </span>
        )}
        <span>
          {userData?.first_name} {userData?.last_name?.substring(0, 1)}.
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
        <h2 className={css.menu_heading}>Teams</h2>
        <ul className={css.menu_list}>
          {teams.map((team) => (
            <li key={team.slug}>
              <Link
                className={css.menu_item}
                href={`/dashboard/t/${team.slug}`}
                aria-current={pathname.includes(`/dashboard/t/${team.slug}`)}
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
              aria-current={pathname === `/dashboard/t`}
            />
          </li>
        </ul>

        {(leagues.length > 0 || userData.user_role === (1 || 2)) && (
          <>
            <h2 className={css.menu_heading}>Leagues</h2>
            <ul className={css.menu_list}>
              {leagues.map((league) => (
                <li key={league.slug}>
                  <Link
                    className={css.menu_item}
                    href={`/dashboard/l/${league.slug}`}
                    aria-current={pathname.includes(
                      `/dashboard/l/${league.slug}`
                    )}
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
              {userData.user_role === (1 || 2) && (
                <li>
                  <Icon
                    className={css.menu_item}
                    icon="add_circle"
                    label="Create a league"
                    href="/dashboard/l/"
                    aria-current={pathname === `/dashboard/l`}
                  />
                </li>
              )}
            </ul>
          </>
        )}

        <ul className={apply_classes([css.menu_list, css.menu_actions])}>
          {userData.user_role === 1 && (
            <li>
              <Icon
                href="/dashboard/admin/"
                className={css.menu_item}
                label="Admin"
                icon="admin_panel_settings"
                aria-current={pathname === `/dashboard/admin`}
              />
            </li>
          )}
          <li>
            <Icon
              href="/dashboard/settings"
              className={css.menu_item}
              label="Settings"
              icon="settings"
              aria-current={pathname === `/dashboard/settings`}
            />
          </li>
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
