import { JWTPayload, jwtVerify, SignJWT } from "jose";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import "server-only";

const secretKey = process.env.SESSION_SECRET;
const encodedKey = new TextEncoder().encode(secretKey);

interface SessionPayload extends JWTPayload {
  userData: UserSessionData;
  expiresAt: Date;
}

export async function encrypt(payload: SessionPayload) {
  return new SignJWT(payload)
    .setProtectedHeader({ alg: "HS256" })
    .setIssuedAt()
    .setExpirationTime("7d")
    .sign(encodedKey);
}

export async function decrypt(session: string | undefined = "") {
  try {
    const { payload } = await jwtVerify(session, encodedKey, {
      algorithms: ["HS256"],
    });
    return payload;
  } catch (error) {
    // TODO: set up proper decrypt error validation
    console.log("Failed to verify token. Error: ", error);
  }
}

export async function createSession(userData: UserSessionData) {
  // const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // One week
  const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // One day
  const session = await encrypt({ userData, expiresAt });
  const cookieStore = await cookies();

  cookieStore.set("session", session, {
    httpOnly: true,
    secure: true,
    expires: expiresAt,
    sameSite: "lax",
    path: "/",
  });
}

interface SessionProps extends JWTPayload {
  userData?: UserSessionData;
}

export async function getSession(): Promise<SessionProps | undefined> {
  const session = (await cookies()).get("session")?.value;
  if (!session) return undefined;
  return (await decrypt(session)) as SessionProps;
}

export async function verifySession(): Promise<UserSessionData> {
  const cookie = (await cookies()).get("session")?.value;
  const session: SessionProps | undefined = await decrypt(cookie);

  if (!session?.userData) redirect("/sign-in");

  return session.userData;
}

// TODO: this doesn't seem to be working...?
// export async function updateSession() {
//   "use server";
//   // console.log("starting to update session!");
//   const session = (await cookies()).get("session")?.value;
//   if (!session) return null;

//   const payload = await decrypt(session);
//   if (!payload) return null;

//   // const expires = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // One week
//   // const expires = new Date(Date.now() + 60 * 60 * 1000); // One hour
//   const expires = new Date(Date.now() + 60 * 1000); // One minute
//   // console.log(expires);

//   const newSession = await encrypt({
//     userData: payload.userData as UserData,
//     expiresAt: expires,
//   });

//   const cookieStore = await cookies();
//   cookieStore.set("session", newSession, {
//     httpOnly: true,
//     secure: true,
//     expires: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
//     sameSite: "lax",
//     path: "/",
//   });
//   // console.log("finished updating session!");
// }
