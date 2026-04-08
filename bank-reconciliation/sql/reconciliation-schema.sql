-- ============================================================
-- Reconciliation Schema
-- Project : Bank Reconciliation Bot (SDD-RPA-002)
-- Platform : Blue Prism — VBO_SQLOperations
-- Author   : Blessing Nnabugwu — RPA Developer
-- Date     : April 2026
-- ============================================================
-- Purpose:
--   Creates all tables required by the Bank Reconciliation
--   bot. Stores transactions from both sources, reconciliation
--   outcomes, run-level audit records, and unresolved
--   discrepancies for finance team review.
-- ============================================================

USE BankReconciliationDB;
GO

-- ============================================================
-- TABLE: dbo.BankTransactions
-- Source A — transactions pulled from the core banking system
-- ============================================================
IF OBJECT_ID('dbo.BankTransactions', 'U') IS NOT NULL
    DROP TABLE dbo.BankTransactions;
GO

CREATE TABLE dbo.BankTransactions (
    BankTransactionID     INT IDENTITY(1,1)    NOT NULL,
    TransactionRef        NVARCHAR(100)         NOT NULL,  -- Unique ref from banking system
    TransactionDate       DATE                  NOT NULL,
    ValueDate             DATE                  NULL,      -- Settlement date (may differ)
    DebitAmount           DECIMAL(18,2)         NULL,
    CreditAmount          DECIMAL(18,2)         NULL,
    NetAmount             AS (ISNULL(CreditAmount,0) - ISNULL(DebitAmount,0)),  -- Computed
    Currency              NCHAR(3)              NOT NULL   CONSTRAINT DF_BankTxn_Currency DEFAULT ('CAD'),
    Description           NVARCHAR(500)         NULL,
    AccountNumber         NVARCHAR(50)          NOT NULL,
    ImportedByBot         BIT                   NOT NULL   CONSTRAINT DF_BankTxn_Bot DEFAULT (1),
    ImportedAt            DATETIME2             NOT NULL   CONSTRAINT DF_BankTxn_Imported DEFAULT (GETUTCDATE()),
    RunID                 UNIQUEIDENTIFIER      NOT NULL,  -- Which bot run imported this

    CONSTRAINT PK_BankTransactions PRIMARY KEY CLUSTERED (BankTransactionID),
    CONSTRAINT UQ_BankTransactions_Ref UNIQUE (TransactionRef, AccountNumber)
);
GO

CREATE NONCLUSTERED INDEX IX_BankTransactions_Date
    ON dbo.BankTransactions (TransactionDate, AccountNumber);
GO


-- ============================================================
-- TABLE: dbo.ExcelTransactions
-- Source B — transactions imported from Excel export
-- ============================================================
IF OBJECT_ID('dbo.ExcelTransactions', 'U') IS NOT NULL
    DROP TABLE dbo.ExcelTransactions;
GO

CREATE TABLE dbo.ExcelTransactions (
    ExcelTransactionID    INT IDENTITY(1,1)    NOT NULL,
    TransactionRef        NVARCHAR(100)         NOT NULL,
    TransactionDate       DATE                  NOT NULL,
    Amount                DECIMAL(18,2)         NOT NULL,
    Currency              NCHAR(3)              NOT NULL   CONSTRAINT DF_ExcelTxn_Currency DEFAULT ('CAD'),
    Description           NVARCHAR(500)         NULL,
    AccountNumber         NVARCHAR(50)          NOT NULL,
    SourceFileName        NVARCHAR(500)         NULL,      -- Name of the Excel file this came from
    ImportedAt            DATETIME2             NOT NULL   CONSTRAINT DF_ExcelTxn_Imported DEFAULT (GETUTCDATE()),
    RunID                 UNIQUEIDENTIFIER      NOT NULL,

    CONSTRAINT PK_ExcelTransactions PRIMARY KEY CLUSTERED (ExcelTransactionID),
    CONSTRAINT UQ_ExcelTransactions_Ref UNIQUE (TransactionRef, AccountNumber)
);
GO

CREATE NONCLUSTERED INDEX IX_ExcelTransactions_Date
    ON dbo.ExcelTransactions (TransactionDate, AccountNumber);
GO


-- ============================================================
-- TABLE: dbo.RPA_Recon_Results
-- One record per transaction — the outcome of matching logic
-- ============================================================
IF OBJECT_ID('dbo.RPA_Recon_Results', 'U') IS NOT NULL
    DROP TABLE dbo.RPA_Recon_Results;
GO

CREATE TABLE dbo.RPA_Recon_Results (
    ReconResultID         INT IDENTITY(1,1)    NOT NULL,
    RunID                 UNIQUEIDENTIFIER      NOT NULL,
    TransactionRef        NVARCHAR(100)         NOT NULL,
    AccountNumber         NVARCHAR(50)          NOT NULL,
    TransactionDate       DATE                  NOT NULL,
    MatchStatus           NVARCHAR(30)          NOT NULL,  -- Matched | Discrepancy | UnmatchedBankOnly | UnmatchedExcelOnly
    BankAmount            DECIMAL(18,2)         NULL,      -- Amount from banking system
    ExcelAmount           DECIMAL(18,2)         NULL,      -- Amount from Excel
    AmountDelta           AS (ABS(ISNULL(BankAmount,0) - ISNULL(ExcelAmount,0))),  -- Computed variance
    DiscrepancyReason     NVARCHAR(200)         NULL,      -- AmountMismatch | DateVariance | RefFormatDiff
    RequiresInvestigation BIT                   NOT NULL   CONSTRAINT DF_Recon_Investigation DEFAULT (0),
    InvestigatedBy        NVARCHAR(100)         NULL,      -- Finance analyst who reviewed (filled manually)
    InvestigatedAt        DATETIME2             NULL,
    ResolutionNotes       NVARCHAR(MAX)         NULL,
    CreatedAt             DATETIME2             NOT NULL   CONSTRAINT DF_Recon_CreatedAt DEFAULT (GETUTCDATE()),

    CONSTRAINT PK_RPA_Recon_Results PRIMARY KEY CLUSTERED (ReconResultID),
    CONSTRAINT CK_Recon_MatchStatus CHECK (
        MatchStatus IN ('Matched', 'Discrepancy', 'UnmatchedBankOnly', 'UnmatchedExcelOnly')
    )
);
GO

CREATE NONCLUSTERED INDEX IX_Recon_Results_RunID
    ON dbo.RPA_Recon_Results (RunID, MatchStatus);
GO

-- Fast lookup for unresolved discrepancies
CREATE NONCLUSTERED INDEX IX_Recon_Results_Unresolved
    ON dbo.RPA_Recon_Results (RequiresInvestigation, InvestigatedAt)
    WHERE RequiresInvestigation = 1 AND InvestigatedAt IS NULL;
GO


-- ============================================================
-- TABLE: dbo.RPA_Recon_AuditLog
-- One record per bot run — high-level summary stats
-- ============================================================
IF OBJECT_ID('dbo.RPA_Recon_AuditLog', 'U') IS NOT NULL
    DROP TABLE dbo.RPA_Recon_AuditLog;
GO

CREATE TABLE dbo.RPA_Recon_AuditLog (
    ReconAuditID          INT IDENTITY(1,1)    NOT NULL,
    RunID                 UNIQUEIDENTIFIER      NOT NULL,
    RunDate               DATE                  NOT NULL,
    AccountNumber         NVARCHAR(50)          NOT NULL,
    ReconPeriodStart      DATE                  NOT NULL,  -- Date range reconciled
    ReconPeriodEnd        DATE                  NOT NULL,
    TotalBankRecords      INT                   NOT NULL   CONSTRAINT DF_Recon_BankRec   DEFAULT (0),
    TotalExcelRecords     INT                   NOT NULL   CONSTRAINT DF_Recon_ExcelRec  DEFAULT (0),
    TotalMatched          INT                   NOT NULL   CONSTRAINT DF_Recon_Matched   DEFAULT (0),
    TotalDiscrepancies    INT                   NOT NULL   CONSTRAINT DF_Recon_Discr     DEFAULT (0),
    TotalUnmatchedBank    INT                   NOT NULL   CONSTRAINT DF_Recon_UnmBank   DEFAULT (0),
    TotalUnmatchedExcel   INT                   NOT NULL   CONSTRAINT DF_Recon_UnmExcel  DEFAULT (0),
    MatchRatePct          AS (
        CASE WHEN (TotalBankRecords + TotalExcelRecords) = 0 THEN NULL
             ELSE CAST(TotalMatched * 100.0 /
                  NULLIF(CASE WHEN TotalBankRecords > TotalExcelRecords
                              THEN TotalBankRecords ELSE TotalExcelRecords END, 0)
                  AS DECIMAL(5,2))
        END
    ),
    ReportFilePath        NVARCHAR(500)         NULL,      -- Path to generated Excel report
    SummaryEmailSent      BIT                   NOT NULL   CONSTRAINT DF_Recon_Email     DEFAULT (0),
    EscalationEmailSent   BIT                   NOT NULL   CONSTRAINT DF_Recon_Escalate  DEFAULT (0),
    RunDurationSeconds    INT                   NULL,
    CreatedAt             DATETIME2             NOT NULL   CONSTRAINT DF_Recon_Audit_Created DEFAULT (GETUTCDATE()),

    CONSTRAINT PK_RPA_Recon_AuditLog PRIMARY KEY CLUSTERED (ReconAuditID),
    CONSTRAINT UQ_RPA_Recon_AuditLog_RunID UNIQUE (RunID)
);
GO


-- ============================================================
-- GRANT minimum permissions to bot service account
-- ============================================================

-- Replace 'DOMAIN\rpa-recon-svc' with actual service account
GRANT SELECT, INSERT          ON dbo.BankTransactions      TO [DOMAIN\rpa-recon-svc];
GRANT SELECT, INSERT          ON dbo.ExcelTransactions     TO [DOMAIN\rpa-recon-svc];
GRANT SELECT, INSERT, UPDATE  ON dbo.RPA_Recon_Results     TO [DOMAIN\rpa-recon-svc];
GRANT SELECT, INSERT, UPDATE  ON dbo.RPA_Recon_AuditLog    TO [DOMAIN\rpa-recon-svc];
GO


-- ============================================================
-- SAMPLE QUERY: Today's reconciliation summary
-- ============================================================
/*
SELECT
    ral.RunDate,
    ral.AccountNumber,
    ral.TotalBankRecords,
    ral.TotalExcelRecords,
    ral.TotalMatched,
    ral.TotalDiscrepancies,
    ral.MatchRatePct,
    ral.EscalationEmailSent
FROM dbo.RPA_Recon_AuditLog ral
WHERE ral.RunDate = CAST(GETDATE() AS DATE)
ORDER BY ral.CreatedAt DESC;
*/

-- ============================================================
-- SAMPLE QUERY: All unresolved discrepancies for finance review
-- ============================================================
/*
SELECT
    rr.TransactionRef,
    rr.AccountNumber,
    rr.TransactionDate,
    rr.BankAmount,
    rr.ExcelAmount,
    rr.AmountDelta,
    rr.DiscrepancyReason,
    rr.CreatedAt AS FlaggedAt
FROM dbo.RPA_Recon_Results rr
WHERE rr.RequiresInvestigation = 1
  AND rr.InvestigatedAt IS NULL
ORDER BY rr.AmountDelta DESC;
*/
