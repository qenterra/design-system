import { Button } from "@/components/ui/button"
import {
  ButtonGroup,
  ButtonGroupText,
} from "@/components/ui/button-group"
import { IconPlaceholder } from "@/app/(create)/components/icon-placeholder"

export function Pattern() {
  return (
    <ButtonGroup>
      <Button size="sm" variant="outline">
        <IconPlaceholder
          lucide="UserPlusIcon"
          tabler="IconUserPlus"
          hugeicons="UserAdd01Icon"
          phosphor="UserPlusIcon"
          remixicon="RiUserAddLine"
          aria-hidden="true"
        />
        Follow
      </Button>
      <ButtonGroupText className="text-muted-foreground">
        2.4k followers
      </ButtonGroupText>
    </ButtonGroup>
  )
}