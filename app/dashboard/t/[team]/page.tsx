import { getTeam } from "@/actions/teams";
import TeamHeader from "@/components/dashboard/teams/TeamHeader/TeamHeader";
import { notFound } from "next/navigation";

export default async function Page({
  params,
}: {
  params: Promise<{ team: string }>;
}) {
  const { team } = await params;

  const { data: teamData } = await getTeam(team);

  console.log(teamData);

  if (!teamData) notFound();

  return (
    <>
      <TeamHeader team={teamData} canEdit={true} />
    </>
  );
}
