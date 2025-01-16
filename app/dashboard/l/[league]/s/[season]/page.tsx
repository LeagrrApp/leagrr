export default async function Page({
  params,
}: {
  params: Promise<{ season: string }>;
}) {
  const { season: slug } = await params;

  return (
    <>
      <h2>{slug}</h2>
    </>
  );
}
