import "server-only";
import { SessionPayload } from "./definitions";
import { jwtVerify, SignJWT } from "jose";
import { cookies } from "next/headers";
import { NextRequest, NextResponse } from "next/server";

const secretKey = process.env.SESSION_SECRET;
const encodedKey = new TextEncoder().encode(secretKey);

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
    console.log("Failed to verify token");
  }
}

export async function createSession(user_id: number, user_role: number) {
  const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
  const session = await encrypt({ user_id, user_role, expiresAt });
  const cookieStore = await cookies();

  cookieStore.set("session", session, {
    httpOnly: true,
    secure: true,
    expires: expiresAt,
    sameSite: "lax",
    path: "/",
  });
}

export async function getSession() {
  const session = (await cookies()).get("session")?.value;
  if (!session) return null;
  return await decrypt(session);
}

// TODO: this doesn't seem to be working...?
export async function updateSession() {
  "use server";
  // console.log("starting to update session!");
  const session = (await cookies()).get("session")?.value;
  if (!session) return null;

  const payload = await decrypt(session);
  if (!payload) return null;

  const expires = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
  // console.log(expires);

  const newSession = await encrypt({
    user_id: payload.user_id as number,
    user_role: payload.user_role,
    expiresAt: expires,
  });

  const cookieStore = await cookies();
  cookieStore.set("session", newSession, {
    httpOnly: true,
    secure: true,
    expires: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    sameSite: "lax",
    path: "/",
  });
  // console.log("finished updating session!");
}
