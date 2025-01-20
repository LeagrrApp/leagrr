import { canEditLeague } from "@/actions/leagues";
import { getSeason } from "@/actions/seasons";
import DivisionTabs from "@/components/dashboard/DivisionTabs/DivisionTabs";
import Container from "@/components/ui/Container/Container";
import { notFound } from "next/navigation";
import { PropsWithChildren } from "react";

export default async function Layout({
  children,
  params,
}: PropsWithChildren<{
  params: Promise<{ league: string; season: string }>;
}>) {
  const { season, league } = await params;

  const { data } = await getSeason(season, league, true);

  if (!data) notFound();

  // check to see if user can edit this league
  const { canEdit } = await canEditLeague(data.league_id);

  return (
    <Container>
      {data?.divisions && data.divisions.length !== 0 && (
        <DivisionTabs divisions={data.divisions} canAdd={canEdit} />
      )}
      {children}
    </Container>
  );
}
