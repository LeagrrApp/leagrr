import { canEditUser, getUser, verifyUserRole } from "@/actions/users";
import UserHeader from "@/components/dashboard/user/UserHeader/UserHeader";
import Container from "@/components/ui/Container/Container";
import { verifySession } from "@/lib/session";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { notFound } from "next/navigation";
import { PropsWithChildren } from "react";

export default async function Layout({
  params,
  children,
}: PropsWithChildren<{
  params: Promise<{ username: string }>;
}>) {
  const userSession = await verifySession();

  const { username } = await params;

  const { data: userData } = await getUser(username);

  if (!userData) {
    notFound();
  }

  const { canEdit } = await canEditUser(username);

  const editLink = createDashboardUrl({ u: username }, "edit");

  // TODO:  Things to include on profile:
  //        - basic details: name, username, pronoun/gender, profile pic/icon
  //        - up next: next game from any team/division
  //        - team history with basic team/player stats

  return (
    <>
      <UserHeader user={userData} canEdit={canEdit} editLink={editLink} />
      <Container className="pbe-l">{children}</Container>
    </>
  );
}
