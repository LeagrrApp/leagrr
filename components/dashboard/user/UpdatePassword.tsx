"use client";

import { updatePassword } from "@/actions/users";
import Alert from "@/components/ui/Alert/Alert";
import Button from "@/components/ui/Button/Button";
import Card from "@/components/ui/Card/Card";
import Input from "@/components/ui/forms/Input";
import Icon from "@/components/ui/Icon/Icon";
import Grid from "@/components/ui/layout/Grid";
import { useActionState, useEffect, useState } from "react";

interface UpdatePasswordProps {
  user: UserData;
  isCurrentUser: boolean;
}

export default function UpdatePassword({
  user,
  isCurrentUser,
}: UpdatePasswordProps) {
  const [state, action, pending] = useActionState(updatePassword, undefined);

  const [currentPasswordValue, setCurrentPasswordValue] = useState<string>("");
  const [newPasswordValue, setNewPasswordValue] = useState<string>("");
  const [confirmPasswordValue, setConfirmPasswordValue] = useState<string>("");
  const [hasFormErrors, setHasFormErrors] = useState<boolean>(false);

  useEffect(() => {
    if (
      state?.errors?.confirm_password ||
      state?.errors?.current_password ||
      state?.errors?.new_password ||
      state?.errors?.user_id
    ) {
      setHasFormErrors(true);
    }
    if (state?.status === 200) {
      setHasFormErrors(false);
      setCurrentPasswordValue("");
      setNewPasswordValue("");
      setConfirmPasswordValue("");
    }
  }, [state]);

  if (isCurrentUser)
    return (
      <Card padding="l">
        <h3 className="push">Update Password</h3>
        <form action={action}>
          <Grid gap="base">
            <Input
              name="current_password"
              label="Current Password"
              type="password"
              value={currentPasswordValue}
              onChange={(e) => setCurrentPasswordValue(e.target.value)}
              errors={{ errs: state?.errors?.current_password, type: "danger" }}
              required
            />
            <Input
              name="new_password"
              label="New Password"
              type="password"
              value={newPasswordValue}
              onChange={(e) => setNewPasswordValue(e.target.value)}
              errors={{ errs: state?.errors?.new_password, type: "danger" }}
              required
            />
            <Input
              name="confirm_password"
              label="Confirm New Password"
              type="password"
              value={confirmPasswordValue}
              onChange={(e) => setConfirmPasswordValue(e.target.value)}
              errors={{ errs: state?.errors?.confirm_password, type: "danger" }}
              required
            />
            <input type="hidden" name="user_id" value={user.user_id} />
            {state?.message && state?.status && !hasFormErrors && (
              <Alert
                type={state.status === 200 ? "success" : "danger"}
                alert={state.message}
              />
            )}
            <Button type="submit" disabled={pending}>
              <Icon icon="save" label="Save Password" />
            </Button>
          </Grid>
        </form>
      </Card>
    );

  return (
    <Card padding="l">
      <h3>Reset Password</h3>
      <p className="push-ml">
        Click to reset user&apos;s password. They will receive an email to reset
        their password.
      </p>
      <Button href="#" fullWidth>
        <Icon icon="lock_reset" label="Reset Password" />
      </Button>
    </Card>
  );
}
