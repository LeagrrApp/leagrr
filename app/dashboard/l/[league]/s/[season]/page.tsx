import Container from "@/components/ui/Container/Container";

export default async function Page({
  params,
}: {
  params: Promise<{ season: string }>;
}) {
  const { season: slug } = await params;

  return (
    <Container>
      <h2>{slug}</h2>
    </Container>
  );
}
