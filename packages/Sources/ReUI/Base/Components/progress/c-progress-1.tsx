import {
  Progress,
  ProgressLabel,
  ProgressValue,
} from "@/components/ui/progress"

export function Pattern() {
  return (
    <div className="mx-auto w-full max-w-xs">
      <Progress value={56}>
        <ProgressLabel>Upload progress</ProgressLabel>
        <ProgressValue />
      </Progress>
    </div>
  )
}