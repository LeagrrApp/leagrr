/* eslint-disable @typescript-eslint/no-explicit-any */
"use client";

import Alert from "@/components/ui/Alert/Alert";
import Button, { ButtonProps } from "@/components/ui/Button/Button";
import Dialog from "@/components/ui/Dialog/Dialog";
import Icon from "@/components/ui/Icon/Icon";
import Grid from "@/components/ui/layout/Grid";
import { apply_classes } from "@/utils/helpers/html-attributes";
import { useActionState, useRef } from "react";
import css from "./modalConfirmAction.module.css";

interface ModalConfirmActionProps {
  defaultState?: any;
  actionFunction: (state: any, payload: unknown) => any;
  confirmationHeading: string;
  confirmationByline?: string;
  confirmationButton?: string;
  confirmationButtonVariant?: ColorOptions;
  trigger: {
    classes?: string | string[];
    label: string;
    hideLabel?: boolean;
    icon?: string;
    buttonStyles?: ButtonProps;
  };
}

export default function ModalConfirmAction({
  defaultState,
  actionFunction,
  confirmationHeading,
  confirmationByline,
  confirmationButton,
  confirmationButtonVariant,
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
        padding={trigger?.buttonStyles?.padding}
        asSpan={trigger?.buttonStyles?.asSpan}
      >
        {trigger.icon ? (
          <Icon
            icon={trigger.icon}
            label={trigger.label}
            hideLabel={trigger.hideLabel}
          />
        ) : (
          <>{trigger.label}</>
        )}
      </Button>

      <Dialog className={css.dialog} ref={dialogRef}>
        <form action={action}>
          <h2 className={css.dialog_heading}>{confirmationHeading}</h2>
          {confirmationByline && (
            <p className={css.dialog_byline}>{confirmationByline}</p>
          )}
          <Grid cols={2} gap="base">
            <Button
              type="submit"
              variant={confirmationButtonVariant || "danger"}
            >
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
