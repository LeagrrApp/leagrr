"use client";

import { createSeason } from "@/actions/seasons";
import Button from "@/components/ui/Button/Button";
import Input from "@/components/ui/forms/Input";
import TextArea from "@/components/ui/forms/TextArea";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import { useRouter } from "next/navigation";
import { useActionState } from "react";

interface CreateSeasonProps {
  league_id: number;
}

export default function CreateSeason({ league_id }: CreateSeasonProps) {
  const [state, action, pending] = useActionState(createSeason, undefined);
  const router = useRouter();

  return (
    <form action={action}>
      <Grid cols={{ xs: 1, m: 2 }} gap="base">
        <Col fullSpan>
          <Input
            name="name"
            label="Name"
            errors={{ errs: state?.errors?.name, type: "danger" }}
            defaultValue="2025 Winter"
            required
          />
        </Col>
        <Col fullSpan>
          <TextArea
            name="description"
            label="Description"
            errors={{ errs: state?.errors?.description, type: "danger" }}
            defaultValue="Get your winter skate on!"
            optional
          />
        </Col>
        <Input
          type="date"
          name="start_date"
          label="Start Date"
          defaultValue="2025-01-01"
          errors={{ errs: state?.errors?.start_date, type: "danger" }}
          required
        />
        <Input
          type="date"
          name="end_date"
          label="End Date"
          defaultValue="2025-04-30"
          errors={{ errs: state?.errors?.end_date, type: "danger" }}
          required
        />
        <input type="hidden" name="league_id" value={league_id} />
        <Col>
          <Button type="submit" fullWidth disabled={pending}>
            Create Season
          </Button>
        </Col>
        <Col>
          <Button
            onClick={() => router.back()}
            type="button"
            variant="grey"
            fullWidth
          >
            Cancel
          </Button>
        </Col>
      </Grid>
    </form>
  );
}
