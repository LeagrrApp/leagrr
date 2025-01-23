export default async function Page({
  params,
}: {
  params: Promise<{ division: string; season: string; league: string }>;
}) {
  return (
    <>
      <h3>Add game</h3>
    </>
  );
}
