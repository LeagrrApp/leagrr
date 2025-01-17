import DBHeader from "@/components/dashboard/DashboardHeader/DBHeader";
import CreateLeague from "@/components/dashboard/leagues/CreateLeague";
import Container from "@/components/ui/Container/Container";
import { verifySession } from "@/lib/session";
import { redirect } from "next/navigation";

export default async function Page() {
  const { user_id, user_role } = await verifySession();

  if (user_role !== (1 || 2)) redirect("/dashboard");

  return (
    <>
      <DBHeader headline="Create a League" />
      <Container>
        <CreateLeague user_id={user_id} />
      </Container>
    </>
  );
}
