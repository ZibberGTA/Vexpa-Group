/// Lifecycle actions distinct from workflow status values.
enum WorkflowAction {
  createDraft,
  updateDraft,
  submit,
  resubmit,
  startReview,
  requestInformation,
  approve,
  reject,
  withdraw,
  cancel,
  expire,
  assignReviewer,
}
