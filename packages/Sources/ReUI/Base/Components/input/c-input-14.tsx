import { Field, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"

export function Pattern() {
  return (
    <Field className="max-w-xs">
      <FieldLabel htmlFor="input-demo-time">Time</FieldLabel>
      <Input id="input-demo-time" type="time" />
    </Field>
  )
}