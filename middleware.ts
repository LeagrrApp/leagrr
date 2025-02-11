import { cookies } from "next/headers";
import { type NextRequest, NextResponse } from "next/server";
import { decrypt } from "./lib/session";
import { JWTPayload } from "jose";

interface SessionProps extends JWTPayload {
  userData?: UserSessionData;
}

export default async function middleware(req: NextRequest) {
  // Check if route is protected

  /*
  
    This version assumes multiple routes that are protected.
    Currently there is only one so I simplified it down to
    reduce load on each route change

    const protectedRoutes = ["/dashboard"];
    const currentPath = req.nextUrl.pathname;
    let isProtectedRoute = false;
  
    protectedRoutes.forEach((r) => {
      if (currentPath.includes(r)) {
        isProtectedRoute = true;
      }
    });

  */

  if (req.nextUrl.pathname.includes("/dashboard")) {
    // check for valid session
    const cookie = (await cookies()).get("session")?.value;
    const session: SessionProps | undefined = await decrypt(cookie);

    // redirect unauthed users
    if (!session?.userData) {
      return NextResponse.redirect(new URL("/sign-in", req.nextUrl));
    }
  }

  // render route
  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!api|_next/static|_next/image).*)"],
};
