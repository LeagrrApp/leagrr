import { getDashboardMenuData } from "@/actions/users";
import { verifySession } from "@/lib/session";
import { redirect } from "next/navigation";

export default async function Page() {
  await verifySession();
  const { data } = await getDashboardMenuData();

  if (data?.leagues[0]) {
    redirect(`/dashboard/l/${data?.leagues[0].slug}/`);
  } else if (data?.teams[0]) {
    redirect(`/dashboard/t/${data?.teams[0].slug}/`);
  } else {
    redirect(`/dashboard/t/`);
  }
}
