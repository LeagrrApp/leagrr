import { applyColor } from "@/utils/helpers/formatting";

interface IndicatorProps {
  color?: string;
  size?: string;
}

export default function Indicator({ color, size }: IndicatorProps) {
  const fill = color ? applyColor(color) : "var(--color-secondary)";
  const stroke = color
    ? applyColor(color, "dark")
    : "var(--color-secondary-dark)";

  const width = size || "0.75em";

  return (
    <svg
      style={{ width }}
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 16 16"
    >
      <path
        fill={fill}
        d="M12.07,15.5c-.49,0-.96-.13-1.39-.38L2.53,10.42c-.88-.5-1.4-1.41-1.4-2.42s.52-1.91,1.4-2.42L10.68.88c.44-.25.9-.38,1.39-.38,1.35,0,2.8,1.07,2.8,2.8v9.4c0,1.73-1.45,2.8-2.8,2.8Z"
      />
      <path
        fill={stroke}
        d="M12.07,1h0c1.1,0,2.3.88,2.3,2.3v9.41c0,1.42-1.19,2.3-2.3,2.3-.4,0-.78-.1-1.14-.31L2.78,9.99c-.72-.41-1.15-1.16-1.15-1.99s.43-1.57,1.15-1.98L10.93,1.31c.36-.21.74-.31,1.14-.31M12.07,0c-.55,0-1.11.14-1.64.45L2.28,5.15C.09,6.42.09,9.58,2.28,10.85l8.15,4.7c.53.31,1.09.45,1.64.45,1.72,0,3.3-1.38,3.3-3.3V3.3C15.37,1.38,13.79,0,12.07,0h0Z"
      />
    </svg>
  );
}
