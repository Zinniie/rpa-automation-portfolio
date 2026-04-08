# Blessing Nnabugwu — RPA Automation Portfolio

> UiPath · Blue Prism · SQL Server · Orchestrator · REFramework · Document Understanding

![Platform](https://img.shields.io/badge/UiPath-Studio%20%7C%20Orchestrator-E05A19?style=flat-square)
![Platform](https://img.shields.io/badge/Blue%20Prism-Developer-00008B?style=flat-square)
![SQL](https://img.shields.io/badge/SQL-Server-CC2927?style=flat-square)
![Location](https://img.shields.io/badge/Location-Toronto%2C%20ON-1F3864?style=flat-square)
![Available](https://img.shields.io/badge/Status-Open%20to%20Opportunities-1D9E75?style=flat-square)

---

## About This Portfolio

This repository contains enterprise RPA automation projects demonstrating end-to-end capability across the full automation lifecycle, from **process discovery and solution design** through **development, exception handling, deployment, support and monitoring**.

Each project is built on realistic business scenarios drawn from finance, operations, and accounts payable, the same domains where RPA delivers the highest ROI in enterprise environments.

> 📄 Every project includes a **Solution Design Document (SDD)** or detailed README covering architecture, data mapping, exception design, and UAT test cases, because documentation is what makes automation sustainable.

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

### 01 · Invoice Processing Automation
**UiPath · Document Understanding · REFramework · SQL Server · Orchestrator**

End-to-end Accounts Payable automation — extracts structured data from PDF invoices using Document Understanding, validates against a SQL database, handles 12 exception types, and writes a full audit trail on every transaction.

| Metric | Result |
|---|---|
| Manual effort eliminated | ~95% |
| Processing speed | < 2 seconds per invoice |
| Volume capacity | 500+ invoices per run |
| Audit coverage | 100% |

📁 [`/01-invoice-processing`](./01-invoice-processing/) · 📄 [Solution Design Document](https://github.com/Zinniie/rpa-automation-portfolio/blob/main/01-invoice-processing/docs/SDD-RPA-001-Invoice-Processing.pdf)

---

### 02 · Bank Reconciliation Bot
**Blue Prism · SQL Stored Procedures · VBO Components · Control Room · Excel**

Nightly reconciliation automation comparing banking system transactions against Excel exports — matching records using SQL-driven logic, flagging discrepancies, generating formatted reports, and escalating unresolved items automatically.

| Metric | Result |
|---|---|
| Reconciliation time | Minutes vs. hours manually |
| Efficiency improvement | 3× faster |
| Consistency | Identical logic on every record |
| Scheduling | Nightly via Control Room — zero manual trigger |

📁 [`/02-bank-reconciliation`](./02-bank-reconciliation/)

---

### 03 · REFramework Transaction Processor
**UiPath · Orchestrator Queues · Exception Handling · Config Management · Logging**

A clean, fully documented reference implementation of the UiPath Robotic Enterprise Framework, demonstrating best-practice exception handling, retry logic, Orchestrator queue management, and structured logging. Built to serve as both a production bot and a learning reference.

| Feature | Implementation |
|---|---|
| Business exceptions | No retry — log, fail, alert |
| Application exceptions | Retry up to configured max |
| Config management | Orchestrator Assets + Config.xlsx |
| Logging | Full trace in Orchestrator — zero unhandled exceptions |

📁 [`/03-reframework-processor`](./03-reframework-processor/)

---

### 04 · RPA Solution Design Documents
**Technical Documentation · SDD · Process Design · UAT · Enterprise Standards**

A collection of professional Solution Design Documents written to enterprise RPA standards. Covers AS-IS/TO-BE process design, architecture, data mapping, exception strategy, UAT test cases, deployment plans, and post-go-live monitoring KPIs.

| Document | Bot | Status |
|---|---|---|
| SDD-RPA-001 | Invoice Processing Automation | ✅ Complete |
| SDD-RPA-002 | Bank Reconciliation Bot | 🔄 In Progress |
| SDD-RPA-003 | REFramework Processor | 🔄 Planned |

📁 [`/04-sdd-documentation`](./04-sdd-documentation/)

---

## How I Work

Every automation in this portfolio follows the same end-to-end delivery approach:

```
  🔍 Discover        📐 Design          ⚙️ Build
  ───────────        ─────────          ────────
  Map AS-IS          Write SDD          REFramework
  process            before coding      or equivalent
  Quantify           Define all         Reusable
  manual effort      exceptions         components
  Identify           Data mapping       Full exception
  candidates         + UAT cases        handling

  ✅ Test            🚀 Deploy          📊 Monitor
  ──────────         ─────────          ─────────
  Unit test all      Orchestrator       Uptime KPIs
  exception paths    or Control Room    Exception rates
  UAT with           Runbook for        Root cause
  business team      support team       analysis
  Sign-off before    Hypercare          Continuous
  production         period             improvement
```

---

## Skills Demonstrated

| Category | Skills |
|---|---|
| **RPA Platforms** | UiPath Studio, Blue Prism, UiPath Orchestrator, Blue Prism Control Room |
| **Architecture** | REFramework, VBO Components, Queue Management, Dispatcher/Performer pattern |
| **Exception Handling** | Business exceptions, Application exceptions, Retry logic, Escalation workflows |
| **Document Automation** | UiPath Document Understanding, ABBYY OCR, Confidence-based routing |
| **Database** | SQL Server, Stored Procedures, Audit logging, Data validation |
| **Scripting** | VB.NET, JavaScript, VBA |
| **Cloud & DevOps** | Azure, AWS, Git/GitHub, CI/CD |
| **Documentation** | SDD, ODI, PDI, Operational Runbooks, UAT test cases |
| **Methodology** | Agile/Scrum, UAT support, Stakeholder communication |

---

## Repository Structure

```
rpa-automation-portfolio/
│
├── README.md                               ← You are here
│
├── 01-invoice-processing/
│   ├── README.md                           ← Architecture, data mapping, exceptions
│   ├── docs/
│   │   └── SDD-RPA-001-Invoice-Processing.docx
│   └── sql/
│       └── audit-log-schema.sql            ← SQL table definitions
│
├── 02-bank-reconciliation/
│   ├── README.md                           ← VBO design, SQL logic, report structure
│   └── sql/
│       └── reconciliation-schema.sql
│
├── 03-reframework-processor/
│   ├── README.md                           ← Full REFramework guide + state machine
│   └── docs/
│       └── reframework-flow.md
│
└── 04-sdd-documentation/
    ├── README.md                           ← Why documentation matters in RPA
    └── docs/
        └── SDD-RPA-001-Invoice-Processing.docx
```

---

## Contact

**Blessing Nnabugwu** — RPA Developer  

[![LinkedIn](https://img.shields.io/badge/LinkedIn-blessingnnabugwu-0077B5?style=flat-square&logo=linkedin)](https://linkedin.com/in/blessingnnabugwu)
[![Portfolio](https://img.shields.io/badge/Portfolio-zinniie.github.io-1D9E75?style=flat-square)](https://zinniie.github.io/rpa-portfolio/)
[![Email](https://img.shields.io/badge/Email-blessingezinnennabugwu%40gmail.com-1F3864?style=flat-square)](mailto:blessingezinnennabugwu@gmail.com)

---

*Built with care — because good automation starts with good design.*
