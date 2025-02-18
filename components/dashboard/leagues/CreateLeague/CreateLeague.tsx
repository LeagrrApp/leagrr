"use client";

import { createLeague } from "@/actions/leagues";
import Alert from "@/components/ui/Alert/Alert";
import Button from "@/components/ui/Button/Button";
import Card from "@/components/ui/Card/Card";
import Container from "@/components/ui/Container/Container";
import Input from "@/components/ui/forms/Input";
import TextArea from "@/components/ui/forms/TextArea";
import IconSport from "@/components/ui/Icon/IconSport";
import Grid from "@/components/ui/layout/Grid";
import { sports_options } from "@/lib/definitions";
import { capitalize } from "@/utils/helpers/formatting";
import { CSSProperties, useActionState, useEffect, useState } from "react";
import css from "./createLeague.module.css";

interface CreateLeagueProps {
  user_id: number;
}

interface BackgroundStyles extends CSSProperties {
  "--bg-image": string;
}

export default function CreateLeague({ user_id }: CreateLeagueProps) {
  const [state, action, pending] = useActionState(createLeague, undefined);
  const [sport, setSport] = useState<string>("hockey");
  const [leagueName, setLeagueName] = useState<string>("");

  useEffect(() => {
    console.log(state);
  }, [state]);

  const styles: BackgroundStyles = {
    "--bg-image": `url('/bg-${sport}.jpg')`,
  };

  return (
    <div style={styles} className={css.form_background}>
      <Container maxWidth="45rem" className={css.form_wrap}>
        <Card padding="l">
          <form action={action}>
            <Grid gap="base">
              <h1>Create a league</h1>
              <Input
                label="Name"
                name="name"
                errors={{ errs: state?.errors?.name, type: "danger" }}
                onChange={(e) => setLeagueName(e.target.value)}
                required
              />
              <TextArea
                label="Description"
                name="description"
                errors={{ errs: state?.errors?.description, type: "danger" }}
                optional
              />
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
              <input type="hidden" name="user_id" value={user_id} />
              <Button type="submit" disabled={pending}>
                <IconSport
                  sport={sport}
                  label={`Create ${leagueName || "League"}`}
                />
              </Button>
              {state?.message && state.status !== 200 && (
                <Alert alert={state.message} type="danger" />
              )}
            </Grid>
          </form>
        </Card>
      </Container>
    </div>
  );
}
