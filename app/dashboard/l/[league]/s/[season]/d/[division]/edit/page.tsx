import { getDivision } from "@/actions/divisions";
import { canEditLeague } from "@/actions/leagues";
import { getSeason } from "@/actions/seasons";
import EditDivisionInfo from "@/components/dashboard/divisions/EditDivisionInfo";
import { notFound, redirect } from "next/navigation";

export default async function Page({
  params,
}: {
  params: Promise<{ division: string; season: string; league: string }>;
}) {
  const { division, season, league } = await params;

  const { data: divisionData } = await getDivision(division, season, league);

  if (!divisionData) notFound();

  const backLink = `/dashboard/l/${league}/s/${season}/d/${division}`;

  // check to see if user can edit this league
  const { canEdit } = await canEditLeague(divisionData.league_id);

  if (!canEdit) redirect(backLink);

  return (
    <>
      <h3>Division Information</h3>
      <EditDivisionInfo division={divisionData} divisionLink={backLink} />
    </>
  );
}
