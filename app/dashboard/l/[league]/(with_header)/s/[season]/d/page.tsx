import { getSeason, getSeasonMetaData } from "@/actions/seasons";
import CreateDivision from "@/components/dashboard/divisions/CreateDivision";
import Card from "@/components/ui/Card/Card";
import Container from "@/components/ui/Container/Container";
import { verifySession } from "@/lib/session";
import { notFound } from "next/navigation";

type PageProps = {
  params: Promise<{ season: string; league: string }>;
};

export async function generateMetadata({ params }: PageProps) {
  const { season, league } = await params;

  const { data: seasonData } = await getSeasonMetaData(season, league, {
    prefix: "Create Division",
  });

  return seasonData;
}

export default async function Page({ params }: PageProps) {
  await verifySession();

  const { league, season } = await params;

  const { data: seasonData } = await getSeason(season, league);

  if (!seasonData) notFound();

  return (
    <Container>
      <Card padding="l">
        <h2 className="push">New division</h2>
        <CreateDivision season={seasonData} />
      </Card>
    </Container>
  );
}
