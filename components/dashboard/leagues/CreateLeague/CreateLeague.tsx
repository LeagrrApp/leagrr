"use client";

import { createLeague } from "@/actions/leagues";
import Button from "@/components/ui/Button/Button";
import Container from "@/components/ui/Container/Container";
import Input from "@/components/ui/forms/Input";
import Select from "@/components/ui/forms/Select";
import TextArea from "@/components/ui/forms/TextArea";
import Grid from "@/components/ui/layout/Grid";
import { useActionState, useEffect } from "react";

interface CreateLeagueProps {
  user_id: number;
}

export default function CreateLeague({ user_id }: CreateLeagueProps) {
  const [state, action, pending] = useActionState(createLeague, undefined);

  useEffect(() => {
    console.log(state);
  }, [state]);

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

  return (
    <Container maxWidth="35rem">
      <form action={action}>
        <Grid gap="base">
          <h1>Create a League</h1>
          <Input
            label="Name"
            name="name"
            defaultValue="Hockey Time Party"
            errors={{ errs: state?.errors?.name, type: "danger" }}
            required
          />
          <TextArea
            label="Description"
            name="description"
            value="This is a great hockey league!"
            errors={{ errs: state?.errors?.description, type: "danger" }}
            optional
          />
          <Select
            label="Sport"
            name="sport_id"
            choices={sports}
            errors={{ errs: state?.errors?.status, type: "danger" }}
          />
          <input type="hidden" name="user_id" value={user_id} />
          <Button type="submit">Create League</Button>
        </Grid>
      </form>
    </Container>
  );
}
