"use client";

import { joinTeam } from "@/actions/teams";
import Alert from "@/components/ui/Alert/Alert";
import Button from "@/components/ui/Button/Button";
import Card from "@/components/ui/Card/Card";
import Container from "@/components/ui/Container/Container";
import Input from "@/components/ui/forms/Input";
import Select from "@/components/ui/forms/Select";
import Icon from "@/components/ui/Icon/Icon";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import { CSSProperties, useActionState, useEffect } from "react";
import css from "./joinTeam.module.css";
import { applyColor } from "@/utils/helpers/formatting";

interface JoinTeamProps {
  team: TeamData;
  join_code?: string;
  division_id?: number;
}

interface JoinTeamStyles extends CSSProperties {
  "--color-team"?: string;
}

export default function JoinTeam({
  team,
  join_code,
  division_id,
}: JoinTeamProps) {
  const [state, action, pending] = useActionState(joinTeam, undefined);

  const styles: JoinTeamStyles = {};

  if (team.color) styles["--color-team"] = applyColor(team.color);

  return (
    <div
      style={styles}
      className={css.join_team_wrap}
      data-team-name={team.name}
    >
      <Container maxWidth="35rem">
        <Card padding="l">
          <form action={action}>
            <Grid gap="base" cols={{ xs: 1, m: 2 }}>
              <Col fullSpan>
                <h1>Join {division_id ? "Roster" : "Team"}</h1>
              </Col>
              <Input
                name="name"
                label="Team"
                defaultValue={team.name}
                disabled={true}
              />
              <input type="hidden" name="team_id" value={team.team_id} />
              <Input
                name="join_code"
                label="Join Code"
                defaultValue={join_code}
              />
              {division_id && (
                <>
                  <input type="hidden" name="division_id" value={division_id} />
                  <Input
                    name="number"
                    label="Number"
                    min="1"
                    max="98"
                    defaultValue="1"
                    errors={{ errs: state?.errors?.number, type: "danger" }}
                  />
                  <Select
                    name="position"
                    label="Position"
                    choices={[
                      "Center",
                      "Right Wing",
                      "Left Wing",
                      "Defense",
                      "Goalie",
                    ]}
                    errors={{ errs: state?.errors?.position, type: "danger" }}
                  />
                </>
              )}
              {state?.message && (
                <Col fullSpan>
                  <Alert alert={state.message} type="danger" />
                </Col>
              )}
              <Button type="submit" disabled={pending}>
                <Icon icon="group_add" label="Join Team" />
              </Button>
            </Grid>
          </form>
        </Card>
      </Container>
    </div>
  );
}
