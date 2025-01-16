import DBHeader from "@/components/dashboard/DashboardHeader/DBHeader";
import { verifySession } from "@/lib/session";

export default async function Page() {
  await verifySession();

  return (
    <DBHeader
      headline="Add a team"
      byline="You can either create a new team, or join an existing one with a join code."
    />
  );
}
