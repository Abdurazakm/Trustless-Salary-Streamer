# RSS - Rustfarian Salary Streamer

<p align="center">
  <strong>A Trustless Salary Payment Protocol Built on Ethereum</strong>
</p>

---

<p align="center">
  <em>Google Developer Group Web3 Capstone Project</em>
</p>

---

## The Problem: Trust Shouldn't Be a Luxury

Every day, millions of workers around the world face the same frustrating reality: they pour their time and skills into jobs, but payment arrives late, unpredictably, or sometimes not at all. According to recent labor statistics, **over 60% of workers globally** have experienced delayed wages at some point in their careers. In the gig economy, this number climbs even higher.

Traditional payroll systems are built on trust: trust that employers will pay on time, trust that middlemen like payroll services and banks will process transactions correctly, and trust that disputes will be resolved fairly. But trust is precisely what's broken. When a company delays payroll, workers bear the cost. When a contractor goes unpaid, there's often little recourse. And for businesses operating across borders, the complexity of international payments adds layers of fees, delays, and friction.

**What if trust wasn't required?**

What if salary payments could be automated, transparent, and unbreakable? This would mean they're governed not by human discretion, but by code that's impossible to bend.

This is the question that inspired **RSS (Rustfarian Salary Streamer)**.

---

## Introducing RSS: Payroll Without the Middleman

RSS is a smart contract-powered salary payment protocol that creates a direct, trustless relationship between employers and workers. Built on Ethereum, it eliminates the need for payroll services, banks, and other intermediaries by encoding payment logic directly into immutable blockchain code.

Here's how it works in practice:

1. **The Employer Locks the Salary**: When starting a new engagement, the employer deploys the RSS contract and locks the total salary in ETH. This isn't a promise; it's real money, held in the contract.

2. **Time Determines Earnings**: The contract calculates exactly how much the worker has earned based on time elapsed. It's proportional and transparent: if a worker has completed 30% of their contract duration, they have earned 30% of their salary.

3. **Workers Withdraw on a Schedule**: Rather than waiting for a monthly direct deposit that may or may not arrive, workers can withdraw their earned salary at fixed intervals, such as weekly, biweekly, or monthly. The contract enforces this schedule automatically.

4. **Fairness for Everyone**: If an engagement ends early, the employer can claw back only the _unearned_ portion. Whatever the worker has already earned, even if not yet withdrawn, stays protected. No one gets shortchanged.

With RSS, **payment isn't about who you know or how good you are at sending follow-up emails. It's about mathematics and time.**

---

## Features & Functionality

### Trustless Salary Locking

When an employer creates a new SalaryStreamer contract, they deposit the entire salary upfront. This ETH is held in the smart contract, immutably locked until the worker earns it or the employer clawbacks unearned funds. There's no way to freeze wages, delay payments, or simply forget to pay. The code doesn't allow it.

### Proportional Earnings Calculation

The contract calculates earnings using a simple, transparent formula:

```
earned = (totalSalary × elapsedTime) / totalDuration
```

This means:

- After 1 week of a 4-week contract, the worker has earned 25%
- After 15 days of a 30-day contract, the worker has earned 50%
- After 6 months of a 12-month contract, the worker has earned 50%

The worker never receives less than they've earned, and the employer never pays more than what was earned. It's mathematical fairness, encoded in code.

### Flexible Payment Periods

RSS supports three payment schedules to mirror real-world payroll:

- **Weekly**: Workers can withdraw every 7 days
- **Biweekly**: Workers can withdraw every 14 days
- **Monthly**: Workers can withdraw every 30 days

This flexibility lets employers and workers agree on terms that work for both parties, without requiring any middleman to enforce the schedule.

### Clear Lifecycle States

The contract operates in three distinct states that prevent confusion and protect both parties:

1. **PENDING**: The contract exists and salary is locked, but work hasn't officially begun. Workers cannot withdraw yet, and this prevents someone from claiming salary for days before they actually started working.

2. **ACTIVE**: The employer has called `startWork()`, and time is now counting. Workers can withdraw at the end of each payment period.

3.ENDED\*\*: The full duration has passed, or the employer has clawed back unearned funds. No more withdrawals are possible.

### Employer Clawback Protection

Sometimes engagements end early. Perhaps a worker resigns, a project gets cancelled, or priorities shift. RSS handles this fairly with the `clawback()` function, which allows employers to recover only the _unearned_ portion of the salary.

**Critical distinction**: The clawback can only recover funds the worker _hasn't earned yet_. If a worker earned 60% of the contract value but only withdrew 40%, the employer gets back only the remaining 20%, not the 40% already earned. This protects workers from being penalized for not withdrawing frequently.

### Worker Escape Hatch

What if an employer deploys a contract but never actually starts the work? Without protection, a worker could be left in limbo: technically employed but unable to withdraw.

RSS solves this with `cancelIfNotStarted()`: if the employer hasn't called `startWork()` within 7 days of deployment, the worker can cancel the contract and release the locked funds back to the employer. No one gets stuck, and no one gets hurt.

### Complete Transparency

All earnings, withdrawals, and contract state are publicly visible on the blockchain. Workers can check exactly how much they've earned at any time using the `getEarned()` and `getWithdrawable()` view functions. There's no hidden math, no mysterious deductions, and no surprises.

---

## Handling Edge Cases: Built for the Real World

Smart contracts don't have the luxury of assuming everything will go perfectly. RSS includes robust safeguards for scenarios that would otherwise cause problems:

| Edge Case                                          | How RSS Handles It                                                                               |
| -------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| **Employer tries to deploy with no salary**        | The transaction reverts. A contract with zero ETH would be meaningless.                          |
| **Zero contract duration**                         | Prevented at deployment to avoid division-by-zero errors in earnings calculations.               |
| **Worker is the null address**                     | Rejected at deployment to prevent funds from being permanently locked.                           |
| **Employer tries to pay themselves as the worker** | Blocked — the contract requires two distinct parties.                                            |
| **Worker tries to withdraw before work starts**    | Blocked by the `onlyActive` modifier — the contract must be in ACTIVE state.                     |
| **Worker tries to withdraw mid-period**            | Blocked — at least one full payment period must have elapsed since the last withdrawal.          |
| **Worker tries to withdraw twice in one period**   | The `withdrawable` calculation accounts for `amountWithdrawn`, preventing double-claiming.       |
| **Employer tries to clawback after full duration** | There's nothing left to claw — unearned equals zero, the transaction reverts.                    |
| **ETH transfer fails**                             | Every transfer includes a success check and reverts on failure — no silent fund loss.            |
| **Re-entrance attack attempt**                     | The contract uses Checks-Effects-Interactions pattern, updating state before any external calls. |

These safeguards ensure that no matter what happens, the contract behaves predictably and fairly.

---

## Real-World Impact: Who Benefits?

### Freelancers & Gig Workers

For the millions of people working as independent contractors, late payments are a way of life. RSS provides assurance that once they've done the work, the money is there for them. No chasing invoices, no awkward conversations about payment terms. Just code that works.

### Remote Teams

Companies hiring across borders face currency conversion fees, bank transfer delays, and compliance headaches. RSS runs on Ethereum, a global, borderless network. Once the salary is locked, it flows automatically, regardless of geography.

### Web3 Projects & DAOs

Decentralized organizations often struggle with contributor compensation. How do you pay someone fairly when there's no HR department? RSS provides a programmable, transparent solution that DAOs can use to compensate contributors proportionally as work is completed.

### Startups & Small Businesses

For companies watching every dollar, RSS provides a way to demonstrate good faith to potential hires. Locking salary in a smart contract signals that the company is serious about compensation. The code guarantees payment, so no trust is required.

---

## Why RSS Matters

The traditional answer to "how do I know I'll get paid?" has always been: _find a reputable employer, sign a contract, hope for the best._

**RSS changes the question entirely.**

Instead of asking "Can I trust this employer?", workers can ask "Is the contract deployed and funded?" If the answer is yes, payment isn't a matter of trust — it's a matter of time.

This shift is profound. It moves the power dynamic from the employer to the worker, from human discretion to mathematical certainty, from "I hope they pay" to "The code guarantees it."

---

## Technical Details

- **Language**: Solidity (Ethereum Virtual Machine)
- **Compiler Version**: ^0.8.19
- **License**: MIT
- **Contract**: Fully immutable once deployed, with no admin keys, no pause functions, and no way to override the rules
- **Security**: Uses Checks-Effects-Interactions pattern to prevent re-entrancy attacks

---

## Getting Started

To create an RSS salary contract:

1. Determine the worker's wallet address
2. Decide on the total engagement duration (in seconds)
3. Choose a payment period (WEEKLY, BIWEEKLY, or MONTHLY)
4. Send the total salary in ETH when deploying the contract
5. Call `startWork()` when ready to begin the engagement

Workers can then call `withdraw()` at the end of each payment period to claim their earned salary.

---

## Conclusion

RSS, the Rustfarian Salary Streamer, is more than a smart contract. It's a statement that payroll doesn't have to be broken, that workers shouldn't have to choose between their dignity and their paycheck, and that trustless systems can create more trust than any traditional arrangement.

**Because everyone deserves to get paid. Every time. Without exception.**
