import { Button } from "@/components/ui/button"
import { IconPlaceholder } from "@/app/(create)/components/icon-placeholder"

export function Pattern() {
  return (
    <Button variant="destructive">
      <IconPlaceholder
        lucide="Trash2Icon"
        tabler="IconTrash"
        hugeicons="Delete02Icon"
        phosphor="TrashIcon"
        remixicon="RiDeleteBinLine"
        aria-hidden="true"
      />
      Delete Account
    </Button>
  )
}