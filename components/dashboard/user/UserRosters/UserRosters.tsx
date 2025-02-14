import { getUserRostersWithStats } from "@/actions/users";
import Icon from "@/components/ui/Icon/Icon";
import DashboardUnit from "../../DashboardUnit/DashboardUnit";
import DashboardUnitHeader from "../../DashboardUnitHeader/DashboardUnitHeader";
import UserRosterItem from "../UserRosterItem/UserRosterItem";
import css from "./userRosters.module.css";

interface UserRostersProps {
  user?: UserData;
}

export default async function UserRosters({ user }: UserRostersProps) {
  const { data: userRosters } = await getUserRostersWithStats(user?.user_id);

  if (!userRosters) return null;

  return (
    <DashboardUnit className={css.user_roster} gridArea="teams">
      <DashboardUnitHeader>
        <h2 className="type-scale-h3">
          <Icon label="Current Teams" icon="groups" labelFirst gap="ml" />
        </h2>
      </DashboardUnitHeader>
      <div className={css.user_roster_grid}>
        {userRosters.map((team) => (
          <UserRosterItem
            key={team.rosterInfo.division_roster_id}
            team={team}
          />
        ))}
      </div>
    </DashboardUnit>
  );
}
