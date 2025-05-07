"use client";

import { getDivisionToJoinAsTeam, joinDivision } from "@/actions/divisions";
import Alert from "@/components/ui/Alert/Alert";
import Button from "@/components/ui/Button/Button";
import Card from "@/components/ui/Card/Card";
import Container from "@/components/ui/Container/Container";
import Input from "@/components/ui/forms/Input";
import Icon from "@/components/ui/Icon/Icon";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { useActionState, useEffect, useState } from "react";

interface TeamJoinDivisionProps {
  team_id: number;
  team_slug: string;
}

export default function TeamJoinDivision({
  team_id,
  team_slug,
}: TeamJoinDivisionProps) {
  const [joinCodeValue, setJoinCodeValue] = useState<string>("");

  const [divisionToJoin, setDivisionToJoin] = useState<
    DivisionData | undefined
  >(undefined);

  const [inDivision, setInDivision] = useState<boolean>(false);

  const [findState, findAction, findPending] = useActionState(
    getDivisionToJoinAsTeam,
    {
      data: {},
    },
  );

  const [joinState, joinAction, joinPending] = useActionState(joinDivision, {
    data: {},
    link: createDashboardUrl({ t: team_slug, d: divisionToJoin?.division_id }),
  });

  useEffect(() => {
    if (findState?.data.division) {
      setDivisionToJoin(findState?.data.division);
    } else {
      setDivisionToJoin(undefined);
    }

    if (findState?.data.inDivision) {
      setInDivision(true);
    } else {
      setInDivision(false);
    }
  }, [findState]);

  return (
    <Container maxWidth="35rem" noPadding>
      <Card padding="l">
        <h2 className="push">Join Division</h2>
        {divisionToJoin ? (
          <>
            <form action={joinAction}>
              <Grid gap="base" cols={{ xs: 1, m: 2 }}>
                <Col fullSpan>
                  <h4>{divisionToJoin.name}</h4>
                  <p>
                    {divisionToJoin.season_name} — {divisionToJoin.league_name}
                  </p>
                </Col>
                {inDivision && (
                  <Col fullSpan>
                    <Alert
                      alert="Your team is already in this division!"
                      type="warning"
                    />
                  </Col>
                )}
                <input type="hidden" name="join_code" value={joinCodeValue} />
                <input type="hidden" name="team_id" value={team_id} />
                <input
                  type="hidden"
                  name="division_id"
                  value={divisionToJoin.division_id}
                />
                {joinState?.message && joinState.status !== 200 && (
                  <Col fullSpan>
                    <Alert alert={joinState.message} type="danger" />
                  </Col>
                )}
                <Button type="submit" disabled={inDivision || joinPending}>
                  <Icon icon="add_circle" label="Join Division" />
                </Button>
                <Button
                  type="button"
                  variant="grey"
                  onClick={() => {
                    setDivisionToJoin(undefined);
                    setInDivision(true);
                  }}
                >
                  <Icon icon="cancel" label="Cancel" />
                </Button>
              </Grid>
            </form>
          </>
        ) : (
          <form action={findAction}>
            <Grid gap="base" cols={{ xs: 1 }}>
              <Input
                name="join_code"
                label="Join Code"
                value={joinCodeValue}
                onChange={(e) => setJoinCodeValue(e.target.value)}
                required
              />
              <input type="hidden" value={team_id} name="team_id" />
              {findState?.message && findState.status !== 200 && (
                <Col fullSpan>
                  <Alert alert={findState.message} type="danger" />
                </Col>
              )}
              <Button type="submit" disabled={findPending}>
                <Icon icon="search" label="Search" />
              </Button>
            </Grid>
          </form>
        )}
      </Card>
    </Container>
  );
}
