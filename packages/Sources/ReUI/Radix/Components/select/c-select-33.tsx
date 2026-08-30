import { Field } from "@/components/ui/field"
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"

const sizes = [
  { label: "Select a size", value: null },
  { label: "Small", value: "sm" },
  { label: "Medium", value: "md" },
  { label: "Large", value: "lg" },
  { label: "Extra Large", value: "xl" },
]

export function Pattern() {
  return (
    <Field className="max-w-xs">
      <Select>
        <SelectTrigger size="sm">
          <SelectValue placeholder="Select a size" />
        </SelectTrigger>
        <SelectContent position="popper">
          <SelectGroup>
            {sizes.map((size) => (
              <SelectItem key={size.value} value={size.value as string}>
                {size.label}
              </SelectItem>
            ))}
          </SelectGroup>
        </SelectContent>
      </Select>
    </Field>
  )
}