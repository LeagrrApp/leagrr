import { canEditTeam, getDivisionsByTeam, getTeam } from "@/actions/teams";
import TeamHeader from "@/components/dashboard/teams/TeamHeader/TeamHeader";
import Container from "@/components/ui/Container/Container";
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

  // Check if user has edit permissions
  const { canEdit } = await canEditTeam(team);

  // get list of public divisions the team is currently in
  const { data: divisions } = await getDivisionsByTeam(team_id);

  return (
    <>
      <TeamHeader team={teamData} canEdit={canEdit} divisions={divisions} />

      <Container>{children}</Container>
    </>
  );
}
