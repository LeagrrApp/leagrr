import SignInForm from "@/components/auth/SignInForm";
import Container from "@/components/ui/Container/Container";
import { createMetaTitle } from "@/utils/formatting";
import page from "./page.module.css";

export const metadata = {
  title: createMetaTitle(["Sign In"], { excludeDashboard: true }),
};

export default function Page() {
  return (
    <main className={page.sign_in}>
      <div className={page.sign_in_wrap}>
        <Container maxWidth="35rem">
          <SignInForm />
        </Container>
      </div>
      <div className={page.sign_in_image}></div>
    </main>
  );
}
