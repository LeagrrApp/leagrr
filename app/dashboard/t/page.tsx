import DHeader from "@/components/dashboard/DHeader/DHeader";
import CreateTeam from "@/components/dashboard/teams/CreateTeam";
import JoinTeamByCode from "@/components/dashboard/teams/JoinTeamByCode/JoinTeamByCode";
import Container from "@/components/ui/Container/Container";
import { verifySession } from "@/lib/session";
import { createMetaTitle } from "@/utils/helpers/formatting";
import { Metadata } from "next";
import css from "./page.module.css";

export const metadata: Metadata = {
  title: createMetaTitle(["Add Team"]),
};

export default async function Page() {
  const { user_id } = await verifySession();

  return (
    <>
      <DHeader>
        <h1>Add a team</h1>
        <p>
          You can either create a new team, or join an existing one with a join
          code.
        </p>
      </DHeader>
      <Container className={css.add_team_grid}>
        <div>
          <h2 className="push">Create Team</h2>
          <CreateTeam user_id={user_id} />
        </div>
        <JoinTeamByCode />
      </Container>
    </>
  );
}
