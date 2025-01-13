import { isLoggedIn } from "@/actions/auth";

export default async function Page() {
  await isLoggedIn();

  return <h1>League Page</h1>;
}
