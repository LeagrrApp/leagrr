import { getDivisionsByTeam, getTeam } from "@/actions/teams";
import Button from "@/components/ui/Button/Button";
import {
  createDashboardUrl,
  createMetaTitle,
} from "@/utils/helpers/formatting";
import { notFound, redirect } from "next/navigation";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ team: string }>;
}) {
  const { team } = await params;

  const { data: teamData } = await getTeam(team);

  const titleArray = teamData?.name ? [teamData.name, "Teams"] : ["Teams"];

  return {
    title: createMetaTitle(titleArray),
    description: teamData?.description,
  };
}

export default async function Page({
  params,
  searchParams,
}: {
  params: Promise<{ team: string }>;
  searchParams: Promise<{ [key: string]: string | undefined }>;
}) {
  const { team } = await params;
  const { div: queryDiv } = await searchParams;

  // get team data
  const { data: teamData } = await getTeam(team);

  // redirect if team not found
  if (!teamData) notFound();

  const { team_id } = teamData;

  // get list of public divisions the team is currently in
  const { data: divisions } = await getDivisionsByTeam(team_id);

  if (!divisions || divisions.length === 0) {
    return (
      <>
        <h2>This team is not in any divisions yet.</h2>
        <Button href="#">Join a division</Button>
      </>
    );
  }

  // Redirect to division page
  const currentDivision = divisions.find((d) => {
    if (!d.start_date || !d.end_date) {
      return false;
    }

    const now = new Date(Date.now());

    return d.start_date < now && now < d.end_date;
  });

  if (currentDivision) {
    redirect(createDashboardUrl({ t: team, d: currentDivision.division_id }));
  }

  redirect(createDashboardUrl({ t: team, d: divisions[0].division_id }));
}
