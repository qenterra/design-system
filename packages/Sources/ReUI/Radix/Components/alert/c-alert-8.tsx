import {
  Alert,
  AlertDescription,
  AlertTitle,
} from "@/components/reui/alert"

import { IconPlaceholder } from "@/app/(create)/components/icon-placeholder"

export function Pattern() {
  return (
    <Alert variant="destructive">
      <IconPlaceholder
        lucide="CircleAlertIcon"
        tabler="IconAlertCircle"
        hugeicons="AlertCircleIcon"
        phosphor="WarningCircleIcon"
        remixicon="RiErrorWarningLine"
      />
      <AlertTitle>Error! Something went wrong</AlertTitle>
      <AlertDescription>
        Please try again. If the problem persists, contact support.
      </AlertDescription>
    </Alert>
  )
}