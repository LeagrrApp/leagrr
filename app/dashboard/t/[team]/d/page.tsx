import { getTeam } from "@/actions/teams";
import { createMetaTitle } from "@/utils/helpers/formatting";

type PageParams = {
  params: Promise<{ team: string; division: string }>;
};

export async function generateMetadata({ params }: PageParams) {
  const { team } = await params;

  const { data: teamData } = await getTeam(team);

  const titleArray = teamData?.name ? [teamData.name, "Teams"] : ["Teams"];

  return {
    title: createMetaTitle(titleArray),
    description: teamData?.description,
  };
}

export default async function Page({ params }: PageParams) {
  return (
    <>
      <h2>D</h2>
    </>
  );
}
