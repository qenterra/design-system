import { Button } from "@/components/ui/button"
import {
  ButtonGroup,
  ButtonGroupText,
} from "@/components/ui/button-group"
import { IconPlaceholder } from "@/app/(create)/components/icon-placeholder"

export function Pattern() {
  return (
    <ButtonGroup>
      <Button size="sm" className="border-primary">
        <IconPlaceholder
          lucide="Share2Icon"
          tabler="IconShare"
          hugeicons="Share08Icon"
          phosphor="ShareNetworkIcon"
          remixicon="RiStackshareLine"
          className="..."
        />
        Share
      </Button>
      <ButtonGroupText className="text-muted-foreground bg-transparent px-2">
        128 Shares
      </ButtonGroupText>
    </ButtonGroup>
  )
}