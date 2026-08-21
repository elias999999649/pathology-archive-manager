# Architecture foundation

## Bounded areas

The application will be organized around these bounded areas:

- **Identity and access**: users, roles, authentication, authorization, and security events.
- **Slide archive**: imported slide metadata, search, tags, status, and lifecycle state.
- **Rules**: versioned rule definitions, condition groups, actions, priority, and simulation.
- **Retention**: retention policies and scheduled lifecycle processing.
- **Integrations**: external pathology API connections, adapters, sync runs, and failures.
- **Operations**: storage providers, notifications, audit logs, and system settings.

The first implementation should establish one area at a time and avoid introducing models for areas that do not yet have behavior.

## Application layering

- Controllers handle HTTP concerns, parameter normalization, and rendering.
- Models own persistence constraints and small domain invariants.
- `app/services` owns multi-step business operations and integration orchestration.
- `app/policies` owns Pundit authorization decisions.
- `app/jobs` owns retryable asynchronous work and delegates business logic to services.
- Provider-specific API and storage translations live under `app/services` behind stable adapter interfaces.
- Views remain presentation-only and use shared UI components/partials for consistency.

## Rule evaluation contract

Rule evaluation will be deterministic:

1. Consider enabled rules whose conditions match the slide.
2. Order matches by descending priority, then ascending immutable rule identifier as a tie-breaker.
3. The first match is the winning rule and supplies the primary decision.
4. Every evaluation records all matching rules, the winner, and the explanation used to reach the decision.
5. If a rule set cannot produce a valid decision, the slide is sent to Manual Review and the evaluation is audited rather than silently discarded.

Simulation uses the same evaluator against a read-only query scope and never mutates slides or lifecycle state.

Rules are evaluated only when enabled. Matching rules are ordered by descending priority; ties are resolved by ascending UUID to provide a stable deterministic order. The first matching rule wins. Within a winning rule, exactly one decision action is required; operational actions are recorded in their declared order. No match produces an `undecided` evaluation, which routes the slide to manual review during import. Each evaluation stores every matched rule, the winner, condition results, actions, final decision, and reason. Evaluation records intended decisions only; they do not delete or mutate slides.

## Safety principles

- Destructive lifecycle actions are asynchronous, audited, and require an explicit confirmation workflow for manual operations.
- Important records use soft deletion or a recoverable trash state where practical.
- External credentials use encrypted Rails credentials/attributes and are never hard-coded.
- Automatic deletion decisions stop at an auditable scheduled/soft-delete workflow. Permanent deletion is a separate future operation and is not part of import processing.
- API and storage providers are accessed through adapters so provider changes do not leak into domain models.
- Database foreign keys, unique constraints, and targeted indexes are added with each feature rather than deferred.

## Delivery sequence

1. Application shell, authentication, roles, shared layout, and health check.
2. Slide metadata import and server-side search.
3. Rules, versioning, evaluation audit, and simulation.
4. Retention policies and lifecycle jobs.
5. Integrations, storage, notifications, and operational dashboards.

Each step should include focused model/service/policy/request tests and should be delivered independently.
