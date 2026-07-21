# Venue Management — Trail Participation Regression Checklist

Manual checks for the venue-facing `trail.venue_participation` workflow.

## Eligible trails

- [ ] Trail accepts applications
- [ ] Trail does not accept applications
- [ ] Application window open
- [ ] Application window closed
- [ ] Venue already a stop
- [ ] Capacity reached

## New application

- [ ] Open form from eligible trail
- [ ] Client validation (note, position)
- [ ] Save draft
- [ ] Edit draft
- [ ] Submit
- [ ] List refresh and highlight
- [ ] Reopen submitted application

## Existing applications

- [ ] Submitted (read-only, withdraw)
- [ ] Under review (read-only, withdraw)
- [ ] Information requested (reviewer note, respond, resubmit)
- [ ] Withdraw confirmation and success
- [ ] Approved (no stop mutation claimed)
- [ ] Rejected (decision reason, reapply if allowed)
- [ ] Cancelled / expired (history, reapply if allowed)

## Security

- [ ] Unrelated venue account denied
- [ ] Unmanaged venue denied
- [ ] Direct client attempt to set `approved` denied
- [ ] Direct client attempt to change subject refs denied
- [ ] Direct client attempt to edit audit denied

## Data

- [ ] Request document fields and revision
- [ ] Audit documents append-only
- [ ] Immutable subject references
- [ ] Indexed query fields populated
- [ ] No duplicate open request

## Responsive

- [ ] Narrow browser
- [ ] Tablet
- [ ] Desktop
