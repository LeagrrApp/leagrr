import {
  getAllTeamMembers,
  getDivisionTeamId,
  getTeam,
  getTeamDivisionRoster,
} from "@/actions/teams";
import ActiveRoster from "@/components/dashboard/teams/ActiveRoster/ActiveRoster";
import InactiveRoster from "@/components/dashboard/teams/InactiveRoster/InactiveRoster";
import Alert from "@/components/ui/Alert/Alert";
import Icon from "@/components/ui/Icon/Icon";
import {
  createDashboardUrl,
  createMetaTitle,
} from "@/utils/helpers/formatting";
import { get_unique_items_by_key } from "@/utils/helpers/objects";
import { notFound } from "next/navigation";
import css from "./page.module.css";
import TeamInvite from "@/components/dashboard/teams/TeamInvite/TeamInvite";
import BackButton from "@/components/ui/BackButton/BackButton";

type PageParams = {
  params: Promise<{ team: string; id: string }>;
};

export async function generateMetadata({ params }: PageParams) {
  const { team } = await params;

  const { data: teamData } = await getTeam(team);

  if (!teamData) return null;

  const titleArray = ["Manage Roster", teamData.name, "Teams"];

  return {
    title: createMetaTitle(titleArray),
    description: teamData?.description,
  };
}

export default async function Page({ params }: PageParams) {
  const { team, id } = await params;

  const division_id = parseInt(id as string);

  // get team data
  const { data: teamData } = await getTeam(team);

  // redirect if team not found
  if (!teamData) notFound();

  const backLink = createDashboardUrl({ t: team, d: id });

  const { team_id } = teamData;

  const { data: division_team_id } = await getDivisionTeamId(
    team_id,
    division_id,
  );
  const { data: teamMembers } = await getAllTeamMembers(team_id);
  const { data: divisionRoster } = await getTeamDivisionRoster(
    team_id,
    division_id,
  );

  if (!teamMembers || !divisionRoster || !division_team_id)
    return (
      <>
        <BackButton label="Back to team" href={backLink} />

        <h2>Manage Roster</h2>
        <Alert
          alert="Sorry, team member lists could not be loaded."
          type="danger"
        />
      </>
    );

  const inActiveTeamMembers = get_unique_items_by_key(
    teamMembers,
    divisionRoster,
    "user_id",
  );

  return (
    <>
      <BackButton label="Back to team" href={backLink} />

      <h2 className="push">Manage Roster</h2>

      <div className={css.layout}>
        <div className={css.active}>
          <ActiveRoster team_id={team_id} teamMembers={divisionRoster} />
        </div>
        <div className={css.inactive}>
          <InactiveRoster
            team_id={team_id}
            teamMembers={inActiveTeamMembers}
            division_team_id={division_team_id}
          />
        </div>
        <div className={css.invite}>
          <TeamInvite team={teamData} division_id={division_id} />
        </div>
      </div>
    </>
  );
}
