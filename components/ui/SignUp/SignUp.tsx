"use client";

import { signup } from "@/actions/auth";
import Button from "../Button/Button";
import Input from "../forms/Input";
import Col from "../Grid/Col";
import Grid from "../Grid/Grid";
import { useActionState, useEffect } from "react";

export default function SignUp() {
  const [state, action, pending] = useActionState(signup, undefined);

  useEffect(() => {
    console.log(state);
  }, [state]);

  return (
    <form action={action}>
      <Grid gap="base" cols={2}>
        <Col fullSpan>
          <p>
            Sign up to join <strong>Leagrr</strong> and get your season started!
          </p>
        </Col>
        <Input
          name="username"
          label="Username"
          errors={state?.errors?.username}
          required
        />
        <Input
          name="email"
          label="Email"
          type="email"
          errors={state?.errors?.email}
          required
        />
        <Input
          name="first_name"
          label="First Name"
          errors={state?.errors?.first_name}
          required
        />
        <Input
          name="last_name"
          label="Last Name"
          errors={state?.errors?.last_name}
          required
        />
        <Input
          name="password"
          label="Password"
          type="password"
          errors={state?.errors?.password}
          required
        />
        <Input
          name="password_confirm"
          label="Confirm Password"
          type="password"
          errors={state?.errors?.password_confirm}
          required
        />
        <Col fullSpan>
          <Button type="submit" fullWidth>
            Sign Up
          </Button>
        </Col>
      </Grid>
    </form>
  );
}
