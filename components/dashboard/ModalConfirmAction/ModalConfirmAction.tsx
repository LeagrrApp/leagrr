"use client";

import { useActionState, useRef } from "react";
import css from "./modalConfirmAction.module.css";
import Icon from "@/components/ui/Icon/Icon";
import Grid from "@/components/ui/layout/Grid";
import Button from "@/components/ui/Button/Button";
import { apply_classes } from "@/utils/helpers/html-attributes";
import Alert from "@/components/ui/Alert/Alert";

interface ModalConfirmActionProps {
  defaultState?: any;
  actionFunction(): any;
  confirmationHeading: string;
  confirmationButton?: string;
  triggerClasses?: string | string[];
  triggerLabel: string;
  triggerIcon: string;
  triggerIconPadding?: SizeOptions[];
}

export default function ModalConfirmAction({
  defaultState,
  actionFunction,
  confirmationHeading,
  confirmationButton,
  triggerClasses,
  triggerLabel,
  triggerIcon,
  triggerIconPadding,
}: ModalConfirmActionProps) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const [state, action] = useActionState(actionFunction, defaultState);

  return (
    <>
      <button
        className={css.trigger}
        onClick={() => dialogRef?.current?.showModal()}
      >
        <Icon
          className={apply_classes(css.trigger_icon, triggerClasses)}
          icon={triggerIcon}
          label={triggerLabel}
          padding={triggerIconPadding}
        />
      </button>

      <dialog className={css.dialog} ref={dialogRef}>
        <form action={action}>
          <h2 className={css.dialog_heading}>{confirmationHeading}</h2>
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
      </dialog>
    </>
  );
}
