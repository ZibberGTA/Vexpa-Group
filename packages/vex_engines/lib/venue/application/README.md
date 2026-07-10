# Application

Venue workflows and orchestration:

- load and update venue profile for management
- aggregate dashboard home data
- coordinate gallery uploads through VexCore storage contracts
- compose public profile sections without duplicate VexCore reads

Calls VexCore `VenueDataService` and permission evaluator; does not talk to Firestore directly.
