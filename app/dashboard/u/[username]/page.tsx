import { getUser } from "@/actions/users";
import UserHeader from "@/components/dashboard/user/UserHeader/UserHeader";
import Container from "@/components/ui/Container/Container";
import Icon from "@/components/ui/Icon/Icon";
import { verifySession } from "@/lib/session";
import {
  createDashboardUrl,
  createMetaTitle,
} from "@/utils/helpers/formatting";
import { notFound } from "next/navigation";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ username: string }>;
}) {
  const { username } = await params;

  const { data: userData } = await getUser(username);

  if (!userData) return null;

  const name = `${userData.first_name} ${userData.last_name}`;

  const titleArray = [name];

  return {
    title: createMetaTitle(titleArray),
  };
}

export default async function Page({
  params,
}: {
  params: Promise<{ username: string }>;
}) {
  const userSession = await verifySession();

  const { username } = await params;
  const currentUser = username === userSession.username;

  const { data: userData } = await getUser(username);

  if (!userData) {
    notFound();
  }

  // TODO:  Things to include on profile:
  //        - basic details: name, username, pronoun/gender, profile pic/icon
  //        - up next: next game from any team/division
  //        - team history with basic team/player stats

  return (
    <>
      <h2>User Page</h2>
    </>
  );
}
