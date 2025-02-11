import { canEditUser, getUser } from "@/actions/users";
import EditUser from "@/components/dashboard/user/EditUser";
import UpdatePassword from "@/components/dashboard/user/UpdatePassword";
import BackButton from "@/components/ui/BackButton/BackButton";
import {
  createDashboardUrl,
  createMetaTitle,
} from "@/utils/helpers/formatting";
import { notFound, redirect } from "next/navigation";
import css from "./page.module.css";

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

  const backLink = createDashboardUrl({ u: username });

  const { canEdit, isCurrentUser } = await canEditUser(username);

  if (!canEdit) redirect(backLink);

  const { first_name } = userData;

  return (
    <>
      <BackButton
        href={backLink}
        label={`Back to ${isCurrentUser ? "your" : `${first_name}'s`} page`}
      />
      <h2 className="push">Edit User</h2>
      <div className={css.layout}>
        <EditUser user={userData} />
        <UpdatePassword user={userData} isCurrentUser={isCurrentUser} />
      </div>
    </>
  );
}
