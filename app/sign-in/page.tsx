"use client";

import { signIn } from "@/actions/auth";
import Button from "@/components/ui/Button/Button";
import Container from "@/components/ui/Container/Container";
import Input from "@/components/ui/forms/Input";
import Col from "@/components/ui/layout/Col";
import Flex from "@/components/ui/layout/Flex";
import Grid from "@/components/ui/layout/Grid";
import Link from "next/link";
import { useActionState, useEffect } from "react";

export default function Page() {
  const [state, action, pending] = useActionState(signIn, undefined);

  useEffect(() => {
    console.log(state);
  }, [state]);

  return (
    <Container maxWidth="30rem">
      <form action={action}>
        <Grid gap="base">
          <Col fullSpan>
            <h1>Sign In</h1>
          </Col>
          <Input name="identifier" label="Username or Email" required />
          <Input name="password" label="Password" type="password" required />
          <Col fullSpan>
            <Flex alignItems="center" gap="base">
              <Button type="submit">Sign In</Button>
              <p>
                Don't have an account? <Link href="/sign-up">Sign Up</Link>
              </p>
            </Flex>
          </Col>
        </Grid>
      </form>
    </Container>
  );
}
