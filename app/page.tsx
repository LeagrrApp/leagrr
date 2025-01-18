import { redirect } from "next/navigation";
import { verifySession } from "@/lib/session";

export default async function Page() {
  await verifySession();

  redirect("/dashboard");
}
