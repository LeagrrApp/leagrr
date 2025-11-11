export function applyClasses(
  initialClass: string | string[],
  additionalClass?: string | string[],
): string {
  // convert provided classes to arrays if provided as a string
  const initialAsArray: string[] =
    typeof initialClass === "string" ? initialClass.split(" ") : initialClass;
  const additionalAsArray: string[] | undefined =
    typeof additionalClass === "string"
      ? additionalClass.split(" ")
      : additionalClass;

  // merge into one array
  const combinedArray: string[] = additionalAsArray
    ? initialAsArray.concat(additionalAsArray)
    : initialAsArray;

  // join array into single string with classes separated by spaces and return
  return combinedArray.join(" ");
}

export function applyClassesConditional(
  initialClass: string | string[],
  additionalClass: string | string[],
  condition: boolean | undefined,
): string {
  if (condition) {
    return applyClasses(initialClass, additionalClass);
  } else {
    return applyClasses(initialClass);
  }
}

export function paddingString(
  paddings: [SizeOptions, SizeOptions?, SizeOptions?, SizeOptions?],
): string {
  const paddingVariableArray: string[] = [];

  paddings.forEach((p) => {
    paddingVariableArray.push(`var(--spacer-${p})`);
  });

  const paddingString = paddingVariableArray.join(" ");

  return paddingString;
}
