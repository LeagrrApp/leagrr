import { canEditLeague } from "@/actions/leagues";
import { deleteSeason, getSeason } from "@/actions/seasons";
import ModalConfirmAction from "@/components/dashboard/ModalConfirmAction/ModalConfirmAction";
import EditSeason from "@/components/dashboard/seasons/EditSeason";
import Container from "@/components/ui/Container/Container";
import Icon from "@/components/ui/Icon/Icon";
import { notFound, redirect } from "next/navigation";

export default async function Page({
  params,
}: {
  params: Promise<{ season: string; league: string }>;
}) {
  const { season, league } = await params;

  const { data: seasonData } = await getSeason(season, league);

  if (!seasonData) notFound();

  const backLink = `/dashboard/l/${league}/s/${season}`;

  // check to see if user can edit this league
  const { canEdit } = await canEditLeague(seasonData.league_id);

  if (!canEdit) redirect(backLink);

  return (
    <Container>
      <Icon
        icon="chevron_left"
        label="Back to season"
        size="h4"
        href={backLink}
        className="push"
      />
      <h2 className="push">Edit Season</h2>
      <EditSeason backLink={backLink} season={seasonData} />
      {canEdit && (
        <ModalConfirmAction
          defaultState={{
            season_id: seasonData.season_id,
            league_id: seasonData.league_id,
            backLink: `/dashboard/l/${league}/`,
          }}
          actionFunction={deleteSeason}
          confirmationHeading={`Are you sure you want to delete ${seasonData.name}?`}
          confirmationByline={`This action is permanent cannot be undone. Consider setting the season's status to "Archived" instead.`}
          trigger={{
            icon: "delete",
            label: "Delete Season",
            buttonStyles: {
              variant: "danger",
              fullWidth: true,
            },
          }}
        />
      )}
    </Container>
  );
}
