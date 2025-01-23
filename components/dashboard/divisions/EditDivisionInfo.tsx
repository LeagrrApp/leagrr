"use client";
import { editDivision } from "@/actions/divisions";
import Button from "@/components/ui/Button/Button";
import Input from "@/components/ui/forms/Input";
import Select from "@/components/ui/forms/Select";
import TextArea from "@/components/ui/forms/TextArea";
import Icon from "@/components/ui/Icon/Icon";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import { gender_options, status_options } from "@/lib/definitions";
import { useActionState, useEffect } from "react";

interface EditDivisionProps {
  division: DivisionData;
  divisionLink: string;
}

export default function EditDivisionInfo({
  division,
  divisionLink,
}: EditDivisionProps) {
  const [state, action, pending] = useActionState(editDivision, {
    link: divisionLink,
  });

  console.log(divisionLink);

  useEffect(() => {
    console.log(state);
  }, [state]);

  return (
    <form action={action} className="push">
      <Grid cols={{ xs: 1, m: 2 }} gap="base">
        <Col fullSpan>
          <Input
            name="name"
            label="Name"
            errors={{ errs: state?.errors?.name, type: "danger" }}
            value={division.name}
            required
          />
        </Col>
        <Col fullSpan>
          <TextArea
            name="description"
            label="Description"
            errors={{ errs: state?.errors?.description, type: "danger" }}
            value={division.description}
            optional
          />
        </Col>
        <Input
          type="number"
          name="tier"
          label="Tier"
          min="1"
          value={division.tier?.toString()}
          errors={{ errs: state?.errors?.tier, type: "danger" }}
          required
        />
        <Select
          name="gender"
          label="Gender"
          choices={gender_options}
          selected={division.gender}
          errors={{ errs: state?.errors?.gender, type: "danger" }}
          required
        />
        <Input
          type="text"
          name="join_code"
          label="Join Code"
          errors={{ errs: state?.errors?.join_code, type: "danger" }}
          value={division.join_code}
          optional
        />
        <Select
          name="status"
          label="Status"
          choices={status_options}
          errors={{ errs: state?.errors?.status, type: "danger" }}
          selected={division.status}
        />
        <input type="hidden" value={division.division_id} name="division_id" />
        <input type="hidden" value={division.league_id} name="league_id" />
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
