/* eslint-disable @typescript-eslint/no-explicit-any */
"use client";

import Alert from "@/components/ui/Alert/Alert";
import Button, { ButtonProps } from "@/components/ui/Button/Button";
import Dialog from "@/components/ui/Dialog/Dialog";
import Input from "@/components/ui/forms/Input";
import Icon from "@/components/ui/Icon/Icon";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import { applyClasses } from "@/utils/helpers/html-attributes";
import { useActionState, useEffect, useRef, useState } from "react";
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
  typeToConfirm?: {
    confirmString: string;
    type: string;
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
  typeToConfirm,
}: ModalConfirmActionProps) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const [state, action, pending] = useActionState(actionFunction, defaultState);
  const [typedConfirmedText, setTypedConfirmedText] = useState<string>("");
  const [buttonDisabled, setButtonDisabled] = useState<boolean>(false);

  useEffect(() => {
    if (typeToConfirm) {
      setButtonDisabled(
        typedConfirmedText !== typeToConfirm.confirmString || pending,
      );
    } else {
      setButtonDisabled(pending);
    }
  }, [typeToConfirm, typedConfirmedText, pending]);

  return (
    <>
      <Button
        className={trigger?.classes ? applyClasses(trigger?.classes) : ""}
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
          <Grid cols={2} gap="base">
            <Col fullSpan>
              <h2 className={css.dialog_heading}>{confirmationHeading}</h2>
              {confirmationByline && (
                <p className={css.dialog_byline}>{confirmationByline}</p>
              )}
            </Col>
            {typeToConfirm && (
              <Col fullSpan>
                <small className={css.confirmation_label}>
                  In order to delete this {typeToConfirm.type}, please type out
                  the {typeToConfirm.type} information:{" "}
                  <strong className={css.confirmation_string}>
                    {typeToConfirm.confirmString}
                  </strong>
                </small>
                <Input
                  id="confirmation-string"
                  name="confirmation-string"
                  label="Type confirmation"
                  type="text"
                  value={typedConfirmedText}
                  onChange={(e) => setTypedConfirmedText(e.target.value)}
                  hideLabel
                  noPlaceholder
                  required
                />
              </Col>
            )}
            <Button
              type="submit"
              variant={confirmationButtonVariant || "danger"}
              disabled={buttonDisabled}
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
          {state?.message && state?.status !== 200 && (
            <Alert alert={state.message} type="danger" marginStart="base" />
          )}
        </form>
      </Dialog>
    </>
  );
}
