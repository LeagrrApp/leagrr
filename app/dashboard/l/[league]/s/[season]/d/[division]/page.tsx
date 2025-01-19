export default async function Page({
  params,
}: {
  params: Promise<{ season: string; league: string; division: string }>;
}) {
  const { season, league, division } = await params;

  return (
    <div>
      <h2>{division}</h2>
    </div>
  );
}
