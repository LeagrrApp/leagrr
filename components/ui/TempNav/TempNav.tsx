import Link from "next/link";
import Container from "../Container/Container";
import Button from "../Button/Button";
import { logOut } from "@/actions/auth";
import { redirect } from "next/navigation";
import tempNav from "./tempNav.module.css";
import { getSession } from "@/lib/session";
import Flex from "../layout/Flex";

export default async function TempNav() {
  const session = await getSession();

  return (
    <Container className={tempNav.temp_nav}>
      <Flex alignItems="center" justifyContent="space-between" gap="base">
        <Link href="/">Home</Link>
        <Flex alignItems="center" gap="base">
          {session?.userData ? (
            <>
              <Link href={`/u/moose`}>Profile</Link>
              <form
                action={async () => {
                  "use server";
                  await logOut();
                  redirect("/sign-in");
                }}
              >
                <Button type="submit">Log Out</Button>
              </form>
            </>
          ) : (
            <>
              <Button href="/sign-up">Sign Up</Button>
              <Link href="/sign-in">Sign In</Link>
            </>
          )}
        </Flex>
      </Flex>
    </Container>
  );
}
