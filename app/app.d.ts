interface ResultProps {
  message: string;
  status: number;
}

interface UserSelectResultProps extends ResultProps {
  data?: UserData;
}

// TODO: flush this out to include expanded role and gender information
interface UserData {
  user_id?: number;
  first_name?: string;
  last_name?: string;
  username?: string;
  email?: string;
  pronouns?: string;
  user_role?: number;
  role?: number;
  password_hash?: string;
}
