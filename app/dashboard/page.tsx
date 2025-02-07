import { getDashboardMenuData } from "@/actions/users";
import { verifySession } from "@/lib/session";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { redirect } from "next/navigation";

export default async function Page() {
  await verifySession();
  const { data } = await getDashboardMenuData();

  if (data?.leagues[0]) {
    redirect(createDashboardUrl({ l: data?.leagues[0].slug }));
  } else if (data?.teams[0]) {
    redirect(createDashboardUrl({ t: data?.teams[0].slug }));
  } else {
    redirect(`/dashboard/t/`);
  }
}
