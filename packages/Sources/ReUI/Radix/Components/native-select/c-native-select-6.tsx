import {
  NativeSelect,
  NativeSelectOption,
} from "@/components/ui/native-select"

export function Pattern() {
  return (
    <NativeSelect aria-invalid="true" className="w-full max-w-xs">
      <NativeSelectOption value="">Invalid Select</NativeSelectOption>
      <NativeSelectOption value="1">Option 1</NativeSelectOption>
    </NativeSelect>
  )
}