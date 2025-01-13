import Link from "next/link";
import css from "./menu.module.css";
import { getSession } from "@/lib/session";
import Icon from "@/components/ui/Icon/Icon";
import { apply_classes } from "@/utils/helpers/html-attributes";
import Logout from "../Logout/Logout";
import Image from "next/image";
import profilePic from "./profile.jpg";

export default async function Menu() {
  const session = await getSession();

  return (
    <header id="menu" className={css.menu}>
      <Link className={css.menu_logo} href="/dashboard">
        Leagrr
      </Link>

      <Link
        className={css.menu_profile}
        href={`/dashboard/u/${session?.userData?.username}`}
      >
        {profilePic ? (
          <Image
            className={css.menu_profile_pic}
            src={profilePic}
            alt={`${session?.userData?.first_name} ${session?.userData?.last_name}`}
            width="50"
            height="50"
          />
        ) : (
          <span className={css.menu_profile_letters}>
            {session?.userData?.first_name?.substring(0, 1)}
            {session?.userData?.last_name?.substring(0, 1)}
          </span>
        )}
        <span>Profile</span>
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

        <h2 className={css.menu_heading}>Leagues</h2>
        <ul className={css.menu_list}>
          <li>
            <Icon
              href="/dashboard/l/ottawa-pride-hockey"
              className={css.menu_item}
              label="Ottawa Pride Hockey"
              icon="trophy"
            />
          </li>
          <li>
            <Icon
              href="/dashboard/l/hometown-hockey"
              className={css.menu_item}
              label="Hometown Hockey"
              icon="trophy"
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
