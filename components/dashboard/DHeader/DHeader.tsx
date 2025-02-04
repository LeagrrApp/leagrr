import { CSSProperties, PropsWithChildren } from "react";
import css from "./dHeader.module.css";
import Line from "@/components/ui/decorations/Line";
import Container from "@/components/ui/Container/Container";
import { apply_classes } from "@/utils/helpers/html-attributes";

type DHeaderProps = {
  hideLine?: boolean;
  className?: string[] | string;
  containerClassName?: string[] | string;
  color?: string;
};

interface DBHeaderStyles extends CSSProperties {
  "--dbh-bg-color"?: string;
}

export default function DHeader({
  children,
  className,
  containerClassName,
  hideLine,
  color,
}: PropsWithChildren<DHeaderProps>) {
  const styles: DBHeaderStyles = {};

  if (color) styles["--dbh-bg-color"] = color;

  return (
    <header
      style={styles}
      className={apply_classes(css.dashboard_header, className)}
    >
      <Container className={containerClassName}>
        {children}
        {!hideLine && <Line marginStart="m" marginEnd="l" height="xs" />}
      </Container>
    </header>
  );
}
