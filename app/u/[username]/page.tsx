import { isLoggedIn } from "@/actions/auth";
import Container from "@/components/ui/Container/Container";

export default async function Page() {
  await isLoggedIn();

  return (
    <Container>
      <h1>Welcome to the user page!</h1>
    </Container>
  );
}
