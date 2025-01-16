"use client";

import { editLeague } from "@/actions/leagues";
import Button from "@/components/ui/Button/Button";
import Container from "@/components/ui/Container/Container";
import Input from "@/components/ui/forms/Input";
import Select from "@/components/ui/forms/Select";
import TextArea from "@/components/ui/forms/TextArea";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import { useActionState } from "react";

interface EditLeagueProps {
  league: LeagueData;
}

export default function EditLeague({ league }: EditLeagueProps) {
  const [state, action] = useActionState(editLeague, undefined);

  const sports = [
    {
      value: 1,
      label: "Hockey",
    },
    {
      value: 2,
      label: "Soccer",
    },
    {
      value: 3,
      label: "Basketball",
    },
    {
      value: 4,
      label: "Pickleball",
    },
    {
      value: 5,
      label: "Badminton",
    },
  ];

  const status_options = [
    {
      value: "draft",
      label: "Draft",
    },
    {
      value: "public",
      label: "Public",
    },
    {
      value: "archived",
      label: "Archived",
    },
  ];

  return (
    <form action={action}>
      <Grid gap="base" cols={{ xs: 1, m: 2 }}>
        <Col fullSpan>
          <Input
            label="Name"
            name="name"
            value={league.name}
            errors={{ errs: state?.errors?.name, type: "danger" }}
            required
          />
        </Col>
        <Col fullSpan>
          <TextArea
            label="Description"
            name="description"
            value={league.description}
            errors={{ errs: state?.errors?.description, type: "danger" }}
            optional
          />
        </Col>
        <Select
          label="Sport"
          name="sport_id"
          choices={sports}
          value={league.sport_id.toString()}
        />
        <Select
          label="status"
          name="status"
          choices={status_options}
          value={league.status}
          errors={{ errs: state?.errors?.status, type: "danger" }}
        />
        <input type="hidden" name="league_id" value={league.league_id} />
        <Col fullSpan>
          <Button type="submit" fullWidth>
            <i className="material-symbols-outlined">save</i>
            Save League
          </Button>
        </Col>
      </Grid>
    </form>
  );
}
