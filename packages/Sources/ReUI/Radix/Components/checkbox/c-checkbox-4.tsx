import { Checkbox } from "@/components/ui/checkbox"
import { Field, FieldLabel } from "@/components/ui/field"

export function Pattern() {
  return (
    <Field orientation="horizontal" className="w-auto">
      <Checkbox id="indeterminate" checked="indeterminate" />
      <FieldLabel htmlFor="indeterminate">Indeterminate state</FieldLabel>
    </Field>
  )
}