import Card from "@/components/ui/Card/Card";
import { PropsWithChildren } from "react";
import css from "./tabbedSide.module.css";

export default async function TabbedSide({ children }: PropsWithChildren) {
  return <Card className={css.grid}>{children}</Card>;
}
