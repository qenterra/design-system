import { Button } from "@/components/ui/button"
import { IconPlaceholder } from "@/app/(create)/components/icon-placeholder"

export function Pattern() {
  return (
    <Button size="icon-xs" variant="outline" aria-label="Close">
      <IconPlaceholder
        lucide="XIcon"
        tabler="IconX"
        hugeicons="MultiplicationSignIcon"
        phosphor="XIcon"
        remixicon="RiCloseLine"
        aria-hidden="true"
      />
    </Button>
  )
}