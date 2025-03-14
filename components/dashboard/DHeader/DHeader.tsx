import Container from "@/components/ui/Container/Container";
import { applyColor } from "@/utils/helpers/formatting";
import { applyClasses } from "@/utils/helpers/html-attributes";
import { CSSProperties, PropsWithChildren } from "react";
import css from "./dHeader.module.css";

type DHeaderProps = {
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
  color,
}: PropsWithChildren<DHeaderProps>) {
  const styles: DBHeaderStyles = {};

  styles["--dbh-bg-color"] = applyColor(color || "primary");

  return (
    <header
      style={styles}
      className={applyClasses(css.dashboard_header, className)}
    >
      <Container className={containerClassName}>{children}</Container>
    </header>
  );
}
