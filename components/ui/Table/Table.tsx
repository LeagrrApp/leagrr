import { applyClasses } from "@/utils/helpers/html-attributes";
import { CSSProperties, PropsWithChildren } from "react";
import css from "./table.module.css";

interface TableProps {
  hColWidth?: string;
  colWidth?: string;
  className?: string;
  flipped?: boolean;
}
interface TableStyles extends CSSProperties {
  "--h-col-width"?: string;
  "--col-width"?: string;
}

export default function Table({
  children,
  hColWidth,
  colWidth,
  className,
  flipped,
}: PropsWithChildren<TableProps>) {
  const styles: TableStyles = {};

  if (hColWidth) styles["--h-col-width"] = hColWidth;
  if (colWidth) styles["--col-width"] = colWidth;

  const classes = [css.table];
  if (flipped) classes.push(css.table_flipped);

  return (
    <table style={styles} className={applyClasses(classes, className)}>
      {children}
    </table>
  );
}
