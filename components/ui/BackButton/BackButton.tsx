import { MouseEventHandler } from "react";
import Icon from "../Icon/Icon";
import ButtonInvis from "../ButtonInvis/ButtonInvis";

interface BackButtonProps {
  onClick?: MouseEventHandler<HTMLButtonElement>;
  href?: string;
  label?: string;
}

export default function BackButton({ onClick, href, label }: BackButtonProps) {
  if (href) {
    return (
      <Icon
        className="push"
        icon="chevron_left"
        label={label || "Back"}
        href={href}
        gap="ml"
        size="h4"
      />
    );
  }

  if (onClick) {
    return (
      <ButtonInvis onClick={onClick}>
        <Icon
          className="push"
          icon="chevron_left"
          label={label || "Back"}
          gap="ml"
          size="h4"
        />
      </ButtonInvis>
    );
  }

  return null;
}
