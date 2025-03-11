import {
  createDashboardUrl,
  createMetaTitle,
} from "@/utils/helpers/formatting";
import { redirect } from "next/navigation";

export async function generateMetadata() {
  return {
    title: createMetaTitle(["Admin Portal"]),
  };
}

export default async function Page() {
  redirect(createDashboardUrl({ admin: "u" }));
}
