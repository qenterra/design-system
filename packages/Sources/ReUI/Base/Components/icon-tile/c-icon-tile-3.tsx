import { IconTile } from "@/components/reui/icon-tile"

import { IconPlaceholder } from "@/app/(create)/components/icon-placeholder"

export function Pattern() {
  return (
    <div className="flex items-center justify-center">
      <IconTile variant="frame" aria-hidden="true">
        <IconPlaceholder
          lucide="LayoutDashboardIcon"
          tabler="IconLayoutDashboard"
          hugeicons="DashboardSquare02Icon"
          phosphor="LayoutIcon"
          remixicon="RiDashboardLine"
        />
      </IconTile>
    </div>
  )
}