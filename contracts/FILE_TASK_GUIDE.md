# Contracts Task Plan (Task 1 to Task 6)

Each member should pick exactly one task. The tasks are split one-to-one for 6 members.

## Task 1 - Core Stream Contract
- Owner: Member 1
- Main file: src/TrustlessSalaryStreamer.sol
- Supporting files: src/interfaces/ITrustlessSalaryStreamer.sol, src/libraries/StreamTypes.sol
- Implement:
  - Full lifecycle state machine: PENDING -> ACTIVE -> ENDED.
  - Constructor guards: salary > 0, duration > 0, worker valid, worker != employer.
  - Employer flows: startWork, clawback.
  - Worker flows: withdraw, cancelIfNotStarted.
  - View/getter flows: earned, withdrawable, next claim time, period duration.
  - Internal helpers: earned math and period mapping.
- Done when:
  - Contract behavior matches the provided SalaryStreamer specification.
  - Events and revert messages are consistent and clear.

## Task 2 - Shared Types and Interface Stability
- Owner: Member 2
- Main files: src/libraries/StreamTypes.sol, src/interfaces/ITrustlessSalaryStreamer.sol
- Supporting files: src/TrustlessSalaryStreamer.sol
- Implement:
  - Canonical enums in StreamTypes (PaymentPeriod, Status).
  - Shared structs needed by factory/indexing responses.
  - Full interface surface for streamer events, state getters, and external methods.
  - Signature alignment between interface and implementation.
- Done when:
  - No duplicated enum definitions across files.
  - Interface compiles cleanly and exactly reflects implementation.

## Task 3 - Factory Creation and Registry Layer
- Owner: Member 3
- Main file: src/StreamFactory.sol
- Supporting files: src/TrustlessSalaryStreamer.sol, src/libraries/StreamTypes.sol
- Implement:
  - Payable createStream flow that deploys a new stream contract.
  - Registry structures:
    - all streams list
    - streams by employer
    - streams by worker
  - Factory events with indexing-friendly fields.
  - Read APIs for frontend queries (all streams, per employer, per worker, counts).
- Done when:
  - New stream deployments are discoverable by all required query paths.
  - Event payloads are sufficient for frontend and indexers.

## Task 4 - Security and Edge-Case Hardening
- Owner: Member 4
- Main files: src/TrustlessSalaryStreamer.sol, src/StreamFactory.sol
- Supporting files: src/interfaces/ITrustlessSalaryStreamer.sol
- Implement:
  - Confirm CEI ordering on all value transfers.
  - Verify role restrictions and state-gating on every external function.
  - Validate edge-case behavior from README/spec:
    - no early withdrawal
    - no double claim in same period
    - clawback returns only unearned funds
    - cancel window logic after 7 days
  - Add/adjust explicit revert reasons where clarity is missing.
- Done when:
  - No high-risk logic path remains without clear guard conditions.
  - Security review checklist is completed and attached to PR.

## Task 5 - Test Suite and Coverage
- Owner: Member 5
- Main files: test/TrustlessSalaryStreamer.t.sol, test/StreamFactory.t.sol
- Supporting files: src/TrustlessSalaryStreamer.sol, src/StreamFactory.sol
- Implement:
  - Constructor and validation tests.
  - Lifecycle tests: pending -> active -> ended.
  - Period gating tests for weekly, biweekly, monthly.
  - Clawback and cancellation tests.
  - Registry and event correctness tests for factory.
  - Fuzz tests for earned math monotonicity and salary cap.
- Done when:
  - All tests pass locally.
  - Core paths and critical edge cases are covered.

## Task 6 - Deployment, Config, and Docs
- Owner: Member 6
- Main files: script/DeployTrustlessSalaryStreamer.s.sol, README.md, foundry.toml
- Supporting files: ../contracts/.env.example, ../frontend/.env.example
- Implement:
  - Deployment script that reads env config and deploys factory/stream setup.
  - Deployment output logs required by frontend wiring.
  - Documentation updates for setup, test, deploy, and troubleshooting.
  - Config consistency between local and CI behavior.
- Done when:
  - A new contributor can clone, configure, test, and deploy without extra help.
  - Frontend receives deployment values directly from script output.

## Assignment Rule
- One member = one task.
- No member should own more than one primary task until all six tasks are assigned.
- Cross-review is required:
  - Task 1 reviewed by Member 4.
  - Task 2 reviewed by Member 1.
  - Task 3 reviewed by Member 2.
  - Task 4 reviewed by Member 3.
  - Task 5 reviewed by Member 4.
  - Task 6 reviewed by Member 2.
