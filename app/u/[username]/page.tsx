import { isLoggedIn } from "@/actions/auth";
import { getUserData } from "@/actions/users";
import Container from "@/components/ui/Container/Container";
import { getSession } from "@/lib/session";
import { notFound } from "next/navigation";

export default async function Page({
  params,
}: {
  params: Promise<{ username: string }>;
}) {
  const userData = await isLoggedIn();

  console.log(userData);

  const { username } = await params;

  const { data } = await getUserData(username);

  if (!data) {
    notFound();
  }

  const { first_name, last_name, email, role } = data;

  const currentUser = username === userData.username;

  return (
    <Container>
      <h1>Welcome to {currentUser ? "your" : `${first_name}'s`} page!</h1>
    </Container>
  );
}
