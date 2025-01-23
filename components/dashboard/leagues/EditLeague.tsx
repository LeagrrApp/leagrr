"use client";

import { editLeague } from "@/actions/leagues";
import Button from "@/components/ui/Button/Button";
import Container from "@/components/ui/Container/Container";
import Input from "@/components/ui/forms/Input";
import Select from "@/components/ui/forms/Select";
import TextArea from "@/components/ui/forms/TextArea";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import { sports_options, status_options } from "@/lib/definitions";
import { Url } from "next/dist/shared/lib/router/router";
import { useActionState } from "react";

interface EditLeagueProps {
  league: LeagueData;
  backLink: Url;
}

export default function EditLeague({ league, backLink }: EditLeagueProps) {
  const [state, action, pending] = useActionState(editLeague, undefined);

  return (
    <form className="push" action={action}>
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
          choices={sports_options}
          selected={league.sport_id}
        />
        <Select
          label="status"
          name="status"
          choices={status_options}
          selected={league.status}
          errors={{ errs: state?.errors?.status, type: "danger" }}
        />
        <input type="hidden" name="league_id" value={league.league_id} />
        <Col>
          <Button type="submit" fullWidth disabled={pending}>
            <i className="material-symbols-outlined">save</i>
            Save League
          </Button>
        </Col>
        <Col>
          <Button href={backLink} fullWidth variant="grey">
            <i className="material-symbols-outlined">cancel</i>
            Cancel
          </Button>
        </Col>
      </Grid>
    </form>
  );
}
