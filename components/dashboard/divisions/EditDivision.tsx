"use client";
import { editDivision } from "@/actions/divisions";
import Alert from "@/components/ui/Alert/Alert";
import Button from "@/components/ui/Button/Button";
import Input from "@/components/ui/forms/Input";
import Select from "@/components/ui/forms/Select";
import TextArea from "@/components/ui/forms/TextArea";
import Icon from "@/components/ui/Icon/Icon";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import { gender_options, status_options } from "@/lib/definitions";
import { useActionState } from "react";

interface EditDivisionProps {
  division: DivisionData;
  divisionLink: string;
}

export default function EditDivision({
  division,
  divisionLink,
}: EditDivisionProps) {
  const [state, action, pending] = useActionState(editDivision, {
    data: {},
  });

  return (
    <form action={action} className="push">
      <Grid cols={{ xs: 1, m: 2 }} gap="base">
        <Col fullSpan>
          <Input
            name="name"
            label="Name"
            errors={{ errs: state?.errors?.name, type: "danger" }}
            value={state?.data?.name || division.name}
            required
          />
        </Col>
        <Col fullSpan>
          <TextArea
            name="description"
            label="Description"
            errors={{ errs: state?.errors?.description, type: "danger" }}
            value={state?.data?.description || division.description}
            optional
          />
        </Col>
        <Input
          type="number"
          name="tier"
          label="Tier"
          min="1"
          value={state?.data?.tier?.toString() || division.tier?.toString()}
          errors={{ errs: state?.errors?.tier, type: "danger" }}
          required
        />
        <Select
          name="gender"
          label="Gender"
          choices={gender_options}
          selected={state?.data?.gender || division.gender}
          errors={{ errs: state?.errors?.gender, type: "danger" }}
          required
        />
        <Input
          type="text"
          name="join_code"
          label="Join Code"
          errors={{ errs: state?.errors?.join_code, type: "danger" }}
          value={state?.data?.join_code || division.join_code}
          required
        />
        <Select
          name="status"
          label="Status"
          choices={status_options}
          errors={{ errs: state?.errors?.status, type: "danger" }}
          selected={state?.data?.status || division.status}
          required
        />
        <input type="hidden" value={division.division_id} name="division_id" />
        <input type="hidden" value={division.league_id} name="league_id" />
        {state?.message && state?.status !== 200 && (
          <Col fullSpan>
            <Alert alert={state.message} type="danger" />
          </Col>
        )}
        <Col>
          <Button type="submit" fullWidth disabled={pending}>
            <Icon icon="save" label="Save Division" />
          </Button>
        </Col>
        <Col>
          <Button href={divisionLink} type="button" variant="grey" fullWidth>
            <Icon icon="cancel" label="Cancel" />
          </Button>
        </Col>
      </Grid>
    </form>
  );
}
