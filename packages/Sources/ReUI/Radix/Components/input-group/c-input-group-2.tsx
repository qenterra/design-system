import { Field } from "@/components/ui/field"
import {
  InputGroup,
  InputGroupInput,
} from "@/components/ui/input-group"

export function Pattern() {
  return (
    <Field className="max-w-xs" data-disabled="true">
      <InputGroup>
        <InputGroupInput placeholder="Disabled field" disabled />
      </InputGroup>
    </Field>
  )
}