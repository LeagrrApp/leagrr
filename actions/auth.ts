import { SignupFormSchema, FormState } from "@/lib/definitions";
import { isObjectEmpty } from "@/utils/helpers/objects";

interface ErrorProps {
  email?: string[] | undefined;
  username?: string[] | undefined;
  first_name?: string[] | undefined;
  last_name?: string[] | undefined;
  password?: string[] | undefined;
  password_confirm?: string[] | undefined;
}

interface ResultProps {
  message?: string;
  status?: number;
}

export async function signup(state: FormState, formData: FormData) {
  const userData = {
    email: formData.get("email"),
    username: formData.get("username"),
    first_name: formData.get("first_name"),
    last_name: formData.get("last_name"),
    password: formData.get("password"),
  };

  let errors: ErrorProps = {};

  // Validate form fields
  const validatedFields = SignupFormSchema.safeParse(userData);

  // If any form fields are invalid, return early
  if (!validatedFields.success) {
    errors = validatedFields.error.flatten().fieldErrors;
  }

  // check if passwords match
  if (userData.password !== formData.get("password_confirm")) {
    errors.password_confirm = ["Passwords must match!"];
  }

  if (!isObjectEmpty(errors)) {
    return {
      errors,
    };
  }

  // make POST request to /u/ and provide userData as body
  const postResult = await fetch("/u", {
    method: "POST",
    body: JSON.stringify(userData),
  })
    .then(async (res) => {
      const { message } = await res.json();

      const fetchResult: ResultProps = {
        status: res.status,
        message,
      };

      return fetchResult;
    })
    .catch(() => {
      return {
        message: "There was an issue connecting to the server, try again.",
        status: 500,
      };
    });

  // Sign up failed path ------
  if (postResult.status !== 200) {
    return {
      ...postResult,
    };
  }

  // Sign up successful path ------
  // get new user data

  // create user session

  // redirect user
}
