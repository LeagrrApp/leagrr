"use client";

import { signUp } from "@/actions/auth";
import { useActionState } from "react";
import Link from "next/link";
import Container from "@/components/ui/Container/Container";
import Grid from "@/components/ui/layout/Grid";
import Col from "@/components/ui/layout/Col";
import Input from "@/components/ui/forms/Input";
import Flex from "@/components/ui/layout/Flex";
import Button from "@/components/ui/Button/Button";

export default function Page() {
  const [state, action, pending] = useActionState(signUp, undefined);

  return (
    <Container maxWidth="35rem">
      <form action={action}>
        <Grid gap="base" cols={2}>
          <Col fullSpan>
            <h1>Sign Up</h1>
            <p>
              Sign up to join <strong>Leagrr</strong> and get your season
              started!
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
            <Flex alignItems="center" gap="base">
              <Button type="submit">Sign Up</Button>
              <p>
                Already have an account? <Link href="/sign-in">Sign In</Link>
              </p>
            </Flex>
          </Col>
        </Grid>
      </form>
    </Container>
  );
}
