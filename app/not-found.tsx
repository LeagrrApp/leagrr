import Button from "@/components/ui/Button/Button";
import Container from "@/components/ui/Container/Container";

export default async function NotFound() {
  return (
    <Container maxWidth="35rem">
      <h1>Sorry, page not found.</h1>
      <p>It looks like this page does not exist.</p>
      <Button href="/">Return</Button>
    </Container>
  );
}
