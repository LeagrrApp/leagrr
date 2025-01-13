import { PropsWithChildren } from "react";
import Container from "@/components/ui/Container/Container";
import css from "./dBHeader.module.css";

export default function DBHeader({ children }: PropsWithChildren) {
  return (
    <header className={css.dashboard_header}>
      <Container className={css.dashboard_container}>{children}</Container>
    </header>
  );
}
