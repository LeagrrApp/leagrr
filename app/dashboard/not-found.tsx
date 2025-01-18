import Button from "@/components/ui/Button/Button";
import Container from "@/components/ui/Container/Container";

export default function NotFound() {
  return (
    <Container>
      <h1 className="push">Yikes, couldn't find what you were looking for!</h1>
      <Button href="/">Go to Dashboard</Button>
    </Container>
  );
}
