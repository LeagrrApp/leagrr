import Button from "@/components/ui/Button/Button";
import Container from "@/components/ui/Container/Container";

export default function NotFound() {
  return (
    <Container>
      <h2 className="push">Yikes, league not found!</h2>
      <Button href="../">Go Back</Button>
    </Container>
  );
}
