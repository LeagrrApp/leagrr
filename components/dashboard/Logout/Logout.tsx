"use client";

import Icon from "@/components/ui/Icon/Icon";
import css from "./logout.module.css";
import { useActionState, useRef } from "react";
import { redirect } from "next/navigation";
import { logOut } from "@/actions/auth";
import Button from "@/components/ui/Button/Button";
import Grid from "@/components/ui/layout/Grid";

export default function Logout() {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const [state, action] = useActionState(logOut, undefined);

  return (
    <>
      <button
        className={css.logout_toggle}
        onClick={() => dialogRef?.current?.showModal()}
      >
        <Icon
          className={css.logout_toggle_icon}
          icon="logout"
          label="Log Out"
        />
      </button>

      <dialog className={css.logout_dialog} ref={dialogRef}>
        <form action={action}>
          <h2 className={css.logout_heading}>
            Are you sure you want to log out?
          </h2>
          <Grid cols={2} gap="base">
            <Button type="submit" variant="danger">
              Log Out
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
        </form>
      </dialog>
    </>
  );
}
