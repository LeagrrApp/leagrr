import { getDashboardMenuData } from "@/actions/users";
import Menu from "@/components/dashboard/Menu/Menu";
import SkipLinks from "@/components/ui/accessibility/SkipLinks";
import { verifySession } from "@/lib/session";
import css from "./layout.module.css";

export default async function Layout({
  children,
}: {
  children: React.ReactNode;
}) {
  const userData = await verifySession();
  const { data } = await getDashboardMenuData();

  if (!data)
    throw new Error(
      "Sorry, an error occurred and we were unable to load your data.",
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

      <Menu userData={userData} menuData={data} />

      <main id="main" className={css.main}>
        {children}
      </main>
    </div>
  );
}
