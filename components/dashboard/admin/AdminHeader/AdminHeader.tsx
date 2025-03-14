import Icon from "@/components/ui/Icon/Icon";
import DHeader from "../../DHeader/DHeader";

export default function AdminHeader() {
  return (
    <DHeader>
      <h1>
        <Icon
          icon="admin_panel_settings"
          label="Admin Portal"
          gap="m"
          labelFirst
        />
      </h1>
    </DHeader>
  );
}
