"use client";

import { joinDivision } from "@/actions/divisions";
import Alert from "@/components/ui/Alert/Alert";
import Button from "@/components/ui/Button/Button";
import Card from "@/components/ui/Card/Card";
import Container from "@/components/ui/Container/Container";
import Input from "@/components/ui/forms/Input";
import Select from "@/components/ui/forms/Select";
import Icon from "@/components/ui/Icon/Icon";
import IconSport from "@/components/ui/Icon/IconSport";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import { useSearchParams } from "next/navigation";
import { useActionState } from "react";
import css from "./joinDivision.module.css";

interface JoinDivisionProps {
  division: DivisionData;
  league?: LeagueData;
  teams?: TeamData[];
  backLink: string;
}

export default function JoinDivision({
  division,
  league,
  teams,
  backLink,
}: JoinDivisionProps) {
  const searchParams = useSearchParams();
  const [state, action, pending] = useActionState(joinDivision, {
    link: backLink,
    data: {},
  });

  const { name, division_id } = division;

  if (!teams || teams.length < 1) {
    return (
      <div
        className={css.join_division}
        data-league-name={league?.name}
        data-division-name={division.name}
      >
        <div className={css.league_info} aria-hidden="true">
          <span className={css.division_name}>{division.name}</span>
          {league?.name && (
            <span className={css.league_name}>{league.name}</span>
          )}
        </div>
        <Container maxWidth="35rem">
          <Card padding="l">
            <h1 className="push-ml">Sorry</h1>
            <p className="push">
              You don&apos;t manage any teams or all of the teams you manage are
              already assigned to this division.
            </p>
            <Button href="/dashboard/">
              <Icon icon="chevron_left" label="Go back" />
            </Button>
          </Card>
        </Container>
      </div>
    );
  }

  const team_choices = teams.map((t) => {
    return {
      value: t.team_id,
      label: t.name,
    };
  });

  return (
    <div className={css.join_division}>
      <div className={css.league_info} aria-hidden="true">
        <span className={css.division_name}>{division.name}</span>
        {league?.name && <span className={css.league_name}>{league.name}</span>}
      </div>
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
                <IconSport
                  sport={league?.sport || "group_add"}
                  label="Join Division"
                />
              </Button>
            </Grid>
          </form>
        </Card>
      </Container>
    </div>
  );
}
