import { Field, FieldError } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"

export function Pattern() {
  return (
    <Field className="w-full max-w-xs" data-invalid="true">
      <Label htmlFor="label-error">Email</Label>
      <Input
        id="label-error"
        type="email"
        defaultValue="invalid-email"
        aria-invalid="true"
      />
      <FieldError>Please enter a valid email address</FieldError>
    </Field>
  )
}