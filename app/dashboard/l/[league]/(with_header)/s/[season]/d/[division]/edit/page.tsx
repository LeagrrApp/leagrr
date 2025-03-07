import {
  deleteDivision,
  getDivision,
  getDivisionMetaInfo,
} from "@/actions/divisions";
import { canEditLeague } from "@/actions/leagues";
import EditDivision from "@/components/dashboard/divisions/EditDivision";
import ModalConfirmAction from "@/components/dashboard/ModalConfirmAction/ModalConfirmAction";
import BackButton from "@/components/ui/BackButton/BackButton";
import Card from "@/components/ui/Card/Card";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { notFound, redirect } from "next/navigation";

type PageProps = {
  params: Promise<{ division: string; season: string; league: string }>;
};

export async function generateMetadata({ params }: PageProps) {
  const { division, season, league } = await params;

  const { data: divisionMetaData } = await getDivisionMetaInfo(
    division,
    season,
    league,
    { prefix: "Edit" },
  );

  return divisionMetaData;
}

export default async function Page({ params }: PageProps) {
  const { division, season, league } = await params;

  const { data: divisionData } = await getDivision(division, season, league);

  if (!divisionData) notFound();

  const backLink = createDashboardUrl({ l: league, s: season, d: division });

  // check to see if user can edit this league
  const { canEdit } = await canEditLeague(divisionData.league_id);

  if (!canEdit) redirect(backLink);

  return (
    <>
      <BackButton href={backLink} label="Back to division" />
      <Card padding="l">
        <h3 className="push-m">Division Information</h3>
        <EditDivision division={divisionData} divisionLink={backLink} />
        <ModalConfirmAction
          defaultState={{
            link: createDashboardUrl({ l: league, s: season }),
            data: {
              division_id: divisionData.division_id,
              league_id: divisionData.league_id,
            },
          }}
          actionFunction={deleteDivision}
          confirmationHeading={`Are you sure you want to delete ${divisionData.name}?`}
          confirmationByline={`This action is permanent cannot be undone. Consider setting the division's status to "Archived" instead.`}
          trigger={{
            icon: "delete",
            label: "Delete Division",
            buttonStyles: {
              variant: "danger",
              fullWidth: true,
            },
          }}
          typeToConfirm={{
            type: "division",
            confirmString: `${league}/${season}/${division}`,
          }}
        />
      </Card>
    </>
  );
}
