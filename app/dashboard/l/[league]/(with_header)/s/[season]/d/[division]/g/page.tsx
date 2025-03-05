import {
  getDivision,
  getDivisionMetaInfo,
  getDivisionOptionsForGames,
} from "@/actions/divisions";
import { canEditLeague } from "@/actions/leagues";
import CreateGame from "@/components/dashboard/games/CreateGame";
import BackButton from "@/components/ui/BackButton/BackButton";
import Card from "@/components/ui/Card/Card";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import Link from "next/link";
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
    { prefix: "Create Game" },
  );

  return divisionMetaData;
}

export default async function Page({ params }: PageProps) {
  const { division, season, league } = await params;

  const { data: divisionData } = await getDivision(division, season, league);

  if (!divisionData) notFound();

  const { canEdit } = await canEditLeague(league);

  const backLink = createDashboardUrl({ l: league, s: season, d: division });

  if (!canEdit) redirect(backLink);

  const { data: addGameData } = await getDivisionOptionsForGames(
    divisionData.division_id,
  );

  if (!addGameData) {
    return (
      <>
        <BackButton href={backLink} label="Back to division" />
        <Card padding="l">
          <h3 className="push">Unable to Create Game</h3>
          <p>
            There was an error loading necessary data in order to create a game.
            Try reloading the page.
          </p>
        </Card>
      </>
    );
  }

  if (addGameData.teams.length < 2 || addGameData.locations.length === 0) {
    return (
      <>
        <BackButton href={backLink} label="Back to division" />
        <Card padding="l">
          <h3 className="push">Set Up Incomplete</h3>
          <p className="push-m">
            It is not possible to create a game in this division because{" "}
            {addGameData.teams.length < 2 && "the division"}
            {addGameData.teams.length < 2 &&
              addGameData.locations.length === 0 &&
              " and "}
            {addGameData.locations.length === 0 && "the league"}
            {addGameData.teams.length < 2 && addGameData.locations.length === 0
              ? " are "
              : " is "}{" "}
            not set up properly:
          </p>
          <ul>
            {addGameData.teams.length < 2 && (
              <li>
                There must be at least two (2) teams in this division to create
                a game.
              </li>
            )}
            {addGameData.locations.length === 0 && (
              <li>
                This league has no venues. Add a venue in the{" "}
                <Link
                  href={createDashboardUrl({ l: league }, "settings/venues")}
                >
                  league venue settings page
                </Link>{" "}
                to create a game.
              </li>
            )}
          </ul>
        </Card>
      </>
    );
  }
  return (
    <>
      <BackButton href={backLink} label="Back to division" />
      <Card padding="l">
        <h3 className="push">Add game</h3>
        <CreateGame
          addGameData={addGameData}
          league_id={divisionData.league_id}
          division_id={divisionData.division_id}
          backLink={backLink}
        />
      </Card>
    </>
  );
}
