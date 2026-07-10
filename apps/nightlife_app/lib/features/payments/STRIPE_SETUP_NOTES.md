# Stripe setup notes

This lib is wired for the Firebase Stripe Checkout extension style flow:

1. Create Stripe Products/Prices for each boost plan.
2. Replace the placeholder Price IDs in `features/payments/services/stripe_checkout_service.dart`.
3. Configure Firebase/Stripe Checkout sessions so docs written to:
   `customers/{uid}/checkout_sessions/{sessionId}`
   receive a generated `url`, `status`, and `payment_status`.
4. In production, connect the generated Checkout URL to `url_launcher`, a web redirect, or your app's deep link handler.
5. Boosts only activate automatically after the checkout session is marked paid/complete.

Do not put Stripe secret keys in Flutter/Dart client code.
