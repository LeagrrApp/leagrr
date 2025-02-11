type FormState<E, D> =
  | {
      errors?: E;
      message?: string;
      status?: number;
      link?: string;
      data: D;
    }
  | undefined;

type UserErrorProps = {
  email?: string[] | undefined;
  username?: string[] | undefined;
  first_name?: string[] | undefined;
  last_name?: string[] | undefined;
  password?: string[] | undefined;
  password_confirm?: string[] | undefined;
};

type UserFormState = FormState<
  UserErrorProps,
  {
    email: string;
    username: string;
    first_name: string;
    last_name: string;
    gender?: string;
    pronouns?: string;
    user_role?: number;
    img?: string;
    password?: string;
    identifier?: string;
  }
>;
