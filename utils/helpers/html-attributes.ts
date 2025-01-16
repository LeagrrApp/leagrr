export function apply_classes(
  classes: string[] | string,
  additionalClasses?: string[] | string
): string {
  if (!classes) return "";

  if (typeof classes === "string") {
    if (!additionalClasses) return classes;

    if (typeof additionalClasses === "string")
      return `${classes} ${additionalClasses}`;
  }

  const updatedClassesArray = [...classes];

  if (additionalClasses) {
    if (typeof additionalClasses === "string") {
      updatedClassesArray.push(additionalClasses);
    } else {
      updatedClassesArray.forEach((c) => {
        updatedClassesArray.push(c);
      });
    }
  }

  return updatedClassesArray.join(" ");
}

export function paddingString(paddings: SizeOptions[]): string {
  const paddingVariableArray: string[] = [];

  paddings.forEach((p) => {
    paddingVariableArray.push(`var(--spacer-${p})`);
  });

  const paddingString = paddingVariableArray.join(" ");

  return paddingString;
}
