import { isLoggedIn } from "@/actions/auth";
import DBHeader from "@/components/dashboard/DashboardHeader/DBHeader";

export default async function Page() {
  await isLoggedIn();

  return (
    <DBHeader>
      <h1>Join a team!</h1>
    </DBHeader>
  );
}
