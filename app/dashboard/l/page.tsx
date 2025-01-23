import DHeader from "@/components/dashboard/DHeader/DHeader";
import LeagueHeader from "@/components/dashboard/leagues/LeagueHeader/LeagueHeader";
import CreateLeague from "@/components/dashboard/leagues/CreateLeague";
import Container from "@/components/ui/Container/Container";
import { verifySession } from "@/lib/session";
import { redirect } from "next/navigation";

export default async function Page() {
  const { user_id, user_role } = await verifySession();

  if (user_role !== (1 || 2)) redirect("/dashboard");

  return (
    <>
      <DHeader>
        <h1>Create a League</h1>
      </DHeader>
      <Container>
        <CreateLeague user_id={user_id} />
      </Container>
    </>
  );
}
