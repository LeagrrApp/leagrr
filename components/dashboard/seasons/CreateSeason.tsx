"use client";

import { createSeason } from "@/actions/seasons";
import Alert from "@/components/ui/Alert/Alert";
import Button from "@/components/ui/Button/Button";
import Input from "@/components/ui/forms/Input";
import TextArea from "@/components/ui/forms/TextArea";
import Icon from "@/components/ui/Icon/Icon";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import { useActionState } from "react";

interface CreateSeasonProps {
  league_id: number;
  backLink: string;
}

export default function CreateSeason({
  league_id,
  backLink,
}: CreateSeasonProps) {
  const [state, action, pending] = useActionState(createSeason, undefined);

  return (
    <form action={action}>
      <Grid cols={{ xs: 1, m: 2 }} gap="base">
        <Col fullSpan>
          <Input
            name="name"
            label="Name"
            errors={{ errs: state?.errors?.name, type: "danger" }}
            required
          />
        </Col>
        <Col fullSpan>
          <TextArea
            name="description"
            label="Description"
            errors={{ errs: state?.errors?.description, type: "danger" }}
            optional
          />
        </Col>
        <Input
          type="date"
          name="start_date"
          label="Start Date"
          errors={{ errs: state?.errors?.start_date, type: "danger" }}
          required
        />
        <Input
          type="date"
          name="end_date"
          label="End Date"
          errors={{ errs: state?.errors?.end_date, type: "danger" }}
          required
        />
        <input type="hidden" name="league_id" value={league_id} />
        {state?.message && state.status !== 200 && (
          <Col fullSpan>
            <Alert alert={state.message} type="danger" />
          </Col>
        )}
        <Col>
          <Button type="submit" fullWidth disabled={pending}>
            <Icon icon="add_circle" label="Create Season" />
          </Button>
        </Col>
        <Col>
          <Button
            href={backLink}
            type="button"
            variant="grey"
            fullWidth
            disabled={pending}
          >
            <Icon icon="cancel" label="Cancel" />
          </Button>
        </Col>
      </Grid>
    </form>
  );
}
