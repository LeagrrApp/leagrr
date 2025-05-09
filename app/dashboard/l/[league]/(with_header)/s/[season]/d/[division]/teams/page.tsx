import { getDivision, getDivisionMetaInfo } from "@/actions/divisions";
import { getTeamsByDivisionId, getTeamsByLeagueId } from "@/actions/teams";
import DivisionInvite from "@/components/dashboard/divisions/DivisionInvite/DivisionInvite";
import DivisionTeams from "@/components/dashboard/divisions/DivisionTeams/DivisionTeams";
import LeagueTeams from "@/components/dashboard/divisions/LeagueTeams/LeagueTeams";
import BackButton from "@/components/ui/BackButton/BackButton";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { notFound } from "next/navigation";
import css from "./page.module.css";

type PageProps = {
  params: Promise<{ division: string; season: string; league: string }>;
};

export async function generateMetadata({ params }: PageProps) {
  const { division, season, league } = await params;

  const { data: divisionMetaData } = await getDivisionMetaInfo(
    division,
    season,
    league,
    { prefix: "Manage Teams" },
  );

  return divisionMetaData;
}

export default async function Page({ params }: PageProps) {
  const { division, season, league } = await params;

  const { data: divisionData } = await getDivision(division, season, league);

  if (!divisionData) notFound();

  const backLink = createDashboardUrl({ l: league, s: season, d: division });

  const { data: divisionTeams } = await getTeamsByDivisionId(
    divisionData.division_id,
  );

  const { data: leagueTeams } = await getTeamsByLeagueId(
    divisionData.league_id,
    { excludeDivision: divisionData.division_id },
  );

  return (
    <div className={css.layout}>
      <div className={css.division_teams}>
        <BackButton href={backLink} label="Back to division" />
        <h3 className="push-m">Division Teams</h3>
        {divisionTeams && divisionTeams?.length > 0 ? (
          <DivisionTeams teams={divisionTeams} division={divisionData} />
        ) : (
          <p>
            There are no teams in this division! Add teams from below, or send
            the invite code out to teams to automatically join!
          </p>
        )}
      </div>

      <div className={css.division_teams}>
        {leagueTeams && leagueTeams?.length > 0 && (
          <>
            <h3>League Teams</h3>
            <p className="push-m">
              The teams found in this list are members of other divisions or
              other seasons and can be quick added to the current division.
            </p>
            <LeagueTeams teams={leagueTeams} division={divisionData} />
          </>
        )}
      </div>

      <div>
        <DivisionInvite division={divisionData} />
      </div>
    </div>
  );
}
