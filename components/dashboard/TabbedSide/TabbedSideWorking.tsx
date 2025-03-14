import { PropsWithChildren } from "react";
import css from "./tabbedSide.module.css";

export default async function TabbedSideWorking({
  children,
}: PropsWithChildren) {
  return <div className={css.work_area}>{children}</div>;
}
