"use client";

import { signUp } from "@/actions/auth";
import Button from "@/components/ui/Button/Button";
import Container from "@/components/ui/Container/Container";
import Input from "@/components/ui/forms/Input";
import Col from "@/components/ui/layout/Col";
import Flex from "@/components/ui/layout/Flex";
import Grid from "@/components/ui/layout/Grid";
import Link from "next/link";
import { useActionState } from "react";
import page from "./page.module.css";

export default function Page() {
  const [state, action, pending] = useActionState(signUp, undefined);

  return (
    <main className={page.sign_up}>
      <Container maxWidth="35rem">
        <form action={action}>
          <Grid gap="base" cols={{ xs: 1, m: 2 }}>
            <Col fullSpan>
              <h1 className="type-scale-xxl push">Sign Up</h1>
              <p>
                Sign up to join <strong>Leagrr</strong> and get your season
                started!
              </p>
            </Col>
            <Input
              name="username"
              label="Username"
              errors={{ errs: state?.errors?.username, type: "danger" }}
              required
            />
            <Input
              name="email"
              label="Email"
              type="email"
              errors={{ errs: state?.errors?.email, type: "danger" }}
              required
            />
            <Input
              name="first_name"
              label="First Name"
              errors={{ errs: state?.errors?.first_name, type: "danger" }}
              required
            />
            <Input
              name="last_name"
              label="Last Name"
              errors={{ errs: state?.errors?.last_name, type: "danger" }}
              required
            />
            <Input
              name="password"
              label="Password"
              type="password"
              errors={{ errs: state?.errors?.password, type: "danger" }}
              required
            />
            <Input
              name="password_confirm"
              label="Confirm Password"
              type="password"
              errors={{ errs: state?.errors?.password_confirm, type: "danger" }}
              required
            />
            <Col fullSpan>
              <Flex alignItems="center" gap="base">
                <Button type="submit" disabled={pending}>
                  Sign Up
                </Button>
                <p>
                  Already have an account? <Link href="/sign-in">Sign In</Link>
                </p>
              </Flex>
            </Col>
          </Grid>
        </form>
      </Container>
    </main>
  );
}
