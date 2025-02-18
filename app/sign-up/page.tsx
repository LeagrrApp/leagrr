import SignUpForm from "@/components/auth/SignUpForm";
import Container from "@/components/ui/Container/Container";
import { createMetaTitle } from "@/utils/helpers/formatting";
import page from "./page.module.css";

export const metadata = {
  title: createMetaTitle(["Sign Up"], { excludeDashboard: true }),
};

export default function Page() {
  return (
    <main className={page.sign_up}>
      <Container maxWidth="35rem">
        <SignUpForm />
      </Container>
    </main>
  );
}
