import CreateLeague from "@/components/dashboard/leagues/CreateLeague/CreateLeague";
import { verifySession } from "@/lib/session";
import { createMetaTitle } from "@/utils/helpers/formatting";
import { redirect } from "next/navigation";

export async function generateMetadata() {
  return {
    title: createMetaTitle(["Create League"]),
    description: "Create a new league.",
  };
}

export default async function Page() {
  const { user_id, user_role } = await verifySession();

  if (user_role !== (1 || 2)) redirect("/dashboard");

  return <CreateLeague user_id={user_id} />;
}
