import { applyClasses } from "@/utils/helpers/html-attributes";
import { CSSProperties, PropsWithChildren } from "react";
import css from "./dashboardUnit.module.css";

interface DashboardUnitProps {
  className?: string | string[];
  gridArea?: string;
  stretch?: boolean;
}

interface DashboardUnitStyles extends CSSProperties {
  "--grid-area"?: string;
}

export default function DashboardUnit({
  children,
  className,
  gridArea,
  stretch,
}: PropsWithChildren<DashboardUnitProps>) {
  const classes = [css.dashboard_unit];

  if (stretch) classes.push(css.dashboard_unit_stretch);

  const styles: DashboardUnitStyles = {};

  if (gridArea) styles["--grid-area"] = gridArea;

  return (
    <div style={styles} className={applyClasses(classes, className)}>
      {children}
    </div>
  );
}
