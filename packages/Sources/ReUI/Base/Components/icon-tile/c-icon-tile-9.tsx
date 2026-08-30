import { IconTile } from "@/components/reui/icon-tile"

export function Pattern() {
  return (
    <div className="flex items-center justify-center gap-3">
      <IconTile variant="elevated" className="text-xs font-medium">
        AK
      </IconTile>
      <IconTile
        variant="outline"
        radius="full"
        className="text-muted-foreground text-xs font-medium"
      >
        12
      </IconTile>
    </div>
  )
}