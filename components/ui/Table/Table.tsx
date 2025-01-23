import { CSSProperties, PropsWithChildren } from "react";
import css from "./table.module.css";
import { apply_classes } from "@/utils/helpers/html-attributes";

interface TableProps {
  hColWidth?: string;
  colWidth?: string;
  className?: string;
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
}: PropsWithChildren<TableProps>) {
  const styles: TableStyles = {};

  if (hColWidth) styles["--h-col-width"] = hColWidth;
  if (colWidth) styles["--col-width"] = colWidth;

  return (
    <table style={styles} className={apply_classes(css.table, className)}>
      {children}
    </table>
  );
}
