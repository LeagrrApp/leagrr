import { applyClasses } from "@/utils/helpers/html-attributes";
import Image from "next/image";
import css from "./profileImg.module.css";

interface ProfileImgProps {
  src?: string;
  label: string;
  size?: number;
  className?: string | string[];
}

export default function ProfileImg({
  src,
  label,
  size,
  className,
}: ProfileImgProps) {
  return (
    <div className={applyClasses(css.profile_img, className)}>
      <Image
        src={src || "/profile-ph.jpg"}
        alt={label}
        width={size || 50}
        height={size || 50}
      />
    </div>
  );
}
