import { Field, FieldLabel } from "@/components/ui/field"
import { Textarea } from "@/components/ui/textarea"

export function Pattern() {
  return (
    <div className="mx-auto w-full max-w-xs">
      <Field className="w-full">
        <FieldLabel htmlFor="textarea-disabled">Message (Disabled)</FieldLabel>
        <Textarea
          id="textarea-disabled"
          placeholder="Type your message here…"
          disabled
        />
      </Field>
    </div>
  )
}