import { getUserGamePreviews } from "@/actions/users";
import GamePreview from "../../games/GamePreview/GamePreview";
import DashboardUnit from "../../DashboardUnit/DashboardUnit";
import DashboardUnitHeader from "../../DashboardUnitHeader/DashboardUnitHeader";
import Icon from "@/components/ui/Icon/Icon";
import Card from "@/components/ui/Card/Card";

interface UserSnapshotProps {
  user: UserData;
}

export default async function UserSnapshot({ user }: UserSnapshotProps) {
  // get next game for any division team
  const nextGame = await getUserGamePreviews(user.user_id);

  // get most recent completed game for any division team
  const prevGame = await getUserGamePreviews(user.user_id, true);

  return (
    <>
      <DashboardUnit>
        <DashboardUnitHeader>
          <h2>
            <Icon label="Next Game" icon="event_upcoming" labelFirst gap="m" />
          </h2>
        </DashboardUnitHeader>
        {nextGame ? (
          <GamePreview game={nextGame} includeGameLink />
        ) : (
          <Card padding="base">
            <p>You have no upcoming games.</p>
          </Card>
        )}
      </DashboardUnit>
      <DashboardUnit>
        <DashboardUnitHeader>
          <h2>
            <Icon label="Last Game" icon="event_available" labelFirst gap="m" />
          </h2>
        </DashboardUnitHeader>
        {prevGame ? (
          <GamePreview game={prevGame} includeGameLink />
        ) : (
          <Card padding="base">
            <p>You have no completed games.</p>
          </Card>
        )}
      </DashboardUnit>
    </>
  );
}
