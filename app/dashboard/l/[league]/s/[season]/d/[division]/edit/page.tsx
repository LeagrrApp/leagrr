import { deleteDivision, getDivision } from "@/actions/divisions";
import { canEditLeague } from "@/actions/leagues";
import EditDivisionInfo from "@/components/dashboard/divisions/EditDivisionInfo";
import ModalConfirmAction from "@/components/dashboard/ModalConfirmAction/ModalConfirmAction";
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
      <ModalConfirmAction
        defaultState={{
          division_id: divisionData.division_id,
          league_id: divisionData.league_id,
          backLink: `/dashboard/l/${league}/s/${season}`,
        }}
        actionFunction={deleteDivision}
        confirmationHeading={`Are you sure you want to delete ${divisionData.name}?`}
        confirmationByline={`This action is permanent cannot be undone. Consider setting the division's status to "Archived" instead.`}
        trigger={{
          icon: "delete",
          label: "Delete Season",
          buttonStyles: {
            variant: "danger",
            fullWidth: true,
          },
        }}
      />
    </>
  );
}
