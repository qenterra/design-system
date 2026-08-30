import { Field, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"

export function Pattern() {
  return (
    <Field className="w-full max-w-xs">
      <FieldLabel htmlFor="pill-input">Search</FieldLabel>
      <Input
        id="pill-input"
        className="rounded-full px-4"
        placeholder="Search everything..."
      />
    </Field>
  )
}