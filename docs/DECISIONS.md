# Architecture decision record

## ADR-001: Start with a Rails-native foundation

The project uses Rails conventions with PostgreSQL, Hotwire, Devise, Pundit, Sidekiq, and RSpec. This keeps the initial system approachable and avoids adding a separate frontend or workflow framework before the domain is understood.

## ADR-002: Separate decision from retention

A rule decision such as Keep or Delete is not itself the retention schedule. Retention is modeled independently so policy changes and legal/operational holds can be applied without rewriting the original decision history.

## ADR-003: Make rule conflicts observable

Priority plus a stable tie-breaker determines the winner. Evaluations retain match and winner information, allowing operators to explain every automatic decision and identify ambiguous configurations.
