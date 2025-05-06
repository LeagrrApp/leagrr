import { canEditLeague } from "@/actions/leagues";
import { getSeason, getSeasonMetaData } from "@/actions/seasons";
import Button from "@/components/ui/Button/Button";
import Container from "@/components/ui/Container/Container";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { notFound, redirect } from "next/navigation";

type PageProps = {
  params: Promise<{ season: string; league: string }>;
};

export async function generateMetadata({ params }: PageProps) {
  const { season, league } = await params;

  const { data: seasonData } = await getSeasonMetaData(season, league);

  return seasonData;
}

export default async function Page({ params }: PageProps) {
  const { season, league } = await params;

  const { data: seasonData } = await getSeason(season, league, {
    includeDivisions: true,
  });

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
      <h2 className="push" style={{ width: "min(45rem, 100%)" }}>
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
