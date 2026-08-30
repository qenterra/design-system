import { Field } from "@/components/ui/field"
import {
  InputGroup,
  InputGroupAddon,
  InputGroupInput,
  InputGroupText,
} from "@/components/ui/input-group"

export function Pattern() {
  return (
    <Field className="max-w-xs">
      <InputGroup>
        <InputGroupInput placeholder="username" />
        <InputGroupAddon align="inline-end">
          <InputGroupText>@gmail.com</InputGroupText>
        </InputGroupAddon>
      </InputGroup>
    </Field>
  )
}