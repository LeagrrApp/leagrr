import { getTeam } from "@/actions/teams";
import { createMetaTitle } from "@/utils/helpers/formatting";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ team: string }>;
}) {
  const { team } = await params;

  const { data: teamData } = await getTeam(team);

  const titleArray = teamData?.name
    ? ["Edit", teamData.name, "Teams"]
    : ["Edit", "Teams"];

  return {
    title: createMetaTitle(titleArray),
    description: teamData?.description,
  };
}

export default async function Page({
  params,
}: {
  params: Promise<{ team: string }>;
}) {
  const { team } = await params;

  // get team data
  const { data: teamData } = await getTeam(team);

  return (
    <>
      <h2>Edit</h2>
    </>
  );
}
