"use client";
import { createDivision } from "@/actions/divisions";
import Button from "@/components/ui/Button/Button";
import Input from "@/components/ui/forms/Input";
import Select from "@/components/ui/forms/Select";
import TextArea from "@/components/ui/forms/TextArea";
import Icon from "@/components/ui/Icon/Icon";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import { gender_options, status_options } from "@/lib/definitions";
import { useRouter } from "next/navigation";
import { useActionState } from "react";

interface CreateDivisionProps {
  season: SeasonData;
}

export default function CreateDivision({ season }: CreateDivisionProps) {
  const [state, action, pending] = useActionState(createDivision, undefined);
  const router = useRouter();

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
        <Input
          type="text"
          name="join_code"
          label="Join Code"
          errors={{ errs: state?.errors?.join_code, type: "danger" }}
          optional
        />
        <Select
          name="status"
          label="Status"
          choices={status_options}
          errors={{ errs: state?.errors?.status, type: "danger" }}
        />
        <input type="hidden" name="season_id" value={season.season_id} />
        <input type="hidden" name="league_id" value={season.league_id} />
        <Col>
          <Button type="submit" fullWidth disabled={pending}>
            <Icon icon="add_circle" label="Create Division" />
          </Button>
        </Col>
        <Col>
          <Button
            onClick={() => router.back()}
            type="button"
            variant="grey"
            fullWidth
          >
            <Icon icon="cancel" label="Cancel" />
          </Button>
        </Col>
      </Grid>
    </form>
  );
}
