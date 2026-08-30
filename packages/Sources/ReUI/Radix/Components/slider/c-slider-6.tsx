import { Slider } from "@/components/ui/slider"

export function Pattern() {
  return (
    <div className="flex w-full max-w-xs items-center justify-center">
      <Slider defaultValue={[25, 75]} max={100} step={5} />
    </div>
  )
}