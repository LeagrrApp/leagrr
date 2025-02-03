import { getDivisionsByTeam, getTeam } from "@/actions/teams";
import TeamHeader from "@/components/dashboard/teams/TeamHeader/TeamHeader";
import { notFound } from "next/navigation";
import { PropsWithChildren } from "react";

export default async function Layout({
  params,
  children,
}: PropsWithChildren<{
  params: Promise<{ team: string }>;
}>) {
  const { team } = await params;

  // get team data
  const { data: teamData } = await getTeam(team);

  // redirect if team not found
  if (!teamData) notFound();

  const { team_id } = teamData;

  // get list of public divisions the team is currently in
  const { data: divisions } = await getDivisionsByTeam(team_id);

  return (
    <>
      <TeamHeader team={teamData} canEdit={true} divisions={divisions} />

      {children}
    </>
  );
}
