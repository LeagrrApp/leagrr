import { verifyUserRole } from "@/actions/users";
import AdminHeader from "@/components/dashboard/admin/AdminHeader/AdminHeader";
import TabbedSide from "@/components/dashboard/TabbedSide/TabbedSide";
import { TabbedSideMenu } from "@/components/dashboard/TabbedSide/TabbedSideMenu";
import TabbedSideWorking from "@/components/dashboard/TabbedSide/TabbedSideWorking";
import Container from "@/components/ui/Container/Container";
import { verifySession } from "@/lib/session";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { notFound } from "next/navigation";
import { PropsWithChildren } from "react";

export default async function Layout({ children }: PropsWithChildren) {
  // confirm user is logged in, if not, redirect
  await verifySession();

  const isAdmin = await verifyUserRole(1);

  if (!isAdmin) notFound();

  const menuItems = [
    {
      icon: "person",
      label: "Users",
      url: createDashboardUrl({ admin: "u" }),
    },
    {
      icon: "trophy",
      label: "Leagues",
      url: createDashboardUrl({ admin: "l" }),
    },
    {
      icon: "group",
      label: "Teams",
      url: createDashboardUrl({ admin: "t" }),
    },
  ];

  return (
    <>
      <AdminHeader />
      <Container>
        <TabbedSide>
          <TabbedSideMenu menuItems={menuItems} />
          <TabbedSideWorking>{children}</TabbedSideWorking>
        </TabbedSide>
      </Container>
    </>
  );
}
