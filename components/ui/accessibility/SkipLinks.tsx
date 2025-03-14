import accessibility from "./accessibility.module.css";

interface SkipLinksProps {
  links: BasicLink[];
}

export default function SkipLinks({ links }: SkipLinksProps) {
  return (
    <ul className={accessibility.skip_links}>
      {links.map((link) => (
        <li key={link.href}>
          <a className={accessibility.skip_link} href={link.href}>
            {link.text}
          </a>
        </li>
      ))}
    </ul>
  );
}
