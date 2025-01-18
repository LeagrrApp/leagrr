import { PropsWithChildren } from "react";
import css from "./dHeader.module.css";
import Line from "@/components/ui/decorations/Line";
import Container from "@/components/ui/Container/Container";
import { apply_classes } from "@/utils/helpers/html-attributes";

type DHeaderProps = {
  hideLine?: boolean;
  className?: string[] | string;
  containerClassName?: string[] | string;
};

export default function DHeader({
  children,
  className,
  containerClassName,
  hideLine,
}: PropsWithChildren<DHeaderProps>) {
  return (
    <header className={apply_classes(css.dashboard_header, className)}>
      <Container className={containerClassName}>
        {children}
        {!hideLine && <Line marginStart="m" marginEnd="l" height="xs" />}
      </Container>
    </header>
  );
}
