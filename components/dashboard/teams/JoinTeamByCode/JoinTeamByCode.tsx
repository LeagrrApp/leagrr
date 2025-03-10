"use client";

import { joinTeamByCode } from "@/actions/teamMemberships";
import Alert from "@/components/ui/Alert/Alert";
import Button from "@/components/ui/Button/Button";
import Card from "@/components/ui/Card/Card";
import Input from "@/components/ui/forms/Input";
import Icon from "@/components/ui/Icon/Icon";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import { useActionState } from "react";

export default function JoinTeamByCode() {
  const [state, action, pending] = useActionState(joinTeamByCode, undefined);

  return (
    <Card padding="l">
      <form action={action}>
        <Grid gap="base">
          <h2>Join Team</h2>
          <p>Join an existing team with the team&apos;s join code!</p>
          <Input name="join_code" label="Join Code" required />

          {state?.message && state.status !== 200 && (
            <Col fullSpan>
              <Alert alert={state.message} type="danger" />
            </Col>
          )}
          <Button type="submit" disabled={pending}>
            <Icon icon="group" label="Join Team" />
          </Button>
        </Grid>
      </form>
    </Card>
  );
}
