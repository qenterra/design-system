import { Field } from "@/components/ui/field"
import {
  InputGroup,
  InputGroupAddon,
  InputGroupInput,
} from "@/components/ui/input-group"
import { IconPlaceholder } from "@/app/(create)/components/icon-placeholder"

export function Pattern() {
  return (
    <Field className="max-w-xs">
      <InputGroup>
        <InputGroupAddon>
          <IconPlaceholder
            lucide="SearchIcon"
            tabler="IconSearch"
            hugeicons="Search01Icon"
            phosphor="MagnifyingGlassIcon"
            remixicon="RiSearchLine"
          />
        </InputGroupAddon>
        <InputGroupInput placeholder="Search..." />
      </InputGroup>
    </Field>
  )
}