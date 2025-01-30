import { AnchorHTMLAttributes } from "react";
import Icon from "./Icon";

interface IconSportProps extends AnchorHTMLAttributes<HTMLAnchorElement> {
  sport: "hockey" | "soccer" | "basketball" | "pickleball" | "badminton";
  label: string;
  hideLabel?: boolean;
  size?: FontSizeOptions;
  padding?: [SizeOptions, SizeOptions?];
  labelFirst?: boolean;
  gap?: SizeOptions;
}

export default function IconSport({
  sport,
  label,
  hideLabel,
  href,
  className,
  size,
  padding,
  labelFirst,
  gap,
}: IconSportProps) {
  let finalIcon = `sports_${sport}`;

  if (sport === "pickleball" || sport === "badminton")
    finalIcon = "sports_tennis";
  return (
    <Icon
      icon={finalIcon}
      label={label}
      hideLabel={hideLabel}
      href={href}
      className={className}
      size={size}
      padding={padding}
      labelFirst={labelFirst}
      gap={gap}
    />
  );
}
