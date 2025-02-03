import CreateLeague from "@/components/dashboard/leagues/CreateLeague/CreateLeague";
import { verifySession } from "@/lib/session";
import { redirect } from "next/navigation";

export default async function Page() {
  const { user_id, user_role } = await verifySession();

  if (user_role !== (1 || 2)) redirect("/dashboard");

  return <CreateLeague user_id={user_id} />;
}
