import UserList from "@/components/dashboard/admin/UserList/UserList";
import { createMetaTitle } from "@/utils/helpers/formatting";

export async function generateMetadata() {
  return {
    title: createMetaTitle(["Users", "Admin Portal"]),
  };
}

export default function Page() {
  return (
    <>
      <h2>Users</h2>
      <UserList />
    </>
  );
}
