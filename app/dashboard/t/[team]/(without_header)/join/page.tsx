import { getTeam } from "@/actions/teams";
import JoinTeam from "@/components/dashboard/teams/JoinTeam/JoinTeam";
import { createMetaTitle } from "@/utils/helpers/formatting";
import { notFound } from "next/navigation";

type PageParams = {
  params: Promise<{ team: string }>;
  searchParams: Promise<{ join_code: string }>;
};

export async function generateMetadata({ params }: PageParams) {
  const { team } = await params;

  const { data: teamData } = await getTeam(team);

  if (!teamData) return null;

  const titleArray = ["Join", teamData.name, "Teams"];

  return {
    title: createMetaTitle(titleArray),
    description: teamData?.description,
  };
}

export default async function Page({ params, searchParams }: PageParams) {
  const { team } = await params;
  const { join_code } = await searchParams;

  // get team data
  const { data: teamData } = await getTeam(team);

  // redirect if team not found
  if (!teamData) notFound();

  return (
    <>
      <JoinTeam team={teamData} join_code={join_code} />
    </>
  );
}
