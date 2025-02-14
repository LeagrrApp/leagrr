"use client";

import { createTeam } from "@/actions/teams";
import Button from "@/components/ui/Button/Button";
import Input from "@/components/ui/forms/Input";
import Select from "@/components/ui/forms/Select";
import TextArea from "@/components/ui/forms/TextArea";
import Icon from "@/components/ui/Icon/Icon";
import Grid from "@/components/ui/layout/Grid";
import { color_options } from "@/lib/definitions";
import { useActionState, useState } from "react";
import css from "./teamForm.module.css";

interface CreateTeamProps {
  user_id: number;
}

export default function CreateTeam({ user_id }: CreateTeamProps) {
  const [state, action, pending] = useActionState(createTeam, undefined);
  const [colorValue, setColorValue] = useState<string>(
    state?.data?.color || "",
  );

  return (
    <form action={action}>
      <Grid gap="base">
        <Input
          label="Name"
          name="name"
          defaultValue="Metcalfe Jets"
          errors={{ errs: state?.errors?.name, type: "danger" }}
          required
        />
        <TextArea
          label="Description"
          name="description"
          value="A small town team."
          errors={{ errs: state?.errors?.description, type: "danger" }}
          optional
        />
        <div className={css.color_wrap}>
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
              type="color"
              errors={{ errs: state?.errors?.custom_color, type: "danger" }}
              required
            />
          )}
        </div>
        <input type="hidden" name="user_id" value={user_id} />
        <Button type="submit" disabled={pending}>
          <Icon icon="add_circle" label="Create Team" />
        </Button>
      </Grid>
    </form>
  );
}
