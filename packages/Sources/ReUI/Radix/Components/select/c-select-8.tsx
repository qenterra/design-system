import {
  Field,
  FieldDescription,
  FieldLabel,
} from "@/components/ui/field"
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"

const items = [
  { label: "Select a fruit", value: null },
  { label: "Apple", value: "apple" },
  { label: "Banana", value: "banana" },
  { label: "Blueberry", value: "blueberry" },
  { label: "Grapes", value: "grapes" },
  { label: "Pineapple", value: "pineapple" },
]

export function Pattern() {
  return (
    <Field className="max-w-xs">
      <FieldLabel htmlFor="select-fruit">Favorite Fruit</FieldLabel>
      <Select>
        <SelectTrigger id="select-fruit">
          <SelectValue placeholder="Select a fruit" />
        </SelectTrigger>
        <SelectContent position="popper">
          <SelectGroup>
            {items.map((item) => (
              <SelectItem key={item.value} value={item.value as string}>
                {item.label}
              </SelectItem>
            ))}
          </SelectGroup>
        </SelectContent>
      </Select>
      <FieldDescription>
        Choose your favorite fruit from the list.
      </FieldDescription>
    </Field>
  )
}