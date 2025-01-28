"use client";

import { useActionState, useRef } from "react";
import css from "./modalConfirmAction.module.css";
import Grid from "@/components/ui/layout/Grid";
import Button, { ButtonProps } from "@/components/ui/Button/Button";
import { apply_classes } from "@/utils/helpers/html-attributes";
import Alert from "@/components/ui/Alert/Alert";
import Dialog from "@/components/ui/Dialog/Dialog";

interface ModalConfirmActionProps {
  defaultState?: any;
  actionFunction(): any;
  confirmationHeading: string;
  confirmationByline?: string;
  confirmationButton?: string;
  trigger: {
    classes?: string | string[];
    label: string;
    icon: string;
    buttonStyles?: ButtonProps;
  };
}

export default function ModalConfirmAction({
  defaultState,
  actionFunction,
  confirmationHeading,
  confirmationByline,
  confirmationButton,
  trigger,
}: ModalConfirmActionProps) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const [state, action] = useActionState(actionFunction, defaultState);

  return (
    <>
      <Button
        className={trigger?.classes ? apply_classes(trigger?.classes) : ""}
        onClick={() => dialogRef?.current?.showModal()}
        variant={trigger?.buttonStyles?.variant || "transparent"}
        outline={trigger?.buttonStyles?.outline}
        size={trigger?.buttonStyles?.size}
        fullWidth={trigger?.buttonStyles?.fullWidth}
        asSpan={trigger?.buttonStyles?.asSpan}
      >
        {trigger.icon && (
          <i className="material-symbols-outlined">{trigger.icon}</i>
        )}
        {trigger.label}
      </Button>

      <Dialog className={css.dialog} ref={dialogRef}>
        <form action={action}>
          <h2 className={css.dialog_heading}>{confirmationHeading}</h2>
          {confirmationByline && (
            <p className={css.dialog_byline}>{confirmationByline}</p>
          )}
          <Grid cols={2} gap="base">
            <Button type="submit" variant="danger">
              {confirmationButton || "Confirm"}
            </Button>
            <Button
              type="button"
              variant="grey"
              outline
              onClick={() => dialogRef?.current?.close()}
            >
              Cancel
            </Button>
          </Grid>
          {state?.status === 401 && (
            <Alert alert={state.message} type="danger" marginStart="m" />
          )}
        </form>
      </Dialog>
    </>
  );
}
