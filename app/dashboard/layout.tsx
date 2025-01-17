import Menu from "@/components/dashboard/Menu/Menu";
import SkipLinks from "@/components/ui/accessibility/SkipLinks";
import css from "./layout.module.css";
import { verifySession } from "@/lib/session";
import { getDashboardMenuData } from "@/actions/users";

export default async function Layout({
  children,
}: {
  children: React.ReactNode;
}) {
  const userData = await verifySession();
  const dashboardMenuData = await getDashboardMenuData();

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

      <Menu userData={userData} userDashboardMenuData={dashboardMenuData} />

      <main id="main">{children}</main>
    </div>
  );
}
