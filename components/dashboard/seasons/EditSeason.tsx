"use client";

import { editSeason } from "@/actions/seasons";
import Button from "@/components/ui/Button/Button";
import Input from "@/components/ui/forms/Input";
import Select from "@/components/ui/forms/Select";
import TextArea from "@/components/ui/forms/TextArea";
import Icon from "@/components/ui/Icon/Icon";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import { status_options } from "@/lib/definitions";
import { Url } from "next/dist/shared/lib/router/router";
import { useActionState } from "react";

interface EditSeasonProps {
  backLink: Url;
  season: SeasonData;
}

export default function EditSeason({ backLink, season }: EditSeasonProps) {
  const [state, action, pending] = useActionState(editSeason, undefined);

  const start_date = season.start_date
    ? new Date(season.start_date).toLocaleDateString("en-CA")
    : "";
  const end_date = season.end_date
    ? new Date(season.end_date).toLocaleDateString("en-CA")
    : "";

  return (
    <form className="push" action={action}>
      <Grid cols={{ xs: 1, m: 2 }} gap="base">
        <Col>
          <Input
            name="name"
            label="Name"
            errors={{ errs: state?.errors?.name, type: "danger" }}
            value={season.name}
            required
          />
        </Col>
        <Col>
          <Select
            name="status"
            label="Status"
            errors={{ errs: state?.errors?.name, type: "danger" }}
            choices={status_options}
            selected={season.status}
            required
          />
        </Col>
        <Col fullSpan>
          <TextArea
            name="description"
            label="Description"
            errors={{ errs: state?.errors?.description, type: "danger" }}
            value={season.description}
            optional
          />
        </Col>
        <Input
          type="date"
          name="start_date"
          label="Start Date"
          value={start_date}
          errors={{ errs: state?.errors?.start_date, type: "danger" }}
          required
        />
        <Input
          type="date"
          name="end_date"
          label="End Date"
          value={end_date}
          errors={{ errs: state?.errors?.end_date, type: "danger" }}
          required
        />
        <input type="hidden" name="league_id" value={season.league_id} />
        <input type="hidden" name="season_id" value={season.season_id} />
        <Col>
          <Button type="submit" fullWidth disabled={pending}>
            <Icon icon="save" label="Save Season" />
          </Button>
        </Col>
        <Col>
          <Button href={backLink} type="button" variant="grey" fullWidth>
            <Icon icon="cancel" label="Cancel" />
          </Button>
        </Col>
      </Grid>
    </form>
  );
}
