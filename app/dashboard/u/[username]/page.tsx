import { getUserData } from "@/actions/users";
import Container from "@/components/ui/Container/Container";
import Icon from "@/components/ui/Icon/Icon";
import { verifySession } from "@/lib/session";
import { notFound } from "next/navigation";

export default async function Page({
  params,
}: {
  params: Promise<{ username: string }>;
}) {
  const userSession = await verifySession();

  const { username } = await params;
  const currentUser = username === userSession.username;

  const { data } = await getUserData(username);

  if (!data) {
    notFound();
  }

  const { first_name, last_name, email, role } = data;

  return (
    <Container>
      <h1>Welcome to {currentUser ? "your" : `${first_name}'s`} page!</h1>
    </Container>
  );
}
