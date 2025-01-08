import SignUp from "@/components/ui/SignUp/SignUp";
import page from "./page.module.css";
import Container from "@/components/ui/Container/Container";

export default function Home() {
  return (
    <Container maxWidth="35rem">
      <h1>Leagrr</h1>
      <SignUp />
    </Container>
  );
}
