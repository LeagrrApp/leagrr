"use client";

import { deleteLeague } from "@/actions/leagues";
import Icon from "@/components/ui/Icon/Icon";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { usePathname } from "next/navigation";
import ModalConfirmAction from "../../ModalConfirmAction/ModalConfirmAction";

import css from "./leagueSettingsMenu.module.css";

interface LeagueSettingsMenuProps {
  league: LeagueData;
  commissionerPrivileges: boolean;
}

export default function LeagueSettingsMenu({
  league,
  commissionerPrivileges,
}: LeagueSettingsMenuProps) {
  const pathname = usePathname();

  const { slug, name, league_id } = league;

  const menuItems = [
    {
      icon: "info",
      label: "Information",
      url: createDashboardUrl({ l: slug }, "settings"),
    },
    {
      icon: "home_pin",
      label: "Venues",
      url: createDashboardUrl({ l: slug }, "settings/venues"),
    },
  ];

  if (commissionerPrivileges) {
    menuItems.push({
      icon: "admin_panel_settings",
      label: "Admins",
      url: createDashboardUrl({ l: slug }, "settings/admins"),
    });
  }
  return (
    <nav className={css.settings_menu}>
      <ul>
        {menuItems.map((item) => (
          <li key={item.url}>
            <Icon
              icon={item.icon}
              label={item.label}
              padding={["ml", "base"]}
              href={item.url}
              aria-current={pathname === item.url || undefined}
            />
          </li>
        ))}
        {commissionerPrivileges && (
          <li className={css.delete_item}>
            <ModalConfirmAction
              defaultState={{
                data: { league_id: league_id },
              }}
              actionFunction={deleteLeague}
              confirmationHeading={`Are you sure you want to delete ${name}?`}
              confirmationByline={`This action is permanent cannot be undone. Consider setting the league's status to "Archived" instead.`}
              trigger={{
                icon: "delete",
                label: "Delete league",
                classes: css.settings_delete,
                buttonStyles: {
                  variant: "danger",
                  fullWidth: true,
                  padding: ["ml", "base"],
                },
              }}
              typeToConfirm={{
                type: "league",
                confirmString: slug,
              }}
            />
          </li>
        )}
      </ul>
    </nav>
  );
}
