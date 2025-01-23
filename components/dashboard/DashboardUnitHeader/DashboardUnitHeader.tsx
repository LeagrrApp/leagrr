import { CSSProperties, PropsWithChildren } from "react";
import css from "./dashboardUnitHeader.module.css";
import { apply_classes } from "@/utils/helpers/html-attributes";

interface DashboardUnitHeaderProps {
  className?: string | string[];
}

interface DashboardUnitHeaderStyles extends CSSProperties {
  "--grid-area"?: string;
}

export default function DashboardUnitHeader({
  children,
  className,
}: PropsWithChildren<DashboardUnitHeaderProps>) {
  const styles: DashboardUnitHeaderStyles = {};

  return (
    <div
      style={styles}
      className={apply_classes(css.dashboard_unit_header, className)}
    >
      {children}
    </div>
  );
}
