-- ============================================================
-- RPA Audit Log Schema
-- Project : Invoice Processing Automation (SDD-RPA-001)
-- Platform : UiPath REFramework
-- Author   : Blessing Nnabugwu — RPA Developer
-- Date     : April 2026
-- ============================================================
-- Purpose:
--   Creates the audit and exception log tables used by the
--   Invoice Processing bot to record every transaction
--   processed — whether successful, failed, or excepted.
--
--   These tables are written to by WriteAuditLog.xaml and
--   SendExceptionAlert.xaml in the UiPath project.
-- ============================================================

USE InvoiceProcessingDB;
GO

-- ============================================================
-- TABLE: dbo.RPA_AuditLog
-- Written on EVERY queue item — success, failure, or exception
-- No UPDATE or DELETE permissions granted to bot service account
-- ============================================================
IF OBJECT_ID('dbo.RPA_AuditLog', 'U') IS NOT NULL
    DROP TABLE dbo.RPA_AuditLog;
GO

CREATE TABLE dbo.RPA_AuditLog (
    AuditID               INT IDENTITY(1,1)    NOT NULL,  -- Auto-incrementing primary key
    RunID                 UNIQUEIDENTIFIER      NOT NULL,  -- Groups all items from one bot run
    QueueItemID           NVARCHAR(100)         NOT NULL,  -- Orchestrator queue item reference
    TransactionStatus     NVARCHAR(20)          NOT NULL,  -- Successful | Failed | SystemException
    InvoiceNumber         NVARCHAR(50)          NULL,      -- Extracted invoice number (if available)
    VendorName            NVARCHAR(200)         NULL,      -- Extracted vendor name
    InvoiceDate           DATE                  NULL,      -- Extracted invoice date
    PONumber              NVARCHAR(50)          NULL,      -- Extracted PO number
    InvoiceTotal          DECIMAL(18,2)         NULL,      -- Extracted invoice total amount
    POTotal               DECIMAL(18,2)         NULL,      -- PO approved amount from database
    ValidationResult      NVARCHAR(50)          NULL,      -- Passed | AmountMismatch | PONotFound | etc.
    ExceptionType         NVARCHAR(50)          NULL,      -- BusinessRule | Application | NULL if success
    ExceptionMessage      NVARCHAR(MAX)         NULL,      -- Full exception message if applicable
    FilePath              NVARCHAR(500)         NULL,      -- Source PDF file path
    ProcessingTimeMs      INT                   NULL,      -- Time taken to process this item (ms)
    BotMachineName        NVARCHAR(100)         NOT NULL,  -- Machine the bot ran on
    BotUserName           NVARCHAR(100)         NOT NULL,  -- Windows user the bot ran as
    CreatedAt             DATETIME2             NOT NULL   -- Timestamp — always UTC
        CONSTRAINT DF_RPA_AuditLog_CreatedAt DEFAULT (GETUTCDATE()),

    CONSTRAINT PK_RPA_AuditLog PRIMARY KEY CLUSTERED (AuditID),
    CONSTRAINT CK_RPA_AuditLog_Status CHECK (
        TransactionStatus IN ('Successful', 'Failed', 'SystemException')
    )
);
GO

-- Index for fast run-level queries (e.g. "show me all items from today's run")
CREATE NONCLUSTERED INDEX IX_RPA_AuditLog_RunID
    ON dbo.RPA_AuditLog (RunID, CreatedAt DESC);
GO

-- Index for invoice-level lookups (e.g. "did we process invoice INV-2024-0891?")
CREATE NONCLUSTERED INDEX IX_RPA_AuditLog_InvoiceNumber
    ON dbo.RPA_AuditLog (InvoiceNumber)
    WHERE InvoiceNumber IS NOT NULL;
GO


-- ============================================================
-- TABLE: dbo.RPA_ExceptionLog
-- Written only on FAILED transactions — full detail for investigation
-- ============================================================
IF OBJECT_ID('dbo.RPA_ExceptionLog', 'U') IS NOT NULL
    DROP TABLE dbo.RPA_ExceptionLog;
GO

CREATE TABLE dbo.RPA_ExceptionLog (
    ExceptionID           INT IDENTITY(1,1)    NOT NULL,
    AuditID               INT                   NOT NULL,  -- FK to dbo.RPA_AuditLog
    RunID                 UNIQUEIDENTIFIER      NOT NULL,
    QueueItemID           NVARCHAR(100)         NOT NULL,
    ExceptionType         NVARCHAR(50)          NOT NULL,  -- BusinessRule | Application
    ExceptionCategory     NVARCHAR(100)         NOT NULL,  -- MissingPONumber | AmountMismatch | etc.
    ExceptionMessage      NVARCHAR(MAX)         NOT NULL,  -- Full error message
    StackTrace            NVARCHAR(MAX)         NULL,      -- Stack trace for app exceptions
    RetryAttempt          INT                   NOT NULL   -- Which attempt this was (1, 2, 3...)
        CONSTRAINT DF_RPA_ExceptionLog_RetryAttempt DEFAULT (1),
    ScreenshotPath        NVARCHAR(500)         NULL,      -- Path to screenshot captured on exception
    AlertEmailSent        BIT                   NOT NULL   -- Was supervisor email sent?
        CONSTRAINT DF_RPA_ExceptionLog_AlertEmailSent DEFAULT (0),
    AlertEmailSentAt      DATETIME2             NULL,      -- When the alert email was sent
    ResolvedBy            NVARCHAR(100)         NULL,      -- Who resolved this (filled manually)
    ResolvedAt            DATETIME2             NULL,      -- When it was resolved (filled manually)
    ResolutionNotes       NVARCHAR(MAX)         NULL,      -- What the resolution was
    CreatedAt             DATETIME2             NOT NULL
        CONSTRAINT DF_RPA_ExceptionLog_CreatedAt DEFAULT (GETUTCDATE()),

    CONSTRAINT PK_RPA_ExceptionLog PRIMARY KEY CLUSTERED (ExceptionID),
    CONSTRAINT FK_RPA_ExceptionLog_AuditLog
        FOREIGN KEY (AuditID) REFERENCES dbo.RPA_AuditLog (AuditID),
    CONSTRAINT CK_RPA_ExceptionLog_Type CHECK (
        ExceptionType IN ('BusinessRule', 'Application')
    )
);
GO

CREATE NONCLUSTERED INDEX IX_RPA_ExceptionLog_RunID
    ON dbo.RPA_ExceptionLog (RunID, CreatedAt DESC);
GO

CREATE NONCLUSTERED INDEX IX_RPA_ExceptionLog_Unresolved
    ON dbo.RPA_ExceptionLog (ResolvedAt)
    WHERE ResolvedAt IS NULL;
GO


-- ============================================================
-- TABLE: dbo.RPA_RunSummary
-- One record per bot run — high-level stats for Orchestrator dashboard
-- ============================================================
IF OBJECT_ID('dbo.RPA_RunSummary', 'U') IS NOT NULL
    DROP TABLE dbo.RPA_RunSummary;
GO

CREATE TABLE dbo.RPA_RunSummary (
    RunSummaryID          INT IDENTITY(1,1)    NOT NULL,
    RunID                 UNIQUEIDENTIFIER      NOT NULL,  -- Must match RunID in AuditLog
    ProcessName           NVARCHAR(100)         NOT NULL,  -- e.g. 'InvoiceProcessingBot'
    BotMachineName        NVARCHAR(100)         NOT NULL,
    RunStartedAt          DATETIME2             NOT NULL,
    RunCompletedAt        DATETIME2             NULL,
    TotalItemsProcessed   INT                   NOT NULL   CONSTRAINT DF_RunSummary_Total    DEFAULT (0),
    TotalSuccessful       INT                   NOT NULL   CONSTRAINT DF_RunSummary_Success  DEFAULT (0),
    TotalFailed           INT                   NOT NULL   CONSTRAINT DF_RunSummary_Failed   DEFAULT (0),
    TotalExceptions       INT                   NOT NULL   CONSTRAINT DF_RunSummary_Except   DEFAULT (0),
    SuccessRatePct        AS (
        CASE WHEN TotalItemsProcessed = 0 THEN NULL
             ELSE CAST(TotalSuccessful * 100.0 / TotalItemsProcessed AS DECIMAL(5,2))
        END
    ),                                                     -- Computed column — no manual update needed
    SummaryEmailSent      BIT                   NOT NULL   CONSTRAINT DF_RunSummary_Email    DEFAULT (0),
    CreatedAt             DATETIME2             NOT NULL   CONSTRAINT DF_RunSummary_Created  DEFAULT (GETUTCDATE()),

    CONSTRAINT PK_RPA_RunSummary PRIMARY KEY CLUSTERED (RunSummaryID),
    CONSTRAINT UQ_RPA_RunSummary_RunID UNIQUE (RunID)
);
GO


-- ============================================================
-- GRANT minimum permissions to bot service account
-- Principle of least privilege — bot can only do what it needs
-- ============================================================

-- Replace 'DOMAIN\rpa-invoice-svc' with your actual service account
GRANT SELECT, INSERT          ON dbo.RPA_AuditLog     TO [DOMAIN\rpa-invoice-svc];
GRANT SELECT, INSERT, UPDATE  ON dbo.RPA_ExceptionLog TO [DOMAIN\rpa-invoice-svc];
GRANT SELECT, INSERT, UPDATE  ON dbo.RPA_RunSummary   TO [DOMAIN\rpa-invoice-svc];
-- Note: No DELETE or DROP permissions granted to service account
GO


-- ============================================================
-- SAMPLE QUERY: Run-level dashboard
-- Use this to monitor bot performance across runs
-- ============================================================
/*
SELECT
    rs.RunID,
    rs.RunStartedAt,
    rs.RunCompletedAt,
    rs.TotalItemsProcessed,
    rs.TotalSuccessful,
    rs.TotalFailed,
    rs.SuccessRatePct,
    DATEDIFF(SECOND, rs.RunStartedAt, rs.RunCompletedAt) AS RunDurationSeconds
FROM dbo.RPA_RunSummary rs
ORDER BY rs.RunStartedAt DESC;
*/

-- ============================================================
-- SAMPLE QUERY: Unresolved exceptions — for AP supervisor review
-- ============================================================
/*
SELECT
    el.ExceptionID,
    el.ExceptionCategory,
    el.ExceptionMessage,
    al.InvoiceNumber,
    al.VendorName,
    al.FilePath,
    el.CreatedAt
FROM dbo.RPA_ExceptionLog el
INNER JOIN dbo.RPA_AuditLog al ON el.AuditID = al.AuditID
WHERE el.ResolvedAt IS NULL
ORDER BY el.CreatedAt DESC;
*/
