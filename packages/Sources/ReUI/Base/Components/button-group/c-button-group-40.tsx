import { cn } from "@/lib/utils"
import { Button } from "@/components/ui/button"
import { ButtonGroup } from "@/components/ui/button-group"

export function Pattern() {
  return (
    <ButtonGroup orientation="vertical">
      <Button variant="outline" className={cn("bg-muted justify-start")}>
        Dashboard
      </Button>
      <Button variant="outline" className="justify-start">
        Analytics
      </Button>
      <Button variant="outline" className="justify-start">
        Settings
      </Button>
      <Button variant="outline" className="justify-start">
        Help
      </Button>
    </ButtonGroup>
  )
}