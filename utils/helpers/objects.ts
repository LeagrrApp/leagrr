export function isObjectEmpty<T extends {}>(objectName: T): boolean {
  return (
    Object.keys(objectName).length === 0 && objectName.constructor === Object
  );
}
