import { createDashboardUrl } from "@/utils/helpers/formatting";
import { redirect } from "next/navigation";

type PageParams = {
  params: Promise<{ team: string; division: string }>;
};

export default async function Page({ params }: PageParams) {
  const { team } = await params;

  redirect(createDashboardUrl({ t: team }));
}
