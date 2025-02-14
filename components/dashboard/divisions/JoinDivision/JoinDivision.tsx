"use client";

import { joinDivision } from "@/actions/divisions";
import Alert from "@/components/ui/Alert/Alert";
import Button from "@/components/ui/Button/Button";
import Card from "@/components/ui/Card/Card";
import Container from "@/components/ui/Container/Container";
import Input from "@/components/ui/forms/Input";
import Select from "@/components/ui/forms/Select";
import Icon from "@/components/ui/Icon/Icon";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import { useSearchParams } from "next/navigation";
import { useActionState } from "react";
import css from "./joinDivision.module.css";

interface JoinDivisionProps {
  division: DivisionData;
  teams: TeamData[];
  backLink: string;
}

export default function JoinDivision({
  division,
  teams,
  backLink,
}: JoinDivisionProps) {
  const searchParams = useSearchParams();
  const [state, action, pending] = useActionState(joinDivision, {
    link: backLink,
    data: {},
  });

  const { name, division_id } = division;

  const team_choices = teams.map((t) => {
    return {
      value: t.team_id,
      label: t.name,
    };
  });

  return (
    <div className={css.join_division}>
      <Container maxWidth="35rem">
        <Card padding="l">
          <form action={action}>
            <Grid gap="base" cols={{ xs: 1, m: 2 }}>
              <Col fullSpan>
                <h1>Join {name}</h1>
              </Col>
              <Input
                name="name"
                label="Team"
                defaultValue={name}
                disabled={true}
              />
              <Select
                name="team_id"
                label="Team"
                choices={team_choices}
                required
              />
              <input type="hidden" name="division_id" value={division_id} />
              <Col fullSpan>
                <Input
                  name="join_code"
                  label="Join Code"
                  defaultValue={searchParams.get("join_code") || ""}
                />
              </Col>
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
