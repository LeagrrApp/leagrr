import { PropsWithChildren } from "react";
import css from "./truncate.module.css";

export function Truncate({ children }: PropsWithChildren) {
  return <div className={css.truncate}>{children}</div>;
}
