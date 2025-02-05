export function isObjectEmpty<T extends {}>(objectName: T): boolean {
  return (
    Object.keys(objectName).length === 0 && objectName.constructor === Object
  );
}

export function get_unique_items<T>(a: T[], b: T[]): T[] {
  const stringifiedA = a.map((p) => JSON.stringify(p));
  const stringifiedB = b.map((p) => JSON.stringify(p));

  const uniqueA = a.filter((p) => !stringifiedB.includes(JSON.stringify(p)));
  const uniqueB = b.filter((p) => !stringifiedA.includes(JSON.stringify(p)));

  return [...uniqueA, ...uniqueB];
}

export function get_unique_items_by_key<T extends { [key: string]: any }>(
  a: T[],
  b: T[],
  key: string,
): T[] {
  const a_values = a.map((item) => item[key]);
  const b_values = b.map((item) => item[key]);

  const uniqueA = a.filter((item) => !b_values.includes(item[key]));
  const uniqueB = b.filter((item) => !a_values.includes(item[key]));

  return [...uniqueA, ...uniqueB];
}
