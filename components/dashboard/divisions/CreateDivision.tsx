"use client";
import { createDivision } from "@/actions/divisions";
import Button from "@/components/ui/Button/Button";
import Input from "@/components/ui/forms/Input";
import Select from "@/components/ui/forms/Select";
import TextArea from "@/components/ui/forms/TextArea";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import { status_options } from "@/lib/definitions";
import { useRouter } from "next/navigation";
import { useActionState } from "react";

interface CreateDivisionProps {
  season_id: number;
}

export default function CreateDivision({ season_id }: CreateDivisionProps) {
  const [state, action, pending] = useActionState(createDivision, undefined);
  const router = useRouter();

  const genders = [
    { label: "All", value: "all" },
    { label: "Men", value: "men" },
    { label: "Women", value: "women" },
  ];

  return (
    <form action={action}>
      <Grid cols={{ xs: 1, m: 2 }} gap="base">
        <Col fullSpan>
          <Input
            name="name"
            label="Name"
            errors={{ errs: state?.errors?.name, type: "danger" }}
            defaultValue="Div 1"
            required
          />
        </Col>
        <Col fullSpan>
          <TextArea
            name="description"
            label="Description"
            errors={{ errs: state?.errors?.description, type: "danger" }}
            defaultValue="For those elites!"
            optional
          />
        </Col>
        <Input
          type="number"
          name="tier"
          label="Tier"
          min="1"
          defaultValue="1"
          required
        />
        <Select name="gender" label="Gender" choices={genders} required />
        <Input type="text" name="join_code" label="Join Code" optional />
        <Select name="status" label="Status" choices={status_options} />
        <input type="hidden" name="league_id" value={season_id} />
        <Col>
          <Button type="submit" fullWidth disabled={pending}>
            Create Division
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
