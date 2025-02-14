import { getUser } from "@/actions/users";
import UserSnapshot from "@/components/dashboard/user/UserSnapshot/UserSnapshot";
import { verifySession } from "@/lib/session";
import { createMetaTitle } from "@/utils/helpers/formatting";
import { notFound } from "next/navigation";
import css from "./page.module.css";
import UserRosters from "@/components/dashboard/user/UserRosters/UserRosters";

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
  const { user_id: logged_user_id } = await verifySession();

  const { username } = await params;

  const { data: userData } = await getUser(username);

  if (!userData) {
    notFound();
  }

  const isCurrentUser = userData.user_id === logged_user_id;

  // TODO:  Things to include on profile:
  //        - basic details: name, username, pronoun/gender, profile pic/icon
  //        - up next: next game from any team/division
  //        - team history with basic team/player stats

  return (
    <div className={css.user_grid}>
      {isCurrentUser && <UserSnapshot user={userData} />}

      <UserRosters user={userData} />
    </div>
  );
}
