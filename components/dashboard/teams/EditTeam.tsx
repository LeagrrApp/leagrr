"use client";

import { editTeam } from "@/actions/teams";
import Button from "@/components/ui/Button/Button";
import Input from "@/components/ui/forms/Input";
import Select from "@/components/ui/forms/Select";
import TextArea from "@/components/ui/forms/TextArea";
import Icon from "@/components/ui/Icon/Icon";
import Grid from "@/components/ui/layout/Grid";
import { color_options } from "@/lib/definitions";
import { useActionState, useState } from "react";
import css from "./teamForm.module.css";
import Col from "@/components/ui/layout/Col";

interface EditTeamProps {
  team: TeamData;
  backLink: string;
}

export default function EditTeam({ team, backLink }: EditTeamProps) {
  const [state, action, pending] = useActionState(editTeam, undefined);
  const [teamName, setTeamName] = useState<string>(
    state?.data?.name || team.name,
  );
  const [colorValue, setColorValue] = useState<string>(() => {
    const foundColor = state?.data?.color || team.color || "";

    if (foundColor.includes("#")) {
      return "custom";
    }
    return foundColor;
  });

  return (
    <form action={action} className="push">
      <Grid gap="base" cols={{ xs: 1, m: 2 }}>
        <Col fullSpan>
          <Input
            label="Name"
            name="name"
            value={teamName}
            onChange={(e) => setTeamName(e.target.value)}
            errors={{ errs: state?.errors?.name, type: "danger" }}
            required
          />
        </Col>
        <Col fullSpan>
          <TextArea
            label="Description"
            name="description"
            defaultValue={team.description}
            errors={{ errs: state?.errors?.description, type: "danger" }}
            optional
          />
        </Col>
        <Col fullSpan className={css.color_wrap}>
          <Select
            label="Color"
            name="color"
            choices={[...color_options, "custom"]}
            selected={colorValue}
            onChange={(e) => setColorValue(e.target.value)}
            errors={{ errs: state?.errors?.color, type: "danger" }}
            blankFirst
            optional
          />
          {colorValue === "custom" && (
            <Input
              label="Custom Color"
              name="custom_color"
              defaultValue={team.color}
              type="color"
              errors={{ errs: state?.errors?.custom_color, type: "danger" }}
              required
            />
          )}
        </Col>
        <input type="hidden" name="team_id" value={team.team_id} />
        <Button type="submit" disabled={pending}>
          <Icon icon="save" label={`Save ${teamName}`} />
        </Button>
        <Button href={backLink} variant="grey">
          <Icon icon="cancel" label="Cancel" />
        </Button>
      </Grid>
    </form>
  );
}
