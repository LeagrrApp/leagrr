"use client";
import { createDivision } from "@/actions/divisions";
import Alert from "@/components/ui/Alert/Alert";
import Button from "@/components/ui/Button/Button";
import Input from "@/components/ui/forms/Input";
import Select from "@/components/ui/forms/Select";
import TextArea from "@/components/ui/forms/TextArea";
import Icon from "@/components/ui/Icon/Icon";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import { gender_options } from "@/lib/definitions";
import { useRouter } from "next/navigation";
import { useActionState, useEffect } from "react";

interface CreateDivisionProps {
  season: SeasonData;
}

export default function CreateDivision({ season }: CreateDivisionProps) {
  const [state, action, pending] = useActionState(createDivision, undefined);
  const router = useRouter();

  useEffect(() => {
    console.log(state);
  }, [state]);

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
          type="number"
          name="tier"
          label="Tier"
          min="1"
          errors={{ errs: state?.errors?.tier, type: "danger" }}
          required
        />
        <Select
          name="gender"
          label="Gender"
          choices={gender_options}
          errors={{ errs: state?.errors?.gender, type: "danger" }}
          required
        />
        <input type="hidden" name="season_id" value={season.season_id} />
        <input type="hidden" name="league_id" value={season.league_id} />
        {state?.message && state.status !== 200 && (
          <Col fullSpan>
            <Alert alert={state.message} type="danger" />
          </Col>
        )}
        <Button type="submit" fullWidth disabled={pending}>
          <Icon icon="add_circle" label="Create Division" />
        </Button>
        <Button
          onClick={() => router.back()}
          type="button"
          variant="grey"
          fullWidth
        >
          <Icon icon="cancel" label="Cancel" />
        </Button>
      </Grid>
    </form>
  );
}
