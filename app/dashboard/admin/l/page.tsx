import LeagueList from "@/components/dashboard/admin/LeagueList/LeagueList";
import { createMetaTitle } from "@/utils/helpers/formatting";

export async function generateMetadata() {
  return {
    title: createMetaTitle(["Leagues", "Admin Portal"]),
  };
}

export default async function Page() {
  return (
    <>
      <h2>Leagues</h2>
      <LeagueList />
    </>
  );
}
