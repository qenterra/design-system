import { Button } from "@/components/ui/button"
import { IconPlaceholder } from "@/app/(create)/components/icon-placeholder"

export function Pattern() {
  return (
    <Button variant="secondary">
      <IconPlaceholder
        lucide="GithubIcon"
        tabler="IconBrandGithub"
        hugeicons="GithubIcon"
        phosphor="GithubLogoIcon"
        remixicon="RiGithubLine"
        aria-hidden="true"
      />
      Github
    </Button>
  )
}