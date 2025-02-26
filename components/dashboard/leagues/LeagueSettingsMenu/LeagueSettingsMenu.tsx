"use client";

import { deleteLeague } from "@/actions/leagues";
import Icon from "@/components/ui/Icon/Icon";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { usePathname } from "next/navigation";
import ModalConfirmAction from "../../ModalConfirmAction/ModalConfirmAction";

import css from "./leagueSettingsMenu.module.css";

interface LeagueSettingsMenuProps {
  league: LeagueData;
  canDelete: boolean;
}

export default function LeagueSettingsMenu({
  league,
  canDelete,
}: LeagueSettingsMenuProps) {
  const pathname = usePathname();

  const { slug, name, league_id } = league;

  return (
    <nav className={css.settings_menu}>
      <ul>
        <li>
          <Icon
            icon="info"
            label="League Info"
            padding={["ml", "base"]}
            href={createDashboardUrl({ l: slug }, "settings")}
            aria-current={
              pathname === createDashboardUrl({ l: slug }, "settings") ||
              undefined
            }
          />
        </li>
        <li>
          <Icon
            icon="home_pin"
            label="Venues"
            padding={["ml", "base"]}
            href={createDashboardUrl({ l: slug }, "settings/venues")}
            aria-current={
              pathname.includes(
                createDashboardUrl({ l: slug }, "settings/venue"),
              ) || undefined
            }
          />
        </li>
        {canDelete && (
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
            />
          </li>
        )}
      </ul>
    </nav>
  );
}
