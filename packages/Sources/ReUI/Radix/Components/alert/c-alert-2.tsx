import {
  Alert,
  AlertDescription,
  AlertTitle,
} from "@/components/reui/alert"

import { IconPlaceholder } from "@/app/(create)/components/icon-placeholder"

export function Pattern() {
  return (
    <Alert>
      <IconPlaceholder
        lucide="CircleCheckIcon"
        tabler="IconCircleCheck"
        hugeicons="CheckmarkCircle01Icon"
        phosphor="CheckCircleIcon"
        remixicon="RiCheckboxCircleLine"
      />
      <AlertTitle>Alert!</AlertTitle>
      <AlertDescription>
        This is an alert with icon, title and description.
      </AlertDescription>
    </Alert>
  )
}