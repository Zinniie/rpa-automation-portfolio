# 📄 RPA Solution Design Documents
### Technical Documentation · Process Design · UiPath · Blue Prism · Enterprise Standards

![Type](https://img.shields.io/badge/Type-Technical%20Documentation-1F3864?style=flat-square)
![Standard](https://img.shields.io/badge/Standard-Enterprise%20SDD%20Format-1D9E75?style=flat-square)
![Tools](https://img.shields.io/badge/Tools-UiPath%20%7C%20Blue%20Prism-E05A19?style=flat-square)

---

## Overview

This repository contains **Solution Design Documents (SDDs)** written for the RPA automation projects in this portfolio. Each SDD is written to enterprise standards — the same format used in production RPA programmes at regulated financial institutions.

Good documentation is what separates a bot that runs from a bot that can be maintained, audited, and handed over. Every automation in this portfolio was designed on paper before a line of code was written.

---

## Documents

| Document | Bot | Platform | Status |
|---|---|---|---|
| [SDD-RPA-001-Invoice-Processing.pdf](https://github.com/Zinniie/rpa-automation-portfolio/blob/main/01-invoice-processing/docs/SDD-RPA-001-Invoice-Processing.pdf) | Invoice Processing Automation | UiPath | ✅ Complete |
| `SDD-RPA-002-Bank-Reconciliation.docx` | Bank Reconciliation Bot | Blue Prism | 🔄 In Progress |
| `SDD-RPA-003-REFramework-Processor.docx` | REFramework Transaction Processor | UiPath | 🔄 Planned |

---

## What is a Solution Design Document?

An SDD is the primary technical document for an RPA automation. Written before development begins, it aligns developers, business analysts, QA teams, and auditors on exactly what the bot will do, how it will handle every scenario, and how success will be measured.

### A strong SDD covers:

```
┌─────────────────────────────────────────────────────────┐
│                  SDD Structure                          │
├─────────────────────────────────────────────────────────┤
│  1. Executive Summary        Business case + KPIs       │
│  2. Process Overview         AS-IS pain points          │
│                              TO-BE automated flow       │
│  3. Scope                    In scope / Out of scope    │
│  4. Architecture             Framework + components     │
│  5. Data Mapping             Fields, sources, rules     │
│  6. Exception Handling       Business + App exceptions  │
│  7. Security & Compliance    Credentials, audit, access │
│  8. UAT Test Cases           10+ scenarios + sign-off   │
│  9. Deployment Plan          Checklist + go-live phases │
│  10. Monitoring              KPIs + alert thresholds    │
└─────────────────────────────────────────────────────────┘
```

---

## SDD-RPA-001 — Invoice Processing Automation

The most complete document in this collection. Covers the full lifecycle of an Accounts Payable invoice processing bot built on UiPath REFramework.

### Highlights

**AS-IS vs TO-BE**
| Metric | Before | After |
|---|---|---|
| Time per invoice | 4–6 minutes | < 2 seconds |
| Error rate | ~3% | Near-zero |
| Audit coverage | Partial | 100% |
| Peak capacity | Limited by headcount | Unlimited |

**Exception Design — 12 exception types documented**

Every failure mode is anticipated before the bot is built:
- 7 Business Exception types with trigger conditions and escalation paths
- 5 Application Exception types with retry logic and abort thresholds
- Confidence-based routing for low-quality document scans

**UAT Test Cases — 10 scenarios**

| Test | Scenario |
|---|---|
| TC-01 | Happy path — clean invoice, full match |
| TC-02 | Missing PO Number |
| TC-03 | PO not in database |
| TC-04 | Amount mismatch |
| TC-05 | Duplicate invoice detection |
| TC-06 | Low extraction confidence — human review routing |
| TC-07 | SQL connection failure — retry behaviour |
| TC-08 | Empty queue — clean shutdown |
| TC-09 | Bulk run — 20 mixed items |
| TC-10 | Audit log completeness verification |

---

## Why Documentation Matters in RPA

Most RPA bots fail not because of bad code, but because of:

- **No handover documentation** — the developer who built it leaves, and nobody can support it
- **No exception design** — the bot handles the happy path but crashes on anything unexpected
- **No audit trail** — a bot processes thousands of financial transactions with no record
- **No UAT** — bugs that would have been caught in testing reach production

Every document in this repo addresses all four of these directly.

---

## Documentation Standards Referenced

- **UiPath RPA Documentation Framework** — SDD structure and content guidelines
- **Blue Prism Process Definition Document** — Exception handling and VBO documentation standards
- **ITIL 4** — Change management and deployment documentation practices
- **ISO/IEC 20000** — IT service management documentation requirements

---

## Reusing These Templates

The SDD structure in this repository can be adapted as a template for any new RPA automation. The key sections to customise are:

1. **Section 2** — Replace AS-IS steps and pain points with your actual process
2. **Section 5** — Update data mapping table with your fields and SQL schema
3. **Section 6** — Define the specific business exceptions for your process rules
4. **Section 8** — Write UAT test cases against your specific requirements

Everything else (architecture patterns, security standards, monitoring approach) largely reuses the same framework.

---

## Author

**Blessing Nnabugwu** — RPA Developer  
[LinkedIn](https://linkedin.com/in/blessingnnabugwu) · [Portfolio](https://zinniie.github.io) · [GitHub](https://github.com/zinniie)
