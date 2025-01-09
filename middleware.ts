import { updateSession } from "./lib/session";

export async function middleware() {
  // console.log("middleware running!");
  return await updateSession();
}
