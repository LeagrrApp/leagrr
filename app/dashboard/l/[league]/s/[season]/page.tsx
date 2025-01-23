import { canEditLeague } from "@/actions/leagues";
import { getSeason } from "@/actions/seasons";
import Button from "@/components/ui/Button/Button";
import Container from "@/components/ui/Container/Container";
import { notFound, redirect } from "next/navigation";

export default async function Page({
  params,
}: {
  params: Promise<{ season: string; league: string }>;
}) {
  const { season, league } = await params;

  const { data } = await getSeason(season, league, true);

  if (!data) notFound();

  // check if there are any divisions, redirect to first division
  if (data.divisions && data.divisions[0]) {
    redirect(`/dashboard/l/${league}/s/${season}/d/${data.divisions[0].slug}`);
  }

  const { canEdit } = await canEditLeague(league);

  return (
    <Container>
      <h2 className="push">
        It looks like this season does not have any divisions yet.
      </h2>
      {canEdit && (
        <Button href={`/dashboard/l/${league}/s/${season}/d/`}>
          Create division
        </Button>
      )}
    </Container>
  );
}
