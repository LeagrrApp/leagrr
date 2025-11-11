import { verifySession } from "@/lib/session";
import { createDashboardUrl } from "@/utils/formatting";
import { redirect } from "next/navigation";

export default async function Page() {
  const { username } = await verifySession();

  redirect(createDashboardUrl({ u: username }));
}
