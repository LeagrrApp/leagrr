export function check_string_is_color_hex(string: string): boolean {
  const regex =
    /^#([a-fA-F0-9]{8}|[a-fA-F0-9]{6}|[a-fA-F0-9]{4}|[a-fA-F0-9]{3})$/;

  return regex.test(string);
}
