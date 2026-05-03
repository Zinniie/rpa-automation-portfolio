-- ============================================================
-- NQR Reconciliation Database Schema
-- Project : NQR Reconciliation Automation (SDD-BN-005)
-- Platform : Blue Prism 7.1.0
-- Author   : Blessing Nnabugwu - RPA Developer
-- Date     : October 2024
-- ============================================================
-- Purpose:
--   Creates the staging, result, and configuration tables
--   used by the NQR Reconciliation bot, and defines the
--   stored procedure spNQRRecon which orchestrates the full
--   reconciliation matching logic.
--
-- Database: BNRPA
-- ============================================================

USE BNRPA;
GO

-- ============================================================
-- TABLE: dbo.NQRTransactionReport
-- Settlement report staging table.
-- Truncated and reloaded at the start of each reconciliation run.
-- Bot reads NQR settlement files from shared folder and
-- bulk-inserts entries here before calling spNQRRecon.
-- ============================================================
IF OBJECT_ID('dbo.NQRTransactionReport','U') IS NOT NULL
    DROP TABLE dbo.NQRTransactionReport;
GO

CREATE TABLE dbo.NQRTransactionReport (
    NIP_SESSION_ID       NVARCHAR(1000)   NULL,
    RESPONSE             NVARCHAR(100)    NULL,
    AMOUNT               NVARCHAR(1000)   NULL,
    ACTUAL_AMOUNT        NVARCHAR(1000)   NULL,
    TRANSACTION_TIME     NVARCHAR(1000)   NULL,
    PAYERS_ACCOUNT_NUMBER NVARCHAR(1000)  NULL,
    PAYERS_ACCOUNT_NAME  NVARCHAR(1000)   NULL,
    PAYING_BANK          NVARCHAR(1000)   NULL,
    MERCHANT_NAME        NVARCHAR(1000)   NULL,
    MERCHANT_ACCOUNT_NO  NVARCHAR(1000)   NULL,
    RECEIVING_BANK       NVARCHAR(1000)   NULL,
    NARRATION            NVARCHAR(1000)   NULL,
    PAYMENT_REFERENCE    NVARCHAR(1000)   NULL,
    FILE_SOURCE          NVARCHAR(50)     NULL,
    LoadedAt             DATETIME2        NOT NULL
        CONSTRAINT DF_NQRTxnReport_Loaded DEFAULT (GETUTCDATE()),
    ReconDate            DATE             NULL
);
GO

CREATE NONCLUSTERED INDEX IX_NQRTransactionReport_SessionID
    ON dbo.NQRTransactionReport (NIP_SESSION_ID);
GO

CREATE NONCLUSTERED INDEX IX_NQRTransactionReport_PaymentRef
    ON dbo.NQRTransactionReport (PAYMENT_REFERENCE);
GO


-- ============================================================
-- TABLE: dbo.NQRRECONGL
-- General Ledger staging table for transit account entries.
-- Truncated and reloaded each run from the GL query.
-- ============================================================
IF OBJECT_ID('dbo.NQRRECONGL','U') IS NOT NULL
    DROP TABLE dbo.NQRRECONGL;
GO

CREATE TABLE dbo.NQRRECONGL (
    UNIQUE_FIELD         NVARCHAR(100)    NULL,
    TRAN_DATE            NVARCHAR(1000)   NULL,
    TRAN_ID              NVARCHAR(1000)   NULL,
    PART_TRAN_TYPE       NVARCHAR(5)      NULL,    -- 'C' = Credit, 'D' = Debit
    FORACID              NVARCHAR(1000)   NULL,    -- GL account number
    VALUE_DATE           NVARCHAR(1000)   NULL,
    PSTD_DATE            NVARCHAR(1000)   NULL,
    TRAN_AMT             NVARCHAR(1000)   NULL,
    TRAN_PARTICULAR      NVARCHAR(1000)   NULL,
    ENTRY_USER_ID        NVARCHAR(1000)   NULL,
    PSTD_USER_ID         NVARCHAR(1000)   NULL,
    VFD_USER_ID          NVARCHAR(1000)   NULL,
    TRAN_RMKS            NVARCHAR(1000)   NULL,    -- Key matching field
    CONTRA_ACCT          NVARCHAR(100)    NULL,
    LoadedAt             DATETIME2        NOT NULL
        CONSTRAINT DF_NQRRECONGL_Loaded DEFAULT (GETUTCDATE()),
    ReconDate            DATE             NULL
);
GO

CREATE NONCLUSTERED INDEX IX_NQRRECONGL_TranRmks
    ON dbo.NQRRECONGL (TRAN_RMKS, PART_TRAN_TYPE);
GO

CREATE NONCLUSTERED INDEX IX_NQRRECONGL_TranType
    ON dbo.NQRRECONGL (PART_TRAN_TYPE, FORACID);
GO


-- ============================================================
-- TABLE: dbo.NQRReconMatched
-- Result table for successfully matched transactions.
-- Truncated by spNQRRecon at start of each execution.
-- ============================================================
IF OBJECT_ID('dbo.NQRReconMatched','U') IS NOT NULL
    DROP TABLE dbo.NQRReconMatched;
GO

CREATE TABLE dbo.NQRReconMatched (
    NIP_SESSION_ID       NVARCHAR(1000)   NULL,
    RESPONSE             NVARCHAR(100)    NULL,
    AMOUNT               NVARCHAR(1000)   NULL,
    ACTUAL_AMOUNT        NVARCHAR(1000)   NULL,
    TRANSACTION_TIME     NVARCHAR(1000)   NULL,
    PAYERS_ACCOUNT_NUMBER NVARCHAR(1000)  NULL,
    PAYERS_ACCOUNT_NAME  NVARCHAR(1000)   NULL,
    PAYING_BANK          NVARCHAR(1000)   NULL,
    MERCHANT_NAME        NVARCHAR(1000)   NULL,
    MERCHANT_ACCOUNT_NO  NVARCHAR(1000)   NULL,
    RECEIVING_BANK       NVARCHAR(1000)   NULL,
    NARRATION            NVARCHAR(1000)   NULL,
    PAYMENT_REFERENCE    NVARCHAR(1000)   NULL,
    FILE_SOURCE          NVARCHAR(50)     NULL,
    -- GL match fields
    FORACID              NVARCHAR(1000)   NULL,
    TRAN_DATE            NVARCHAR(1000)   NULL,
    TRAN_AMT             NVARCHAR(1000)   NULL,
    TRAN_ID              NVARCHAR(1000)   NULL,
    TRAN_PARTICULAR      NVARCHAR(1000)   NULL,
    TRAN_RMKS            NVARCHAR(1000)   NULL,
    VALUE_DATE           NVARCHAR(1000)   NULL,
    PSTD_DATE            NVARCHAR(1000)   NULL,
    ENTRY_USER_ID        NVARCHAR(1000)   NULL,
    PSTD_USER_ID         NVARCHAR(1000)   NULL,
    VFD_USER_ID          NVARCHAR(1000)   NULL,
    AmountDifference     NVARCHAR(1000)   NULL,    -- Variance between settlement and GL amount
    Status               NVARCHAR(50)     NULL     -- 'Matched'
);
GO


-- ============================================================
-- TABLE: dbo.NQRRECONGLException
-- Result table for unmatched GL entries.
-- Populated by spNQRRecon after matching is complete.
-- Entries classified as 'Cr Exception' or 'Dr Exception'.
-- ============================================================
IF OBJECT_ID('dbo.NQRRECONGLException','U') IS NOT NULL
    DROP TABLE dbo.NQRRECONGLException;
GO

CREATE TABLE dbo.NQRRECONGLException (
    UNIQUE_FIELD         NVARCHAR(100)    NULL,
    TRAN_DATE            NVARCHAR(1000)   NULL,
    TRAN_ID              NVARCHAR(1000)   NULL,
    PART_TRAN_TYPE       NVARCHAR(5)      NULL,
    FORACID              NVARCHAR(1000)   NULL,
    VALUE_DATE           NVARCHAR(1000)   NULL,
    PSTD_DATE            NVARCHAR(1000)   NULL,
    TRAN_AMT             NVARCHAR(1000)   NULL,
    TRAN_PARTICULAR      NVARCHAR(1000)   NULL,
    ENTRY_USER_ID        NVARCHAR(1000)   NULL,
    PSTD_USER_ID         NVARCHAR(1000)   NULL,
    VFD_USER_ID          NVARCHAR(1000)   NULL,
    TRAN_RMKS            NVARCHAR(1000)   NULL,
    CONTRA_ACCT          NVARCHAR(100)    NULL,
    ExceptionType        NVARCHAR(50)     NULL     -- 'Cr Exception' | 'Dr Exception'
);
GO


-- ============================================================
-- TABLE: dbo.NQRRECONAutoReversed
-- Result table for auto-reversed GL entry pairs.
-- Populated by spNQRRecon before primary matching begins.
-- ============================================================
IF OBJECT_ID('dbo.NQRRECONAutoReversed','U') IS NOT NULL
    DROP TABLE dbo.NQRRECONAutoReversed;
GO

CREATE TABLE dbo.NQRRECONAutoReversed (
    FORACID              NVARCHAR(1000)   NULL,
    TRAN_DATE            NVARCHAR(1000)   NULL,
    TRAN_AMT             NVARCHAR(1000)   NULL,
    TRAN_ID              NVARCHAR(1000)   NULL,
    TRAN_PARTICULAR      NVARCHAR(1000)   NULL,
    TRAN_RMKS            NVARCHAR(1000)   NULL,
    VALUE_DATE           NVARCHAR(1000)   NULL,
    PSTD_DATE            NVARCHAR(1000)   NULL,
    ENTRY_USER_ID        NVARCHAR(1000)   NULL,
    PSTD_USER_ID         NVARCHAR(1000)   NULL,
    VFD_USER_ID          NVARCHAR(1000)   NULL,
    CONTRA_ACCT          NVARCHAR(100)    NULL,
    Status               NVARCHAR(50)     NULL     -- 'Auto Reversed Credit' | 'Auto Reversed Debit'
);
GO


-- ============================================================
-- GRANT minimum permissions to bot service account
-- Replace 'DOMAIN\rpa-nqr-svc' with actual service account
-- ============================================================
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.NQRTransactionReport   TO [DOMAIN\rpa-nqr-svc];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.NQRRECONGL              TO [DOMAIN\rpa-nqr-svc];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.NQRReconMatched         TO [DOMAIN\rpa-nqr-svc];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.NQRRECONGLException     TO [DOMAIN\rpa-nqr-svc];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.NQRRECONAutoReversed    TO [DOMAIN\rpa-nqr-svc];
GO
