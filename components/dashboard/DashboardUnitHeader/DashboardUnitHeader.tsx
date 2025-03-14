import { applyClasses } from "@/utils/helpers/html-attributes";
import { CSSProperties, PropsWithChildren } from "react";
import css from "./dashboardUnitHeader.module.css";

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
      className={applyClasses(css.dashboard_unit_header, className)}
    >
      {children}
    </div>
  );
}
