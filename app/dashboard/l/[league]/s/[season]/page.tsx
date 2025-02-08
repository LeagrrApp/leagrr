import { canEditLeague } from "@/actions/leagues";
import { getSeason } from "@/actions/seasons";
import Button from "@/components/ui/Button/Button";
import Container from "@/components/ui/Container/Container";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { notFound, redirect } from "next/navigation";

export default async function Page({
  params,
}: {
  params: Promise<{ season: string; league: string }>;
}) {
  const { season, league } = await params;

  const { data: seasonData } = await getSeason(season, league, true);

  if (!seasonData) notFound();

  // check if there are any divisions, redirect to first division
  if (seasonData.divisions && seasonData.divisions[0]) {
    redirect(
      createDashboardUrl({
        l: league,
        s: season,
        d: seasonData.divisions[0].slug,
      }),
    );
  }

  const { canEdit } = await canEditLeague(seasonData.league_id);

  return (
    <Container>
      <h2 className="push">
        It looks like this season does not have any divisions yet.
      </h2>
      {canEdit && (
        <Button
          href={createDashboardUrl(
            {
              l: league,
              s: season,
            },
            "d",
          )}
        >
          Create division
        </Button>
      )}
    </Container>
  );
}
