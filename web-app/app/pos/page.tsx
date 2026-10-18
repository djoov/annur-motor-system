import { redirect } from "next/navigation"

// Web is for monitoring only; sales are made in the mobile app.
// The old web POS is in git history (commit 43ddc08) if it is ever needed.
export default function PosPage() {
  redirect("/dashboard")
}
