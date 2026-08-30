import { Badge } from "@/components/reui/badge"

import { Field, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"

export function Pattern() {
  return (
    <Field className="max-w-xs">
      <div className="flex items-center justify-between gap-2">
        <FieldLabel htmlFor="middle-name">Middle Name</FieldLabel>
        <Badge variant="warning-outline" size="sm">
          Optional
        </Badge>
      </div>
      <Input id="middle-name" placeholder="Alexander" />
    </Field>
  )
}