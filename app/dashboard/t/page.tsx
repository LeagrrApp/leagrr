import DHeader from "@/components/dashboard/DHeader/DHeader";
import Container from "@/components/ui/Container/Container";
import { verifySession } from "@/lib/session";

export default async function Page() {
  await verifySession();

  return (
    <DHeader>
      <h1>Add a team</h1>
      <p>
        You can either create a new team, or join an existing one with a join
        code.
      </p>
    </DHeader>
  );
}
