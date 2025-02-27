"use client";

import { createVenue } from "@/actions/venues";
import Button from "@/components/ui/Button/Button";
import Dialog from "@/components/ui/Dialog/Dialog";
import Input from "@/components/ui/forms/Input";
import TextArea from "@/components/ui/forms/TextArea";
import Icon from "@/components/ui/Icon/Icon";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import { usePathname } from "next/navigation";
import { useActionState, useEffect, useRef, useState } from "react";
import css from "./leagueVenueAdd.module.css";

interface LeagueVenueAddProps {
  league_id: number;
}

export default function LeagueVenueAdd({ league_id }: LeagueVenueAddProps) {
  const pathname = usePathname();
  const dialogRef = useRef<HTMLDialogElement>(null);

  const [state, action, pending] = useActionState(createVenue, {
    link: pathname,
    data: {},
  });

  const [arenasToAdd, setArenasToAdd] = useState<string[]>([]);
  const [arenaBeingAdded, setArenaBeingAdded] = useState<string>("");

  useEffect(() => {
    console.log(state);
  }, [state]);

  function addNewArena() {
    if (arenaBeingAdded) {
      setArenasToAdd([...arenasToAdd, arenaBeingAdded]);
      setArenaBeingAdded("");
    }
  }

  function removeArena(a: string) {
    setArenasToAdd(arenasToAdd.filter((arena) => arena !== a));
  }

  function cancel() {
    setArenaBeingAdded("");
    setArenasToAdd([]);
    dialogRef.current?.close();
  }

  return (
    <>
      <Button
        onClick={() => dialogRef.current?.showModal()}
        variant="grey"
        fullWidth
      >
        <Icon icon="add_circle" label="Add venue" />
      </Button>
      <Dialog ref={dialogRef}>
        <form action={action}>
          <Grid gap="base" cols={2}>
            <Col fullSpan>
              <h3>Add Venue</h3>
            </Col>
            <Col fullSpan>
              <Input
                name="venue_name"
                label="Name"
                errors={{ errs: state?.errors?.venue_name, type: "danger" }}
                required
              />
            </Col>
            <Col fullSpan>
              <TextArea
                name="venue_description"
                label="Description"
                errors={{
                  errs: state?.errors?.venue_description,
                  type: "danger",
                }}
              />
            </Col>
            <Col fullSpan>
              <Input
                name="venue_address"
                label="Address"
                errors={{ errs: state?.errors?.venue_address, type: "danger" }}
                required
              />
            </Col>
            {arenasToAdd && arenasToAdd.length > 0 && (
              <Col fullSpan>
                <h4 className="label type-scale-base">Arenas</h4>

                <div className={css.arenas}>
                  {arenasToAdd.map((a) => (
                    <span key={a}>
                      <Button
                        variant="grey"
                        padding={["xs", "m"]}
                        onClick={() => removeArena(a)}
                        aria-label={`Remove ${a} from list of arenas`}
                      >
                        <Icon
                          icon="close"
                          label={a}
                          size="s"
                          gap="s"
                          labelFirst
                        />
                      </Button>
                      <input type="hidden" name="arenas" value={a} />
                    </span>
                  ))}
                </div>
              </Col>
            )}
            <Col fullSpan>
              <div className={css.new_arena}>
                <Input
                  className={css.new_arena_input}
                  name="arenas"
                  label="Add Arena"
                  value={arenaBeingAdded}
                  onChange={(e) => setArenaBeingAdded(e.target.value)}
                />
                <Button
                  className={css.new_arena_button}
                  variant="grey"
                  padding={["m"]}
                  onClick={addNewArena}
                >
                  <Icon icon="add_circle" label="Add arena" hideLabel />
                </Button>
              </div>
            </Col>
            <input type="hidden" name="league_id" value={league_id} />
            <Button type="submit" disabled={pending}>
              <Icon icon="add_circle" label="Add Venue" />
            </Button>
            <Button type="button" variant="grey" onClick={cancel}>
              <Icon icon="cancel" label="Cancel" />
            </Button>
          </Grid>
        </form>
      </Dialog>
    </>
  );
}
