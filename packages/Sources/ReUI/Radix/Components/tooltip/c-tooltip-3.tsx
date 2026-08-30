import { Button } from "@/components/ui/button"
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip"
import { IconPlaceholder } from "@/app/(create)/components/icon-placeholder"

export function Pattern() {
  return (
    <div className="flex items-center justify-center">
      <TooltipProvider>
        <Tooltip>
          <TooltipTrigger asChild>
            <Button variant="ghost" size="icon" aria-label="More information">
              <IconPlaceholder
                lucide="InfoIcon"
                tabler="IconInfoCircle"
                hugeicons="InformationCircleIcon"
                phosphor="InfoIcon"
                remixicon="RiInformationLine"
              />
            </Button>
          </TooltipTrigger>
          <TooltipContent>
            <p className="text-center text-sm">
              Additional information and help context.
            </p>
          </TooltipContent>
        </Tooltip>
      </TooltipProvider>
    </div>
  )
}