import { CSSProperties, PropsWithChildren } from "react";
import css from "./dashboardUnit.module.css";
import { apply_classes } from "@/utils/helpers/html-attributes";

interface DashboardUnitProps {
  className?: string | string[];
  gridArea?: string;
}

interface DashboardUnitStyles extends CSSProperties {
  "--grid-area"?: string;
}

export default function DashboardUnit({
  children,
  className,
  gridArea,
}: PropsWithChildren<DashboardUnitProps>) {
  const styles: DashboardUnitStyles = {};

  if (gridArea) styles["--grid-area"] = gridArea;

  return (
    <div
      style={styles}
      className={apply_classes(css.dashboard_unit, className)}
    >
      {children}
    </div>
  );
}
