"use client";

import { signIn } from "@/actions/auth";
import Alert from "@/components/ui/Alert/Alert";
import Button from "@/components/ui/Button/Button";
import Input from "@/components/ui/forms/Input";
import Col from "@/components/ui/layout/Col";
import Flex from "@/components/ui/layout/Flex";
import Grid from "@/components/ui/layout/Grid";
import Link from "next/link";
import { useActionState } from "react";

export default function SignInForm() {
  const [state, action, pending] = useActionState(signIn, undefined);
  return (
    <form action={action}>
      <Grid gap="base">
        <Grid gap="m">
          <h1 className="type-scale-xxl">Welcome to Leagrr!</h1>
          <p>Please sign in to continue.</p>
        </Grid>
        <Input name="identifier" label="Username or Email" required />
        <Input name="password" label="Password" type="password" required />
        {state?.message && state?.status !== 200 && (
          <Col fullSpan>
            <Alert alert={state.message} type="danger" />
          </Col>
        )}
        <Col fullSpan>
          <Flex alignItems="center" gap="base">
            <Button type="submit" disabled={pending}>
              Sign In
            </Button>
            <p>
              Don&apos;t have an account? <Link href="/sign-up">Sign Up</Link>
            </p>
          </Flex>
        </Col>
      </Grid>
    </form>
  );
}
