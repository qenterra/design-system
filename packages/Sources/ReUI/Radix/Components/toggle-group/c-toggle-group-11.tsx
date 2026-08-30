import {
  ToggleGroup,
  ToggleGroupItem,
} from "@/components/ui/toggle-group"

export function Pattern() {
  return (
    <div className="flex items-center justify-center">
      <ToggleGroup type="single" defaultValue="m" size="sm" variant="outline">
        <ToggleGroupItem value="s">S</ToggleGroupItem>
        <ToggleGroupItem value="m">M</ToggleGroupItem>
        <ToggleGroupItem value="l">L</ToggleGroupItem>
        <ToggleGroupItem value="xl">XL</ToggleGroupItem>
      </ToggleGroup>
    </div>
  )
}