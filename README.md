# Blessing Nnabugwu — RPA Automation Portfolio

> Blue Prism · UiPath · SQL Server · Control Room · Orchestrator · REFramework · VBO Components

![Platform](https://img.shields.io/badge/Blue%20Prism-7.1.0%20%7C%20Developer-00008B?style=flat-square)
![Platform](https://img.shields.io/badge/UiPath-Studio%20%7C%20Orchestrator-E05A19?style=flat-square)
![SQL](https://img.shields.io/badge/SQL-Server%20%7C%20Stored%20Procedures-CC2927?style=flat-square)
![Location](https://img.shields.io/badge/Location-Toronto%2C%20ON-1F3864?style=flat-square)
![Available](https://img.shields.io/badge/Status-Open%20to%20Opportunities-1D9E75?style=flat-square)

---

## About This Portfolio

This repository contains enterprise RPA automation projects demonstrating end-to-end capability across the full automation lifecycle — from **process discovery and solution design** through **development, exception handling, deployment, production support, and monitoring**.

Projects 01–04 are real production automations rebuilt and anonymised from live banking environments. Projects 05–08 are demo projects built to enterprise standards to complement the production work.

> 📄 Every project includes a **Solution Design Document (SDD)** written to Blue Prism enterprise standards — covering architecture, VBO stage design, database schema, exception handling, failover procedures, and operational control. Because documentation is what makes automation sustainable.

---

## Track Record

| Metric | Achievement |
|---|---|
| 🤖 Bots deployed in production | 200+ |
| ⬆️ Uptime maintained | 98.7%+ |
| ⬇️ Bot failure rate reduced | 85% |
| ⚡ Operational efficiency improved | Up to 3× |
| 🏦 Financial transactions governed | Full audit coverage |

---

## Projects

### 01 · NQR Reconciliation Automation ⭐ Production
**Blue Prism · SQL Stored Procedure · Business Day API · 9-Category Output · Reconciliation Engine**

Daily reconciliation of NQR (National QR Code Payment) settlement records against General Ledger entries. The defining feature: all matching logic is encoded in a SQL stored procedure (`spNQRRecon`) — auto-reversal detection, dual-key matching, and exception classification all happen at the database layer. Blue Prism orchestrates the data flow; the database does the work.

| Metric | Result |
|---|---|
| Average run duration | ~10 minutes |
| Reconciliation categories | 9 — Matched, Exceptions, GL Exceptions, Auto Reversed, Duplicates, + 4 more |
| Weekend handling | Automatic — 5 files standard, 11 files post-weekend |
| Audit coverage | 100% — full result set stored per run |

📁 [`/08-nqr-reconciliation`](./08-nqr-reconciliation/) · 📄 [Solution Design Document](https://github.com/Zinniie/rpa-automation-portfolio/blob/main/08-nqr-reconciliation/docs/SDD-BN-005-NQR-Reconciliation.pdf) · 🗄️ [`spNQRRecon`](./08-nqr-reconciliation/sql/sp-nqr-recon.sql)

---

### 02 · Merchant Debit POS Settlement ⭐ Production
**Blue Prism · Business Day API · Settlement Portal · SQL Server · Posting Control**

Daily settlement of merchant debit POS transactions — file retrieval, transaction validation, posting, and stakeholder reporting. Two architectural highlights: a **dual file source strategy** (shared folder first, Settlement Portal fallback) makes the process resilient without manual intervention; a **configurable posting flag** (`IsPostingOn`) lets operations suspend posting independently of the rest of the process.

| Metric | Result |
|---|---|
| Average run duration | ~2 minutes |
| File source resilience | Shared folder → Portal fallback |
| Working day logic | Automatic weekend / holiday aggregation |
| Posting control | Database flag — no code change required |

📁 [`/07-merchant-debit-pos-settlement`](./07-merchant-debit-pos-settlement/) · 📄 [Solution Design Document](https://github.com/Zinniie/rpa-automation-portfolio/blob/main/07-merchant-debit-pos-settlement/docs/SDD-BN-004-Merchant-Debit-POS-Settlement.pdf)

---

### 03 · User Access Management Automation ⭐ Production
**Blue Prism · Middleware API · BN InfoShare Portal · SQL Server · Real-Time Event Processing**

Event-driven automation that processes user access management requests in near-real-time — creating, modifying, disabling, and resetting access across enterprise systems. Triggered every 5 minutes via Blue Prism scheduler. Retrieves requests from a middleware API via SQL Agent job, routes by request type (New / Disable / Modify / Password Reset / Timed Access), and captures screenshot evidence on every completed operation.

| Metric | Result |
|---|---|
| Processing time per request | ~2 minutes end to end |
| Trigger frequency | Every 5 minutes — near real-time |
| Request types supported | 5 (N / D / M / P / R) with 4 change subtypes |
| Evidence capture | Screenshot attached to every confirmation email |

📁 [`/06-user-access-management`](./06-user-access-management/) · 📄 [Solution Design Document](https://github.com/Zinniie/rpa-automation-portfolio/blob/main/06-user-access-management/docs/SDD-BN-003-User-Access-Management.pdf)

---

### 04 · Cross Currency Posting Automation ⭐ Production
**Blue Prism · Business Day API · Core Banking API · SQL Server · Multi-Session Scheduling**

Three-session daily automation managing the full Cross Currency Posting lifecycle — file retrieval, business day validation, core banking API posting, and stakeholder reporting. Uses a **master-orchestrator pattern** where the BN Operations Process routes each session (FXP1 / FXP2 / FXP3) to the settlement VBO by product code, enabling independent session processing and granular failure isolation.

| Metric | Result |
|---|---|
| Sessions automated per day | 3 (10AM · 1PM · 4PM) |
| Average session duration | ~3 minutes |
| Business day enforcement | Automatic via Business Day API |
| Audit coverage | 100% — every run logged to database |

📁 [`/05-cross-currency-posting`](./05-cross-currency-posting/) · 📄 [Solution Design Document](https://github.com/Zinniie/rpa-automation-portfolio/blob/main/05-cross-currency-posting/docs/SDD-BN-002-Cross-Currency-Posting.pdf)

---

### 05 · Invoice Processing Automation
**UiPath · Document Understanding · REFramework · SQL Server · Orchestrator**

End-to-end Accounts Payable automation — extracts structured data from PDF invoices using Document Understanding, validates against a SQL database, handles 12 exception types, and writes a full audit trail on every transaction. Built on REFramework with Orchestrator queue management.

| Metric | Result |
|---|---|
| Manual effort eliminated | ~95% |
| Processing speed | < 2 seconds per invoice |
| Volume capacity | 500+ invoices per run |
| Audit coverage | 100% |

📁 [`/01-invoice-processing`](./01-invoice-processing/) · 📄 [Solution Design Document](https://github.com/Zinniie/rpa-automation-portfolio/blob/main/01-invoice-processing/docs/SDD-RPA-001-Invoice-Processing.pdf)

---

### 06 · Bank Reconciliation Bot
**Blue Prism · SQL Stored Procedures · VBO Components · Control Room · Excel**

Nightly reconciliation automation comparing banking system transactions against Excel exports — matching records using SQL-driven logic, flagging discrepancies, generating formatted reports, and escalating unresolved items automatically.

| Metric | Result |
|---|---|
| Reconciliation time | Minutes vs. hours manually |
| Efficiency improvement | 3× faster |
| Scheduling | Nightly via Control Room — zero manual trigger |
| Audit coverage | 100% |

📁 [`/02-bank-reconciliation`](./02-bank-reconciliation/)

---

### 07 · REFramework Transaction Processor
**UiPath · Orchestrator Queues · Exception Handling · Config Management · Logging**

A clean, fully documented reference implementation of the UiPath Robotic Enterprise Framework, demonstrating best-practice exception handling, retry logic, Orchestrator queue management, and structured logging.

| Feature | Implementation |
|---|---|
| Business exceptions | No retry — log, fail, alert |
| Application exceptions | Retry up to configured max |
| Config management | Orchestrator Assets + Config.xlsx |
| Logging | Full trace in Orchestrator — zero unhandled exceptions |

📁 [`/03-reframework-processor`](./03-reframework-processor/)

---

### 08 · RPA Solution Design Documents
**Technical Documentation · SDD · Blue Prism Enterprise Standards · Process Design**

A collection of professional Solution Design Documents written to Blue Prism enterprise standards. Covers AS-IS/TO-BE process design, VBO architecture, database schema, exception strategy, failover procedures, and UAT test cases.

| Document | Bot | Status |
|---|---|---|
| SDD-BN-002 | Cross Currency Posting | ✅ Complete |
| SDD-BN-003 | User Access Management | ✅ Complete |
| SDD-BN-004 | Merchant Debit POS Settlement | ✅ Complete |
| SDD-BN-005 | NQR Reconciliation | ✅ Complete |
| SDD-RPA-001 | Invoice Processing | ✅ Complete |

📁 [`/04-sdd-documentation`](./04-sdd-documentation/)

---

## How I Work

Every automation in this portfolio follows the same end-to-end delivery approach:

```
  🔍 Discover        📐 Design          ⚙️ Build
  ───────────        ─────────          ────────
  Map AS-IS          Write SDD          Blue Prism VBO
  process            before coding      or REFramework
  Quantify           Define all         Reusable
  manual effort      exceptions         components
  Identify           Data mapping       Full exception
  candidates         + UAT cases        handling

  ✅ Test            🚀 Deploy          📊 Monitor
  ──────────         ─────────          ─────────
  Unit test all      Orchestrator       Uptime KPIs
  exception paths    or Control Room    Exception rates
  UAT with           Scheduling +       Root cause
  business team      alerting           analysis
  Sign-off before    Runbook for        Continuous
  production         support team       improvement
```

---

## Skills Demonstrated

| Category | Skills |
|---|---|
| **RPA Platforms** | Blue Prism 7.1.0, UiPath Studio, Blue Prism Control Room, UiPath Orchestrator |
| **Blue Prism** | VBO Components, Process Studio, Object Studio, Credential Manager, Scheduler, Work Queues, Exception Handling, Release Manager |
| **Architecture** | Master-Orchestrator pattern, VBO design, REFramework, Queue Management, Dispatcher/Performer pattern, Event-driven automation |
| **Exception Handling** | Business exceptions, Application exceptions, Retry logic, Recover/Resume stages, Escalation workflows |
| **Database** | SQL Server, Stored Procedures, Temp tables, Staging table patterns, Audit logging, Data validation |
| **Integration** | REST API integration, Middleware API, Business Day API, Core Banking API, SQL Agent Jobs |
| **Documentation** | Solution Design Documents (SDD), VBO stage documentation, Operational runbooks, UAT test cases, Failover procedures |
| **Scripting** | VB.NET, JavaScript |
| **Version Control** | Git / GitHub |
| **Methodology** | Agile / Scrum, UAT support, Stakeholder communication, Incident management, Root cause analysis |

---

## Repository Structure

```
rpa-automation-portfolio/
│
├── README.md                                     ← You are here
│
├── 08-nqr-reconciliation/                        ← PRODUCTION · Blue Prism
│   ├── README.md
│   ├── docs/
│   │   ├── SDD-BN-005-NQR-Reconciliation.pdf
│   │   └── diagram-nqr-recon-flow.svg
│   └── sql/
│       ├── nqr-recon-schema.sql
│       └── sp-nqr-recon.sql
│
├── 07-merchant-debit-pos-settlement/             ← PRODUCTION · Blue Prism
│   ├── README.md
│   ├── docs/
│   │   ├── SDD-BN-004-Merchant-Debit-POS-Settlement.pdf
│   │   └── diagram-mdps-flow.svg
│   └── sql/
│
├── 06-user-access-management/                    ← PRODUCTION · Blue Prism
│   ├── README.md
│   └── docs/
│       ├── SDD-BN-003-User-Access-Management.pdf
│       └── diagram-uam-flow.svg
│
├── 05-cross-currency-posting/                    ← PRODUCTION · Blue Prism
│   ├── README.md
│   ├── docs/
│   │   ├── SDD-BN-002-Cross-Currency-Posting.pdf
│   │   └── diagram-cross-currency-flow.svg
│   └── sql/
│       └── bn-cross-currency-schema.sql
│
├── 01-invoice-processing/                        ← DEMO · UiPath
│   ├── README.md
│   ├── docs/
│   │   └── SDD-RPA-001-Invoice-Processing.pdf
│   └── sql/
│       └── audit-log-schema.sql
│
├── 02-bank-reconciliation/                       ← DEMO · Blue Prism
│   ├── README.md
│   └── sql/
│       └── reconciliation-schema.sql
│
├── 03-reframework-processor/                     ← DEMO · UiPath
│   ├── README.md
│   └── docs/
│       └── reframework-flow.md
│
└── 04-sdd-documentation/                         ← Documentation
    ├── README.md
    └── docs/
        └── SDD-RPA-001-Invoice-Processing.pdf
```

---

## Contact

**Blessing Nnabugwu** — RPA Developer

[![LinkedIn](https://img.shields.io/badge/LinkedIn-blessingnnabugwu-0077B5?style=flat-square&logo=linkedin)](https://linkedin.com/in/blessingnnabugwu)
[![Portfolio](https://img.shields.io/badge/Portfolio-zinniie.github.io-1D9E75?style=flat-square)](https://zinniie.github.io/rpa-portfolio/)
[![Email](https://img.shields.io/badge/Email-blessingezinnennabugwu%40gmail.com-1F3864?style=flat-square)](mailto:blessingezinnennabugwu@gmail.com)

---

*Built with care — because good automation starts with good design.*
