import Menu from "@/components/dashboard/Menu/Menu";
import SkipLinks from "@/components/ui/accessibility/SkipLinks";
import css from "./layout.module.css";
import { getSession } from "@/lib/session";
import { getUserDashboardMenuData } from "@/actions/users";
import { redirect } from "next/navigation";

export default async function Layout({
  children,
}: {
  children: React.ReactNode;
}) {
  const session = await getSession();
  if (!session) redirect("/sign-in");

  const userDashboardMenuData = await getUserDashboardMenuData(
    session?.userData.user_id
  );

  const skipLinks: BasicLink[] = [
    {
      href: "#menu",
      text: "Skip to menu",
    },
    {
      href: "#main",
      text: "Skip to main area",
    },
  ];

  return (
    <div className={css.dashboard}>
      <SkipLinks links={skipLinks} />

      <Menu
        userData={session?.userData}
        userDashboardMenuData={userDashboardMenuData}
      />

      <main id="main">{children}</main>
    </div>
  );
}
