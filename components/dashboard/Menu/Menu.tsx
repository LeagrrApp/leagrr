import { logOut } from "@/actions/auth";
import Button from "@/components/ui/Button/Button";
import Link from "next/link";
import { redirect } from "next/navigation";
import css from "./menu.module.css";
import { getSession } from "@/lib/session";
import Icon from "@/components/ui/Icon/Icon";
import { apply_classes } from "@/utils/helpers/html-attributes";
import Logout from "../Logout/Logout";

export default async function Menu() {
  const session = await getSession();

  return (
    <header id="menu" className={css.menu}>
      <Link className={css.menu_logo} href="/dashboard">
        Leagrr
      </Link>

      <nav className={css.menu_nav}>
        <h2 className={css.menu_heading}>Teams</h2>
        <ul className={css.menu_list}>
          <li>
            <Icon
              href="/dashboard/t/otterwa-senators"
              className={css.menu_item}
              label="Otterwa Senators"
              icon="groups"
            />
          </li>
          <li>
            <Icon
              href="/dashboard/t/frostbiters"
              className={css.menu_item}
              label="Frostbitters"
              icon="groups"
            />
          </li>
        </ul>

        <ul className={apply_classes([css.menu_list, css.menu_actions])}>
          {session?.userData.user_role === 1 && (
            <li>
              <Icon
                href="/dashboard/admin/"
                className={css.menu_item}
                label="Admin"
                icon="admin_panel_settings"
              />
            </li>
          )}
          <li>
            <Icon
              href="/dashboard/settings"
              className={css.menu_item}
              label="Settings"
              icon="settings"
            />
          </li>
          <li>
            {/* <Icon
              href="/logout"
              className={apply_classes([css.menu_item, css.menu_logout])}
              label="Log Out"
              icon="logout"
            /> */}

            <Logout />
          </li>
        </ul>
      </nav>

      {/* <form
        action={async () => {
          "use server";
          await logOut();
          redirect("/sign-in");
        }}
      >
        <Button type="submit">Log Out</Button>
      </form> */}
    </header>
  );
}
