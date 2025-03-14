import TeamList from "@/components/dashboard/admin/TeamList/TeamList";
import { createMetaTitle } from "@/utils/helpers/formatting";

export async function generateMetadata() {
  return {
    title: createMetaTitle(["Teams", "Admin Portal"]),
  };
}

export default async function Page() {
  return (
    <>
      <h2>Teams</h2>
      <TeamList />
    </>
  );
}
