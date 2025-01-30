import Image from "next/image";
import css from "./profileImg.module.css";

interface ProfileImgProps {
  src?: string;
  label: string;
  size?: number;
}

export default function ProfileImg({ src, label, size }: ProfileImgProps) {
  return (
    <div className={css.profile_img}>
      <Image
        src={src || "/profile-ph.jpg"}
        alt={label}
        width={size || 50}
        height={size || 50}
      />
    </div>
  );
}
