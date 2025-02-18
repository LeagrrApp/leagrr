import { getUser, getUserMetaData } from "@/actions/users";
import UserRosters from "@/components/dashboard/user/UserRosters/UserRosters";
import UserSnapshot from "@/components/dashboard/user/UserSnapshot/UserSnapshot";
import { verifySession } from "@/lib/session";
import { notFound } from "next/navigation";
import css from "./page.module.css";

type PageProps = {
  params: Promise<{ username: string }>;
};

export async function generateMetadata({ params }: PageProps) {
  const { username } = await params;

  const { data: userMetaData } = await getUserMetaData(username);

  return userMetaData;
}

export default async function Page({ params }: PageProps) {
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
