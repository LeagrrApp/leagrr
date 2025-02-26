import Button from "@/components/ui/Button/Button";
import Container from "@/components/ui/Container/Container";

export default function NotFound() {
  return (
    <Container>
      <h1 className="push">League Not Found</h1>
      <Button href="/">Go to Dashboard</Button>
    </Container>
  );
}
