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
        <InputGroupAddon className="pr-2">
          <InputGroupText>€</InputGroupText>
        </InputGroupAddon>
        <InputGroupInput
          placeholder="0.00"
          className="border-border border-x"
        />
        <InputGroupAddon align="inline-end" className="pl-2">
          <InputGroupText>EUR</InputGroupText>
        </InputGroupAddon>
      </InputGroup>
    </Field>
  )
}