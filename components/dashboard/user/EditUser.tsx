"use client";

import { editUser } from "@/actions/users";
import Button from "@/components/ui/Button/Button";
import Input from "@/components/ui/forms/Input";
import Icon from "@/components/ui/Icon/Icon";
import Grid from "@/components/ui/layout/Grid";
import { useActionState, useEffect, useState } from "react";

interface EditUserProps {
  user: UserData;
}

export default function EditUser({ user }: EditUserProps) {
  const [state, action, pending] = useActionState(editUser, undefined);

  const [firstNameValue, setFirstNameValue] = useState(user.first_name);
  const [lastNameValue, setLastNameValue] = useState(user.last_name);
  const [usernameValue, setUsernameValue] = useState(user.username);
  const [emailValue, setEmailValue] = useState(user.email);
  const [genderValue, setGenderValue] = useState(user.gender);
  const [pronounsValue, setPronounsValue] = useState(user.pronouns);
  const [changesMade, setChangesMade] = useState<boolean>(false);

  useEffect(() => {
    if (
      firstNameValue !== user.first_name ||
      lastNameValue !== user.last_name ||
      usernameValue !== user.username ||
      emailValue !== user.email ||
      genderValue !== user.gender ||
      pronounsValue !== user.pronouns
    ) {
      setChangesMade(true);
    } else {
      setChangesMade(false);
    }
  }, [
    firstNameValue,
    lastNameValue,
    usernameValue,
    emailValue,
    genderValue,
    pronounsValue,
    user.email,
    user.first_name,
    user.gender,
    user.last_name,
    user.pronouns,
    user.username,
  ]);

  useEffect(() => {
    if (state?.data?.first_name) setFirstNameValue(state?.data?.first_name);
    if (state?.data?.last_name) setLastNameValue(state?.data?.last_name);
    if (state?.data?.username) setUsernameValue(state?.data?.username);
    if (state?.data?.email) setEmailValue(state?.data?.email);
    if (state?.data?.gender) setGenderValue(state?.data?.gender);
    if (state?.data?.pronouns) setPronounsValue(state?.data?.pronouns);
  }, [state]);

  function revertChanges() {
    setFirstNameValue(user.first_name);
    setLastNameValue(user.last_name);
    setUsernameValue(user.username);
    setEmailValue(user.email);
    setGenderValue(user.gender);
    setPronounsValue(user.pronouns);
  }

  return (
    <form action={action}>
      <h3 className="push-ml">Basic Information</h3>
      <Grid gap="base" cols={{ xs: 1, m: 2 }}>
        <Input
          onChange={(e) => setFirstNameValue(e.target.value)}
          value={firstNameValue}
          name="first_name"
          label="First Name"
          required
        />
        <Input
          onChange={(e) => setLastNameValue(e.target.value)}
          value={lastNameValue}
          name="last_name"
          label="Last Name"
          required
        />
        <Input
          onChange={(e) => setUsernameValue(e.target.value)}
          value={usernameValue}
          name="username"
          label="Username"
          required
        />
        <Input
          onChange={(e) => setEmailValue(e.target.value)}
          value={emailValue}
          name="email"
          label="Email"
          type="email"
          required
        />
        <Input
          onChange={(e) => setGenderValue(e.target.value)}
          value={genderValue}
          name="gender"
          label="Gender"
        />
        <Input
          onChange={(e) => setPronounsValue(e.target.value)}
          value={pronounsValue}
          name="pronouns"
          label="Pronouns"
        />
        <input type="hidden" name="user_id" value={user.user_id} />
        <Button type="submit" disabled={pending}>
          <Icon icon="save" label="Save" />
        </Button>
        <Button
          variant="grey"
          onClick={() => revertChanges()}
          disabled={!changesMade || pending}
        >
          <Icon icon="undo" label="Clear Changes" />
        </Button>
      </Grid>
    </form>
  );
}
