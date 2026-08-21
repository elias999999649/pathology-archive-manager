# Pathology Archive Manager

Pathology Archive Manager is a Rails application for receiving digital pathology slide metadata from external systems, evaluating configurable archive rules, and managing retention and review workflows.

The current implementation includes the authenticated archive console, slide search and review workflows, configurable archive rules, retention tracking, API connection monitoring, storage monitoring, audit logs, and the responsive operations dashboard. Permanent deletion and vendor-specific API payload ingestion remain intentionally outside the current scope.

## Baseline stack

- Ruby 3.3+
- Rails 8
- PostgreSQL
- Hotwire (Turbo and Stimulus)
- Tailwind CSS
- Devise authentication
- Pundit authorization
- Sidekiq background jobs
- RSpec tests

## Local setup

Ruby, PostgreSQL, and Redis are required locally.

```sh
bundle install
bin/rails db:prepare
bin/dev
```

The application will use PostgreSQL for durable data and Redis as the Sidekiq backend. Credentials must be supplied through environment variables or Rails credentials; they must never be committed to the repository.

Production also requires `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`, `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY`, and `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT`. These keys encrypt API connection credentials at rest and must be managed by the deployment secret store.

For production, also provide `DATABASE_URL`, `REDIS_URL`, `RAILS_MASTER_KEY` or the Active Record encryption keys above, and run both the web process and the Sidekiq worker. Apply migrations with `bin/rails db:migrate` before serving traffic. The application health endpoint is available at `/up`.

## Product boundaries

This is an archive management system, not a pathology image viewer. It stores and evaluates slide metadata, archive decisions, retention state, integrations, audit events, and operational status. Image rendering is explicitly outside the initial scope.

## Architecture decisions

The initial architecture is documented in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md). The implementation will favor Rails-native conventions, thin controllers, policy objects for authorization, service objects for orchestration, and background jobs for integration and retention work.
