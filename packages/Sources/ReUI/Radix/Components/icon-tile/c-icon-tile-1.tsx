import { IconTile } from "@/components/reui/icon-tile"

import { IconPlaceholder } from "@/app/(create)/components/icon-placeholder"

export function Pattern() {
  return (
    <div className="flex items-center justify-center">
      <IconTile aria-hidden="true">
        <IconPlaceholder
          lucide="FolderIcon"
          tabler="IconFolder"
          hugeicons="FolderIcon"
          phosphor="FolderIcon"
          remixicon="RiFolderLine"
        />
      </IconTile>
    </div>
  )
}