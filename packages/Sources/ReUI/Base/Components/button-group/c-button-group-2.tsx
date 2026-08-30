import { Button } from "@/components/ui/button"
import { ButtonGroup } from "@/components/ui/button-group"
import { Input } from "@/components/ui/input"

export function Pattern() {
  return (
    <ButtonGroup>
      <Button variant="outline">Button</Button>
      <Input placeholder="Type something here..." />
    </ButtonGroup>
  )
}