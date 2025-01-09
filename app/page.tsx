import { redirect } from "next/navigation";
import { isLoggedIn } from "@/actions/auth";

export default async function Page() {
  isLoggedIn();

  redirect("/dashboard");
}
