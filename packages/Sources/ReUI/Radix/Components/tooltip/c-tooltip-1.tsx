import { Button } from "@/components/ui/button"
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip"

export function Pattern() {
  return (
    <div className="flex items-center justify-center">
      <TooltipProvider>
        <Tooltip>
          <TooltipTrigger asChild>
            <Button variant="outline" className="w-fit">
              Show Tooltip
            </Button>
          </TooltipTrigger>
          <TooltipContent>
            <p className="text-sm">Add to library</p>
          </TooltipContent>
        </Tooltip>
      </TooltipProvider>
    </div>
  )
}