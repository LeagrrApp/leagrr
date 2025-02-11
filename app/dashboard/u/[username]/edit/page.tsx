import { canEditUser, getUser } from "@/actions/users";
import EditUser from "@/components/dashboard/user/EditUser";
import BackButton from "@/components/ui/BackButton/BackButton";
import { verifySession } from "@/lib/session";
import {
  createDashboardUrl,
  createMetaTitle,
} from "@/utils/helpers/formatting";
import { notFound } from "next/navigation";
import css from "./page.module.css";
import UpdatePassword from "@/components/dashboard/user/UpdatePassword";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ username: string }>;
}) {
  const { username } = await params;

  const { data: userData } = await getUser(username);

  if (!userData) return null;

  const name = `${userData.first_name} ${userData.last_name}`;

  const titleArray = ["Edit", name];

  return {
    title: createMetaTitle(titleArray),
  };
}

export default async function Page({
  params,
}: {
  params: Promise<{ username: string }>;
}) {
  const { username } = await params;

  const { data: userData } = await getUser(username);

  if (!userData) {
    notFound();
  }

  const { isCurrentUser } = await canEditUser(username);

  const backLink = createDashboardUrl({ u: username });

  const { first_name } = userData;

  return (
    <>
      <BackButton href={backLink} label={`Back to ${first_name}'s page`} />
      <h2 className="push">Edit User</h2>
      <div className={css.layout}>
        <EditUser user={userData} />
        <UpdatePassword user={userData} isCurrentUser={isCurrentUser} />
      </div>
    </>
  );
}
