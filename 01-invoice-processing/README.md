# 🤖 Invoice Processing Automation
### UiPath · Document Understanding · SQL Server · REFramework · Orchestrator

![Status](https://img.shields.io/badge/Status-Production%20Ready-1D9E75?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-UiPath%20Studio-E05A19?style=flat-square)
![Framework](https://img.shields.io/badge/Framework-REFramework-1F3864?style=flat-square)
![Language](https://img.shields.io/badge/SQL-Server-CC2927?style=flat-square)

---

## Overview

An end-to-end UiPath automation that eliminates manual invoice processing in Accounts Payable. The bot extracts structured data from PDF invoices using **UiPath Document Understanding**, validates each record against a **SQL Server** database, handles exceptions systematically, and writes a full audit trail on every transaction.

Built on the **UiPath REFramework** with Orchestrator queue management for enterprise-grade scalability and resilience.

---

## Business Problem

| Pain Point | Impact |
|---|---|
| Staff manually keying invoice data | 4–6 minutes per invoice |
| ~3% human error rate on data entry | Payment delays, supplier disputes |
| No real-time audit trail | Compliance risk |
| Bottlenecks during peak periods | Invoice backlogs, late payment penalties |

---

## Solution Results

| Metric | Result |
|---|---|
| Manual effort eliminated | ~95% |
| Processing speed | < 2 seconds per invoice |
| Audit coverage | 100% — every transaction logged |
| Volume capacity | 500+ invoices per scheduled run |
| Error rate on clean documents | Near-zero |

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    UiPath REFramework                    │
├───────────────┬──────────────────┬──────────────────────┤
│ Initialisation│  Get Transaction │  Process Transaction │
│               │                  │                      │
│ • Load config │ • Fetch queue    │ • Extract (Doc.Und.) │
│ • Open apps   │   item from      │ • Validate vs SQL    │
│ • Validate    │   Orchestrator   │ • Update DB          │
│   environment │                  │ • Write audit log    │
│               │                  │ • Handle exceptions  │
└───────────────┴──────────────────┴──────────────────────┘
                              │
                    ┌─────────▼──────────┐
                    │   End Process      │
                    │ • Close apps       │
                    │ • Send summary     │
                    │ • Log run stats    │
                    └────────────────────┘
```

---

## Key Components

| File | Purpose |
|---|---|
| `Main.xaml` | REFramework state machine — orchestrates full process |
| `InitAllApplications.xaml` | Opens applications, validates environment |
| `GetTransactionData.xaml` | Fetches next item from Orchestrator queue |
| `Process.xaml` | Core business logic entry point |
| `ExtractInvoiceData.xaml` | Document Understanding extraction pipeline |
| `ValidateAgainstPO.xaml` | SQL query and field-level comparison logic |
| `WriteAuditLog.xaml` | Writes audit record to SQL on every transaction |
| `SendExceptionAlert.xaml` | Emails AP supervisor on business exceptions |
| `CloseAllApplications.xaml` | Graceful shutdown of all open applications |
| `Config.xlsx` | Environment settings, thresholds, email addresses |

---

## Exception Handling

### Business Exceptions (no retry — log + alert)
| Exception | Trigger |
|---|---|
| Missing PO Number | PO field null or blank after extraction |
| PO Not Found | No matching record in `dbo.PurchaseOrders` |
| Amount Mismatch | Invoice total differs from PO by > tolerance |
| Duplicate Invoice | Invoice number already in `dbo.InvoicePayments` |
| Invalid Date | Future date or unparseable format |
| Vendor Mismatch | Vendor on invoice ≠ vendor master for that PO |
| Low Extraction Confidence | Document Understanding score < 80% |

### Application Exceptions (retry up to configured max)
| Exception | Trigger |
|---|---|
| Login Failure | Cannot authenticate within timeout |
| SQL Connection Error | Database unavailable or timeout |
| Application Timeout | UI element not found within wait time |
| File Not Found | PDF path in queue item inaccessible |

---

## Data Mapping

### Fields Extracted from PDF
| Field | Mandatory | Validation |
|---|---|---|
| Invoice Number | ✅ | Not null, unique |
| Vendor Name | ✅ | Match against vendor master |
| Invoice Date | ✅ | Valid date, not future |
| PO Number | ✅ | Exists in PO table |
| Line Item Amount | ✅ | Greater than 0 |
| Total Amount | ✅ | Equals sum of line items + tax |
| Tax Amount | ❌ | Non-negative if present |
| Line Item Description | ❌ | Informational only |

### SQL Tables
| Table | Operation | Purpose |
|---|---|---|
| `dbo.PurchaseOrders` | SELECT | Retrieve PO for validation |
| `dbo.Vendors` | SELECT | Validate vendor master |
| `dbo.InvoicePayments` | SELECT / INSERT / UPDATE | Check duplicates, insert approved record |
| `dbo.RPA_AuditLog` | INSERT | Write-once audit record per transaction |
| `dbo.RPA_ExceptionLog` | INSERT | Detailed exception records |

---

## Tech Stack

- **UiPath Studio** — Workflow development
- **UiPath Orchestrator** — Queue management, scheduling, monitoring
- **UiPath Document Understanding** — PDF data extraction
- **ABBYY OCR** — Character recognition engine
- **SQL Server** — Data validation and audit logging
- **VB.NET** — Custom expressions and data manipulation
- **SMTP** — Exception and summary email notifications

---

## Configuration

All sensitive values are stored as **Orchestrator Assets** — never hardcoded.

| Config Key | Storage | Description |
|---|---|---|
| `DB_ConnectionString` | Orchestrator Asset (Credential) | SQL Server connection |
| `MaxRetryNumber` | Config.xlsx | Max retries on app exceptions (default: 3) |
| `OrchestratorQueueName` | Config.xlsx | Target Orchestrator queue name |
| `ExtractionConfidenceThreshold` | Config.xlsx | Min confidence score (default: 80%) |
| `AmountTolerancePercent` | Config.xlsx | Allowed % variance on invoice total (default: 0.5%) |
| `AlertEmailRecipient` | Orchestrator Asset | AP supervisor email for exception alerts |

---

## Documentation

📄 Full **Solution Design Document (SDD)** available — covers AS-IS/TO-BE process design, architecture, data mapping, exception strategy, UAT test cases, and deployment plan.

> See [`/docs/SDD-RPA-001-Invoice-Processing.docx`](./docs/)

---

## Author

**Blessing Nnabugwu** — RPA Developer  
[LinkedIn](https://linkedin.com/in/blessingnnabugwu) · [Portfolio](https://zinniie.github.io) · [GitHub](https://github.com/zinniie)
