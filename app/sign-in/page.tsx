"use client";

import { useActionState } from "react";
import { signIn } from "@/actions/auth";
import page from "./page.module.css";
import Alert from "@/components/ui/Alert/Alert";
import Button from "@/components/ui/Button/Button";
import Container from "@/components/ui/Container/Container";
import Input from "@/components/ui/forms/Input";
import Col from "@/components/ui/layout/Col";
import Flex from "@/components/ui/layout/Flex";
import Grid from "@/components/ui/layout/Grid";
import Link from "next/link";

export default function Page() {
  const [state, action, pending] = useActionState(signIn, undefined);

  return (
    <main className={page.sign_in}>
      <Container maxWidth="30rem">
        <form action={action}>
          <Grid gap="base">
            <Grid gap="m">
              <h1 className="type-scale-xxl">Welcome to Leagrr!</h1>
              <p>Please sign in to continue.</p>
            </Grid>
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
            {state?.message && <Alert alert={state.message} type="danger" />}
          </Grid>
        </form>
      </Container>
    </main>
  );
}
