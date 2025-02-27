import { canEditLeague, getLeague } from "@/actions/leagues";
import LeagueSettingsMenu from "@/components/dashboard/leagues/LeagueSettingsMenu/LeagueSettingsMenu";
import BackButton from "@/components/ui/BackButton/BackButton";
import Card from "@/components/ui/Card/Card";
import Container from "@/components/ui/Container/Container";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { notFound, redirect } from "next/navigation";
import { PropsWithChildren } from "react";
import css from "./layout.module.css";

export default async function Layout({
  children,
  params,
}: PropsWithChildren<{
  params: Promise<{ league: string }>;
}>) {
  // get league slug
  const { league } = await params;

  // check user is has permission to access league settings
  const { data: leagueData } = await getLeague(league);

  // if league data not found, redirect
  if (!leagueData) notFound();

  // Get users role to check league permissions
  const { canEdit, isCommissioner, isAdmin } = await canEditLeague(
    leagueData.league_id,
  );
  const backLink = createDashboardUrl({ l: league });

  // If not a league admin, redirect back to league
  if (!canEdit) redirect(backLink);

  // Check if user has authority to delete
  const commissionerPrivileges = isCommissioner || isAdmin;

  return (
    <Container>
      <BackButton href={backLink} label="Back to league" />
      <Card className={css.settings_grid}>
        <LeagueSettingsMenu
          league={leagueData}
          commissionerPrivileges={commissionerPrivileges}
        />
        <div className={css.settings_work_area}>{children}</div>
      </Card>
    </Container>
  );
}
