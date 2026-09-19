# Debt ledger

Non-blocking findings from `/audit-sprint`, one row per finding. Reviewed
and cleared in the hardening sprint, not before.

| Sprint | Location | Finding | Status |
|---|---|---|---|
| 04 | internal/user/repository.go, service.go | Repository and service wrap errors with the same word for List, Update and Delete ("list users: list users: ..."); Create/Get use a different word per layer and don't repeat. | Open |
