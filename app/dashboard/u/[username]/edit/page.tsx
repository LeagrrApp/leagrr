import { canEditUser, getUser, getUserMetaData } from "@/actions/users";
import EditUser from "@/components/dashboard/user/EditUser";
import UpdatePassword from "@/components/dashboard/user/UpdatePassword";
import BackButton from "@/components/ui/BackButton/BackButton";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { notFound, redirect } from "next/navigation";
import css from "./page.module.css";

type PageProps = {
  params: Promise<{ username: string }>;
};

export async function generateMetadata({ params }: PageProps) {
  const { username } = await params;

  const { data: userMetaData } = await getUserMetaData(username, {
    prefix: "Edit",
  });

  return userMetaData;
}

export default async function Page({ params }: PageProps) {
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
