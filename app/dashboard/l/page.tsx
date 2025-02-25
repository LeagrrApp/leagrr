import CreateLeague from "@/components/dashboard/leagues/CreateLeague/CreateLeague";
import Badge from "@/components/ui/Badge/Badge";
import Button from "@/components/ui/Button/Button";
import Container from "@/components/ui/Container/Container";
import { verifySession } from "@/lib/session";
import { createMetaTitle } from "@/utils/helpers/formatting";

export async function generateMetadata() {
  return {
    title: createMetaTitle(["Create League"]),
    description: "Create a new league.",
  };
}

export default async function Page() {
  const { user_id, user_role } = await verifySession();

  if (user_role > 2)
    return (
      <Container maxWidth="45rem">
        <h1 className="push-ml">
          Sorry, you do not have permission to create a league.
        </h1>
        <p className="push">
          Only users with the role of <Badge text="Commissioner" type="grey" />{" "}
          and <Badge text="Site Admin" type="primary" /> are able to create new
          leagues. If you would like to create your own league, upgrade your
          account.
        </p>
        <Button href="#">Learn More</Button>
      </Container>
    );

  return <CreateLeague user_id={user_id} />;
}
