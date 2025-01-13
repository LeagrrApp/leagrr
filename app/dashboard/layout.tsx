"use server";

import Menu from "@/components/dashboard/Menu/Menu";
import SkipLinks from "@/components/ui/accessibility/SkipLinks";
import css from "./layout.module.css";
import { isLoggedIn } from "@/actions/auth";
import { getSession } from "@/lib/session";
import { redirect } from "next/navigation";

export default async function Layout({
  children,
}: {
  children: React.ReactNode;
}) {
  // Check if user is logged in
  const session = await getSession();
  // redirect if not
  if (!session) redirect("/sign-in");

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

      <Menu />

      <main id="main" tabIndex={0}>
        {children}
      </main>
    </div>
  );
}
