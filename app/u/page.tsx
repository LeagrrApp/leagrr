import { isLoggedIn } from "@/actions/auth";
import { redirect } from "next/navigation";

export default async function Page() {
  const userData = await isLoggedIn();

  redirect(`/u/${userData.username}`);
}
