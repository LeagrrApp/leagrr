import { CSSProperties, PropsWithChildren } from "react";
import css from "./table.module.css";

interface TableProps {
  colWidth?: string;
}
interface TableStyles extends CSSProperties {
  "--col-width"?: string;
}

export default function Table({
  children,
  colWidth,
}: PropsWithChildren<TableProps>) {
  const styles: TableStyles = {};

  if (colWidth) styles["--col-width"] = colWidth;

  return (
    <table style={styles} className={css.table}>
      {children}
    </table>
  );
}
