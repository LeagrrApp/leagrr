"use client";

import { editLeague } from "@/actions/leagues";
import Alert from "@/components/ui/Alert/Alert";
import Button from "@/components/ui/Button/Button";
import Input from "@/components/ui/forms/Input";
import Select from "@/components/ui/forms/Select";
import TextArea from "@/components/ui/forms/TextArea";
import Icon from "@/components/ui/Icon/Icon";
import IconSport from "@/components/ui/Icon/IconSport";
import { sports_options, status_options } from "@/lib/definitions";
import { capitalize } from "@/utils/helpers/formatting";
import { Url } from "next/dist/shared/lib/router/router";
import { useActionState, useState } from "react";
import css from "./editLeague.module.css";

interface EditLeagueProps {
  league: LeagueData;
  backLink: Url;
}

export default function EditLeague({ league, backLink }: EditLeagueProps) {
  const [state, action, pending] = useActionState(editLeague, undefined);
  const [sport, setSport] = useState<string>(league.sport);

  return (
    <form action={action} className={css.form}>
      <div className={css.layout}>
        <div className={css.unit_name}>
          <Input
            label="Name"
            name="name"
            value={league.name}
            errors={{ errs: state?.errors?.name, type: "danger" }}
            required
          />
        </div>
        <div className={css.unit_description}>
          <TextArea
            label="Description"
            name="description"
            value={league.description}
            errors={{ errs: state?.errors?.description, type: "danger" }}
            optional
          />
        </div>
        <div className={css.unit_sport}>
          <fieldset>
            <legend className="label">Sport</legend>
            <div className={css.sport_wrap}>
              {sports_options.map((s) => {
                return (
                  <label
                    className={css.sport_option}
                    key={s}
                    htmlFor={`sport-${s}`}
                    title={
                      s !== "hockey"
                        ? "Sport currently unavailable, coming soon!"
                        : undefined
                    }
                  >
                    <IconSport
                      className={css.sport_icon}
                      sport={s}
                      label={capitalize(s)}
                      size="h2"
                    />
                    <input
                      type="radio"
                      name="sport"
                      id={`sport-${s}`}
                      value={s}
                      onChange={(e) => setSport(e.target.value)}
                      checked={s === sport}
                      disabled={s !== "hockey"}
                    />
                  </label>
                );
              })}
            </div>
          </fieldset>
        </div>
        <div className={css.unit_status}>
          <Select
            label="status"
            name="status"
            choices={status_options}
            selected={league.status}
            errors={{ errs: state?.errors?.status, type: "danger" }}
          />
        </div>
        <input type="hidden" name="league_id" value={league.league_id} />
        <div className={css.unit_submit}>
          <Button type="submit" fullWidth disabled={pending}>
            <Icon icon="save" label="Save League" />
          </Button>
        </div>
        <div className={css.unit_cancel}>
          <Button href={backLink} fullWidth variant="grey">
            <Icon icon="cancel" label="Cancel" />
          </Button>
        </div>
        {state?.message && state.status !== 200 && (
          <div className={css.unit_message}>
            <Alert alert={state.message} type="danger" />
          </div>
        )}
      </div>
    </form>
  );
}
