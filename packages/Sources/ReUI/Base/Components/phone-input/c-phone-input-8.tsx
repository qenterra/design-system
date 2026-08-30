import { PhoneInput } from "@/components/reui/phone-input"

export function Pattern() {
  return (
    <PhoneInput
      readOnly
      value="+12125551234"
      placeholder="Enter phone number"
    />
  )
}