import Link from "next/link";
import accessibility from "./accessibility.module.css";

interface SkipLinksProps {
  links: BasicLink[];
}

export default function SkipLinks({ links }: SkipLinksProps) {
  return (
    <ul className={accessibility.skip_links}>
      {links.map((link) => (
        <li key={link.href}>
          <Link className={accessibility.skip_link} href={link.href}>
            {link.text}
          </Link>
        </li>
      ))}
    </ul>
  );
}
