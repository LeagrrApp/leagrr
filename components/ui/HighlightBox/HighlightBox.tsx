import { applyColor } from "@/utils/helpers/formatting";
import { apply_classes, paddingString } from "@/utils/helpers/html-attributes";
import { CSSProperties, PropsWithChildren } from "react";
import css from "./highlighBox.module.css";

interface HighlightBoxProps {
  className?: string | string[];
  type?: ColorOptions | string;
  fontSize?: FontSizeOptions;
  marginStart?: SizeOptions;
  marginEnd?: SizeOptions;
  center?: boolean;
  padding?: [SizeOptions, SizeOptions?];
}

interface HighlighBoxStyles extends CSSProperties {
  "--hb-color": string;
  "--hb-bg": string;
  "--hb-font-size"?: string;
  "--hb-margin-start"?: string;
  "--hb-margin-end"?: string;
  "--hb-padding"?: string;
}

export default function HighlightBox({
  className,
  children,
  type,
  fontSize,
  marginStart,
  marginEnd,
  center,
  padding,
}: PropsWithChildren<HighlightBoxProps>) {
  const styles: HighlighBoxStyles = {
    "--hb-color": applyColor(type || "primary"),
    "--hb-bg": applyColor(type || "primary", "lightest"),
  };

  if (fontSize) {
    styles["--hb-font-size"] = `var(--type-scale-${fontSize})`;
  }

  if (marginStart) styles["--hb-margin-start"] = `var(--spacer-${marginStart})`;
  if (marginEnd) styles["--hb-margin-end"] = `var(--spacer-${marginEnd})`;
  if (center) styles.textAlign = "center";
  if (padding) styles["--hb-padding"] = paddingString(padding);

  return (
    <div style={styles} className={apply_classes(css.highlight_box, className)}>
      {children}
    </div>
  );
}
