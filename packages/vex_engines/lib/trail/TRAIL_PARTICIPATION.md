# Trail venue participation applications

Workflow type: `trail.venue_participation`

## Ownership

| Concern | Owner |
| --- | --- |
| Request lifecycle, status, audit | VexWorkflow |
| Participation eligibility, payload meaning, approval planning | VexTrail |
| Repository contracts, snapshots, commands | VexCore |
| UI, navigation, form state | Venue Management (nightlife_web) |
| Firestore mapping, queries, batch writes | Firebase adapters |

## Subject references

Required stable subject refs on every request:

- `trailId`
- `venueId`

Indexed top-level query fields mirror subject refs:

- `subjectTrailId`
- `subjectVenueId`

## Payload schema (v1)

```json
{
  "schemaVersion": 1,
  "trailId": "trail-id",
  "venueId": "venue-id",
  "requestedStopOrder": 3,
  "participationNote": "Why we want to join"
}
```

## Trail participation settings

Stored on trail documents (`participationSettings` nested object or legacy top-level fields):

| Field | Default |
| --- | --- |
| `acceptsVenueApplications` | `false` |
| `participationApplicationOpensAt` | null |
| `participationApplicationClosesAt` | null |
| `maximumStops` | null (no explicit cap) |
| `venueSelectableStopPosition` | `true` |
| `participationInstructions` | empty |

Existing trails do **not** accept applications unless explicitly enabled.

## Eligibility (pure policy)

Evaluated without repository access. Blocking reasons include:

- Trail not published / archived / disabled
- Applications not accepted
- Non-curated trail type
- Application window closed or not yet open
- Venue already a stop
- Duplicate open application
- Approved application exists
- Invalid requested stop position
- Trail capacity reached (`maximumStops`)
- Venue not manageable

## Duplicate and reapply policy

| Existing status | Behaviour |
| --- | --- |
| Draft, submitted, under review, information requested | Blocks new application |
| Approved | Blocks new application |
| Rejected, withdrawn, cancelled, expired | May create a new request |
| Information requested | Must resubmit same request ID |

## Permissions (venue users)

Allowed:

- Create/update draft for managed venue
- Submit, resubmit after information requested, withdraw own open requests
- Read own venue applications and permitted audit entries

Not allowed:

- Approve, reject, assign reviewer, request information, cancel as admin

Privileged actions must use trusted command execution (callable/gateway).

## Approval consequence planning

`TrailParticipationApprovedHandler` returns a `TrailParticipationApprovalPlan` only.

**No automatic trail stop mutation occurs in this phase.** Administrator review will execute or confirm placement later.

## Persistence

```
workflow_requests/{requestId}
workflow_requests/{requestId}/audit/{auditId}
```

Venue-side writes use Firestore batch: request document + append-only audit entry.

## Non-goals (this phase)

- Administrator review inbox
- Automatic approved-venue insertion into trail stops
- Notifications and analytics aggregation
- Mobile customer trail UI changes

## Venue Management UI (nightlife_web)

Venue managers complete participation through the Trails tab:

1. Browse eligible trails and open an application form
2. Save a draft or submit immediately
3. View application detail, audit history, and status guidance
4. Edit drafts, respond to information requests, resubmit, or withdraw
5. Reapply after terminal states when policy permits

Presentation models hide Firestore payloads. All writes go through
`VenueTrailParticipationRepository` → `TrailParticipationApplicationService`.

### Draft behaviour

Draft requests retain the same `requestId`. Updates mutate payload fields only;
workflow type and subject references remain immutable.

### Information-requested resubmission

Venue managers edit permitted payload fields and resubmit the same request.
Revision increments and audit records a `resubmitted` entry; status returns to
`submitted`.

### Withdrawal

Permitted for open statuses (`submitted`, `under_review`, `information_requested`).
Documents are retained; audit records `withdrawn`.

### Reapplication

After `rejected`, `withdrawn`, `cancelled`, or `expired`, a new request may be
created when eligibility and duplicate policy allow.

### Audit visibility

Venues see submitter-side audit entries with venue-safe labels. Reviewer UIDs and
internal decision codes are not shown in the UI.

### Revision handling

Repository operations pass `expectedRevision`. Stale writes return a conflict
result; the UI prompts refresh rather than overwriting concurrent changes.

### Rules enforcement (known limitations)

Firestore rules validate venue ownership, immutable subject refs, and allowed
status transitions. Rules do **not** fully validate audit action semantics,
revision monotonicity, or draft+audit batch creates. See
`apps/nightlife_app/tests/firestore.rules.test.js` workflow describe block.

### Approval does not mutate trail stops

Approved applications display confirmation only. Trail stop placement remains a
separate administrator process (deferred).
