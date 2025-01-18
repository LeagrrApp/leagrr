import { verifySession } from "@/lib/session";
import { redirect } from "next/navigation";

export default async function Page() {
  const { username } = await verifySession();

  redirect(`/dashboard/u/${username}`);
}
