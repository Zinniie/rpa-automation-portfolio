-- ============================================================
-- Stored Procedures: Bank Reconciliation Bot
-- Project : Bank Reconciliation Bot (SDD-RPA-002)
-- Platform : Blue Prism — VBO_SQLOperations
-- Author   : Blessing Nnabugwu — RPA Developer
-- Date     : April 2026
-- ============================================================

USE BankReconciliationDB;
GO


-- ============================================================
-- PROCEDURE 1: sp_GetBankTransactions
-- Called by Blue Prism at start of run to pull Source A data
-- ============================================================
IF OBJECT_ID('dbo.sp_GetBankTransactions', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetBankTransactions;
GO

CREATE PROCEDURE dbo.sp_GetBankTransactions
    @AccountNumber    NVARCHAR(50),
    @DateFrom         DATE,
    @DateTo           DATE,
    @RunID            UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Return all bank transactions for the account and date range
    -- Bot loads this into a DataTable for in-memory matching
    SELECT
        bt.TransactionRef,
        bt.TransactionDate,
        bt.ValueDate,
        ISNULL(bt.CreditAmount, 0) - ISNULL(bt.DebitAmount, 0) AS NetAmount,
        bt.Currency,
        bt.Description,
        bt.AccountNumber
    FROM dbo.BankTransactions bt
    WHERE bt.AccountNumber = @AccountNumber
      AND bt.TransactionDate BETWEEN @DateFrom AND @DateTo
      AND bt.RunID = @RunID
    ORDER BY bt.TransactionDate ASC, bt.TransactionRef ASC;

END;
GO


-- ============================================================
-- PROCEDURE 2: sp_GetExcelTransactions
-- Called by Blue Prism at start of run to pull Source B data
-- ============================================================
IF OBJECT_ID('dbo.sp_GetExcelTransactions', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetExcelTransactions;
GO

CREATE PROCEDURE dbo.sp_GetExcelTransactions
    @AccountNumber    NVARCHAR(50),
    @DateFrom         DATE,
    @DateTo           DATE,
    @RunID            UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        et.TransactionRef,
        et.TransactionDate,
        et.Amount           AS NetAmount,
        et.Currency,
        et.Description,
        et.AccountNumber,
        et.SourceFileName
    FROM dbo.ExcelTransactions et
    WHERE et.AccountNumber = @AccountNumber
      AND et.TransactionDate BETWEEN @DateFrom AND @DateTo
      AND et.RunID = @RunID
    ORDER BY et.TransactionDate ASC, et.TransactionRef ASC;

END;
GO


-- ============================================================
-- PROCEDURE 3: sp_InsertReconciliationResult
-- Called once per transaction after matching logic runs
-- ============================================================
IF OBJECT_ID('dbo.sp_InsertReconciliationResult', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_InsertReconciliationResult;
GO

CREATE PROCEDURE dbo.sp_InsertReconciliationResult
    @RunID                UNIQUEIDENTIFIER,
    @TransactionRef       NVARCHAR(100),
    @AccountNumber        NVARCHAR(50),
    @TransactionDate      DATE,
    @MatchStatus          NVARCHAR(30),     -- Matched | Discrepancy | UnmatchedBankOnly | UnmatchedExcelOnly
    @BankAmount           DECIMAL(18,2)  = NULL,
    @ExcelAmount          DECIMAL(18,2)  = NULL,
    @DiscrepancyReason    NVARCHAR(200)  = NULL,
    @RequiresInvestigation BIT           = 0,
    @ReconResultID        INT            OUTPUT,
    @ErrorMessage         NVARCHAR(500)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @ReconResultID = NULL;
    SET @ErrorMessage  = NULL;

    -- Validate match status value
    IF @MatchStatus NOT IN ('Matched','Discrepancy','UnmatchedBankOnly','UnmatchedExcelOnly')
    BEGIN
        SET @ErrorMessage = 'Invalid MatchStatus value: ' + @MatchStatus;
        RETURN;
    END

    BEGIN TRANSACTION;

    BEGIN TRY

        INSERT INTO dbo.RPA_Recon_Results (
            RunID,
            TransactionRef,
            AccountNumber,
            TransactionDate,
            MatchStatus,
            BankAmount,
            ExcelAmount,
            DiscrepancyReason,
            RequiresInvestigation,
            CreatedAt
        )
        VALUES (
            @RunID,
            @TransactionRef,
            @AccountNumber,
            @TransactionDate,
            @MatchStatus,
            @BankAmount,
            @ExcelAmount,
            @DiscrepancyReason,
            @RequiresInvestigation,
            GETUTCDATE()
        );

        SET @ReconResultID = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH

        ROLLBACK TRANSACTION;

        SET @ErrorMessage =
            'Failed to insert recon result for ref ' + @TransactionRef + '. ' +
            'Error ' + CAST(ERROR_NUMBER() AS NVARCHAR) + ': ' + ERROR_MESSAGE();

        SET @ReconResultID = NULL;

    END CATCH;

END;
GO


-- ============================================================
-- PROCEDURE 4: sp_InsertReconRunAudit
-- Called once at END of each bot run with summary stats
-- ============================================================
IF OBJECT_ID('dbo.sp_InsertReconRunAudit', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_InsertReconRunAudit;
GO

CREATE PROCEDURE dbo.sp_InsertReconRunAudit
    @RunID                UNIQUEIDENTIFIER,
    @RunDate              DATE,
    @AccountNumber        NVARCHAR(50),
    @ReconPeriodStart     DATE,
    @ReconPeriodEnd       DATE,
    @TotalBankRecords     INT,
    @TotalExcelRecords    INT,
    @TotalMatched         INT,
    @TotalDiscrepancies   INT,
    @TotalUnmatchedBank   INT,
    @TotalUnmatchedExcel  INT,
    @ReportFilePath       NVARCHAR(500) = NULL,
    @RunDurationSeconds   INT           = NULL,
    @ErrorMessage         NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @ErrorMessage = NULL;

    BEGIN TRY

        INSERT INTO dbo.RPA_Recon_AuditLog (
            RunID,
            RunDate,
            AccountNumber,
            ReconPeriodStart,
            ReconPeriodEnd,
            TotalBankRecords,
            TotalExcelRecords,
            TotalMatched,
            TotalDiscrepancies,
            TotalUnmatchedBank,
            TotalUnmatchedExcel,
            ReportFilePath,
            RunDurationSeconds,
            CreatedAt
        )
        VALUES (
            @RunID,
            @RunDate,
            @AccountNumber,
            @ReconPeriodStart,
            @ReconPeriodEnd,
            @TotalBankRecords,
            @TotalExcelRecords,
            @TotalMatched,
            @TotalDiscrepancies,
            @TotalUnmatchedBank,
            @TotalUnmatchedExcel,
            @ReportFilePath,
            @RunDurationSeconds,
            GETUTCDATE()
        );

    END TRY
    BEGIN CATCH

        SET @ErrorMessage =
            'Failed to insert run audit for RunID ' + CAST(@RunID AS NVARCHAR(50)) + '. ' +
            'Error ' + CAST(ERROR_NUMBER() AS NVARCHAR) + ': ' + ERROR_MESSAGE();

    END CATCH;

END;
GO


-- ============================================================
-- PROCEDURE 5: sp_GetUnresolvedDiscrepancies
-- Called by bot to build escalation email content
-- ============================================================
IF OBJECT_ID('dbo.sp_GetUnresolvedDiscrepancies', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetUnresolvedDiscrepancies;
GO

CREATE PROCEDURE dbo.sp_GetUnresolvedDiscrepancies
    @RunID            UNIQUEIDENTIFIER = NULL,   -- NULL = all unresolved, not just this run
    @AccountNumber    NVARCHAR(50)     = NULL    -- NULL = all accounts
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        rr.ReconResultID,
        rr.RunID,
        rr.TransactionRef,
        rr.AccountNumber,
        rr.TransactionDate,
        rr.MatchStatus,
        rr.BankAmount,
        rr.ExcelAmount,
        rr.AmountDelta,
        rr.DiscrepancyReason,
        rr.CreatedAt AS FlaggedAt
    FROM dbo.RPA_Recon_Results rr
    WHERE rr.RequiresInvestigation = 1
      AND rr.InvestigatedAt IS NULL
      AND (@RunID IS NULL OR rr.RunID = @RunID)
      AND (@AccountNumber IS NULL OR rr.AccountNumber = @AccountNumber)
    ORDER BY rr.AmountDelta DESC, rr.TransactionDate ASC;

END;
GO


-- ============================================================
-- GRANT permissions to bot service account
-- ============================================================
GRANT EXECUTE ON dbo.sp_GetBankTransactions         TO [DOMAIN\rpa-recon-svc];
GRANT EXECUTE ON dbo.sp_GetExcelTransactions        TO [DOMAIN\rpa-recon-svc];
GRANT EXECUTE ON dbo.sp_InsertReconciliationResult  TO [DOMAIN\rpa-recon-svc];
GRANT EXECUTE ON dbo.sp_InsertReconRunAudit         TO [DOMAIN\rpa-recon-svc];
GRANT EXECUTE ON dbo.sp_GetUnresolvedDiscrepancies  TO [DOMAIN\rpa-recon-svc];
GO
