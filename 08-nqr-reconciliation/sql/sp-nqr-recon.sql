-- ============================================================
-- Stored Procedure: spNQRRecon
-- Project : NQR Reconciliation Automation (SDD-BN-005)
-- Platform : Blue Prism - called from Execute spNQRRecon stage
-- Author   : Blessing Nnabugwu - RPA Developer
-- Date     : October 2024
-- ============================================================
-- Purpose:
--   Core reconciliation engine for NQR (National QR Code Payment)
--   transactions. Accepts a date range and performs:
--     1. Auto-reversal detection -- identifies GL credit/debit pairs
--        with matching TRAN_RMKS before primary matching begins
--     2. Settlement-to-GL matching -- joins settlement entries to GL
--        credit entries on NIP_SESSION_ID or PAYMENT_REFERENCE
--     3. Exception classification -- unmatched GL entries classified
--        as Cr Exception or Dr Exception; unmatched settlement entries
--        returned as settlement exceptions
--
-- Called by:
--   Blue Prism action stage: Execute spNQRRecon
--   Result saved to collection: Result_Exception
--   Other results read from permanent tables via separate queries:
--     NQRReconMatched, NQRRECONGLException, NQRRECONAutoReversed
--
-- Parameters:
--   @start_date  NVARCHAR(50) -- Start of reconciliation window (yyyy-MM-dd)
--   @end_date    NVARCHAR(50) -- End of reconciliation window (yyyy-MM-dd)
-- ============================================================

USE BNRPA;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[spNQRRecon]
    @start_date NVARCHAR(50),
    @end_date   NVARCHAR(50)
-- @start_date and @end_date must be in yyyy-MM-dd format
AS
BEGIN

    -- ============================================================
    -- STEP 1: Create temp tables
    -- ============================================================

    -- Temp table for matched settlement-to-GL pairs
    CREATE TABLE #tempMatchedItems (
        NIP_SESSION_ID        NVARCHAR(1000),
        RESPONSE              NVARCHAR(100),
        AMOUNT                NVARCHAR(1000),
        ACTUAL_AMOUNT         NVARCHAR(1000),
        TRANSACTION_TIME      NVARCHAR(1000),
        PAYERS_ACCOUNT_NUMBER NVARCHAR(1000),
        PAYERS_ACCOUNT_NAME   NVARCHAR(1000),
        PAYING_BANK           NVARCHAR(1000),
        MERCHANT_NAME         NVARCHAR(1000),
        MERCHANT_ACCOUNT_NO   NVARCHAR(1000),
        RECEIVING_BANK        NVARCHAR(1000),
        NARRATION             NVARCHAR(1000),
        PAYMENT_REFERENCE     NVARCHAR(1000),
        FILE_SOURCE           NVARCHAR(50),
        FORACID               NVARCHAR(1000),
        TRAN_DATE             NVARCHAR(1000),
        TRAN_AMT              NVARCHAR(1000),
        TRAN_ID               NVARCHAR(1000),
        TRAN_PARTICULAR       NVARCHAR(1000),
        TRAN_RMKS             NVARCHAR(1000),
        VALUE_DATE            NVARCHAR(1000),
        PSTD_DATE             NVARCHAR(1000),
        ENTRY_USER_ID         NVARCHAR(1000),
        PSTD_USER_ID          NVARCHAR(1000),
        VFD_USER_ID           NVARCHAR(1000),
        AmountDifference      NVARCHAR(1000) NULL,
        Status                NVARCHAR(50)
    );

    -- Temp table for auto-reversed GL entry pairs
    CREATE TABLE #ReversedMatchedItems (
        FORACID               NVARCHAR(1000),
        TRAN_DATE             NVARCHAR(1000),
        TRAN_AMT              NVARCHAR(1000),
        TRAN_ID               NVARCHAR(1000),
        TRAN_PARTICULAR       NVARCHAR(1000),
        TRAN_RMKS             NVARCHAR(1000),
        VALUE_DATE            NVARCHAR(1000),
        PSTD_DATE             NVARCHAR(1000),
        ENTRY_USER_ID         NVARCHAR(1000),
        PSTD_USER_ID          NVARCHAR(1000),
        VFD_USER_ID           NVARCHAR(1000),
        CONTRA_ACCT           NVARCHAR(100),
        Status                NVARCHAR(50)
    );

    -- Temp table for settlement exception staging
    CREATE TABLE #NQRRECONExceptions (
        UniqueID               NVARCHAR(100),
        SessionId              VARCHAR(40),
        Amount                 DECIMAL(18,2),
        Narration              VARCHAR(1000),
        ItemSource             VARCHAR(100),
        TransactionTime        DATETIME,
        SessionTime            VARCHAR(20),
        Foracid                VARCHAR(20),
        ReconDate              DATETIME,
        TranDate               DATETIME,
        TranId                 VARCHAR(50),
        PartTranType           VARCHAR(5),
        TSQStatus              VARCHAR(1000),
        OriginationInstitution VARCHAR(1000),
        PSTDUSERID             VARCHAR(20),
        VFDUSERID              VARCHAR(20),
        Channel                VARCHAR(255)
    );


    -- ============================================================
    -- STEP 2: Truncate result tables from previous run
    -- ============================================================
    TRUNCATE TABLE NQRReconMatched;
    TRUNCATE TABLE NQRRECONGLException;


    -- ============================================================
    -- STEP 3: Load settlement report into temp table
    --
    -- Reformats two fields for clean matching:
    --   NIP_SESSION_ID:    removes surrounding single quotes
    --   PAYMENT_REFERENCE: removes 'NQR/' prefix
    --
    -- Filters to the reconciliation date range.
    -- Reading into temp preserves the original NQRTransactionReport record.
    -- ============================================================
    SELECT
        REPLACE(NIP_SESSION_ID, '''', '')      AS NIP_SESSION_ID,
        RESPONSE,
        AMOUNT,
        ACTUAL_AMOUNT,
        TRANSACTION_TIME,
        PAYERS_ACCOUNT_NUMBER,
        PAYERS_ACCOUNT_NAME,
        PAYING_BANK,
        MERCHANT_NAME,
        MERCHANT_ACCOUNT_NO,
        RECEIVING_BANK,
        NARRATION,
        REPLACE(PAYMENT_REFERENCE, 'NQR/', '') AS PAYMENT_REFERENCE,
        FILE_SOURCE
    INTO #nqrtransactionreport
    FROM NQRTransactionReport
    WHERE CONVERT(DATE, REPLACE(TRANSACTION_TIME, '''', ''))
          BETWEEN @start_date AND @end_date;


    -- ============================================================
    -- STEP 4: Split GL by transaction type into credit / debit temps
    --
    -- FORACID values are the NQR transit account numbers on BNRPA.
    -- Two accounts are in scope for NQR reconciliation.
    -- ============================================================
    SELECT
        UNIQUE_FIELD, TRAN_DATE, TRAN_ID, PART_TRAN_TYPE, FORACID,
        VALUE_DATE, PSTD_DATE, TRAN_AMT, TRAN_PARTICULAR,
        ENTRY_USER_ID, PSTD_USER_ID, VFD_USER_ID, TRAN_RMKS, CONTRA_ACCT
    INTO #NQRRECONGLCREDIT
    FROM NQRRECONGL
    WHERE PART_TRAN_TYPE = 'C'
      AND FORACID IN ('999NGN00000001', '999NGN00000002');

    SELECT
        UNIQUE_FIELD, TRAN_DATE, TRAN_ID, PART_TRAN_TYPE, FORACID,
        VALUE_DATE, PSTD_DATE, TRAN_AMT, TRAN_PARTICULAR,
        ENTRY_USER_ID, PSTD_USER_ID, VFD_USER_ID, TRAN_RMKS, CONTRA_ACCT
    INTO #NQRRECONGLDEBIT
    FROM NQRRECONGL
    WHERE PART_TRAN_TYPE = 'D'
      AND FORACID IN ('999NGN00000001', '999NGN00000002');


    -- ============================================================
    -- STEP 5: Auto-reversal detection
    --
    -- A GL entry pair is auto-reversed when a credit and debit
    -- share the same TRAN_RMKS (exact or contains relationship).
    -- Both sides are captured then deleted from the credit/debit
    -- temps BEFORE primary matching -- prevents reversed entries
    -- from appearing as false GL exceptions.
    -- ============================================================
    PRINT('auto reversal start');

    INSERT INTO #ReversedMatchedItems
    SELECT
        a.FORACID, a.TRAN_DATE, a.TRAN_AMT, a.TRAN_ID,
        a.TRAN_PARTICULAR, a.TRAN_RMKS, a.VALUE_DATE, a.PSTD_DATE,
        a.ENTRY_USER_ID, a.PSTD_USER_ID, a.VFD_USER_ID,
        a.CONTRA_ACCT, 'Auto Reversed GL Credit'
    FROM #NQRRECONGLCREDIT a
    INNER JOIN #NQRRECONGLDEBIT b
        ON a.TRAN_RMKS = b.TRAN_RMKS
        OR b.TRAN_RMKS LIKE '%' + a.TRAN_RMKS + '%';

    INSERT INTO #ReversedMatchedItems
    SELECT
        b.FORACID, b.TRAN_DATE, b.TRAN_AMT, b.TRAN_ID,
        b.TRAN_PARTICULAR, b.TRAN_RMKS, b.VALUE_DATE, b.PSTD_DATE,
        b.ENTRY_USER_ID, b.PSTD_USER_ID, b.VFD_USER_ID,
        b.CONTRA_ACCT, 'Auto Reversed GL Debit'
    FROM #NQRRECONGLCREDIT a
    INNER JOIN #NQRRECONGLDEBIT b
        ON a.TRAN_RMKS = b.TRAN_RMKS
        OR b.TRAN_RMKS LIKE '%' + a.TRAN_RMKS + '%';

    DELETE FROM #NQRRECONGLCREDIT
    WHERE TRAN_RMKS IN (SELECT TRAN_RMKS FROM #ReversedMatchedItems);

    DELETE FROM #NQRRECONGLDEBIT
    WHERE TRAN_PARTICULAR IN (SELECT TRAN_PARTICULAR FROM #ReversedMatchedItems);

    PRINT('end of auto reversal');


    -- ============================================================
    -- STEP 6: Match settlement report vs GL credit entries
    --
    -- Dual-key matching:
    --   Key 1: NIP_SESSION_ID = TRAN_RMKS
    --   Key 2: PAYMENT_REFERENCE = TRAN_RMKS
    --
    -- AmountDifference = GL TRAN_AMT minus Settlement ACTUAL_AMOUNT
    -- ============================================================
    PRINT('report and GL credit matching: start');

    INSERT INTO #tempMatchedItems
    SELECT
        a.NIP_SESSION_ID, a.RESPONSE, a.AMOUNT, a.ACTUAL_AMOUNT,
        a.TRANSACTION_TIME, a.PAYERS_ACCOUNT_NUMBER, a.PAYERS_ACCOUNT_NAME,
        a.PAYING_BANK, a.MERCHANT_NAME, a.MERCHANT_ACCOUNT_NO,
        a.RECEIVING_BANK, a.NARRATION, a.PAYMENT_REFERENCE, a.FILE_SOURCE,
        b.FORACID, b.TRAN_DATE, b.TRAN_AMT, b.TRAN_ID,
        b.TRAN_PARTICULAR, b.TRAN_RMKS, b.VALUE_DATE, b.PSTD_DATE,
        b.ENTRY_USER_ID, b.PSTD_USER_ID, b.VFD_USER_ID,
        TRY_CONVERT(FLOAT, b.TRAN_AMT)
            - TRY_CONVERT(FLOAT, REPLACE(a.ACTUAL_AMOUNT, '''', ''))
            AS AmountDifference,
        'Matched' AS Status
    FROM #nqrtransactionreport a
    INNER JOIN #NQRRECONGLCREDIT b
        ON a.NIP_SESSION_ID    = b.TRAN_RMKS
        OR a.PAYMENT_REFERENCE = b.TRAN_RMKS;

    -- Remove matched GL credits (prevent double-matching)
    DELETE FROM #NQRRECONGLCREDIT
    WHERE TRAN_RMKS IS NOT NULL
      AND TRAN_RMKS IN (SELECT TRAN_RMKS FROM #tempMatchedItems);

    -- Remove matched settlement entries
    DELETE FROM #nqrtransactionreport
    WHERE PAYMENT_REFERENCE IN (SELECT PAYMENT_REFERENCE FROM #tempMatchedItems)
       OR NIP_SESSION_ID     IN (SELECT NIP_SESSION_ID   FROM #tempMatchedItems);

    PRINT('End of report and GL credit matching');


    -- ============================================================
    -- STEP 7: Persist matched results
    -- ============================================================
    INSERT INTO NQRReconMatched
    SELECT * FROM #tempMatchedItems;


    -- ============================================================
    -- STEP 8: Classify GL exceptions
    -- Remaining credits = Cr Exception
    -- Remaining debits  = Dr Exception
    -- ============================================================
    PRINT('exception');

    INSERT INTO NQRRECONGLException SELECT *, 'Cr Exception' FROM #NQRRECONGLCREDIT;
    INSERT INTO NQRRECONGLException SELECT *, 'Dr Exception' FROM #NQRRECONGLDEBIT;


    -- ============================================================
    -- STEP 9: Persist auto-reversals
    -- ============================================================
    INSERT INTO NQRRECONAutoReversed
    SELECT * FROM #ReversedMatchedItems;


    -- ============================================================
    -- STEP 10: Return settlement exceptions
    --
    -- Remaining entries in #nqrtransactionreport are open items
    -- on the settlement side -- no matching GL credit found.
    -- Single-quote prefix restored for reporting format.
    -- ============================================================
    SELECT
        '''' + NIP_SESSION_ID    AS NIP_SESSION_ID,
        RESPONSE, AMOUNT, ACTUAL_AMOUNT, TRANSACTION_TIME,
        PAYERS_ACCOUNT_NUMBER, PAYERS_ACCOUNT_NAME, PAYING_BANK,
        MERCHANT_NAME, MERCHANT_ACCOUNT_NO, RECEIVING_BANK, NARRATION,
        '''' + PAYMENT_REFERENCE AS PAYMENT_REFERENCE,
        FILE_SOURCE
    FROM #nqrtransactionreport;

END;
GO

GRANT EXECUTE ON dbo.spNQRRecon TO [DOMAIN\rpa-nqr-svc];
GO

-- ============================================================
-- SAMPLE USAGE
-- ============================================================
/*
EXEC dbo.spNQRRecon @start_date = '2025-01-06', @end_date = '2025-01-06';

-- Post-weekend (covers Fri-Mon)
EXEC dbo.spNQRRecon @start_date = '2025-01-03', @end_date = '2025-01-06';

-- Matched summary
SELECT COUNT(*) AS MatchedCount, SUM(TRY_CONVERT(FLOAT, TRAN_AMT)) AS MatchedVolume
FROM NQRReconMatched;

-- Exception breakdown
SELECT ExceptionType, COUNT(*) AS Count, SUM(TRY_CONVERT(FLOAT, TRAN_AMT)) AS Volume
FROM NQRRECONGLException GROUP BY ExceptionType;

-- Variance on matched items
SELECT COUNT(*) AS ItemsWithVariance,
       SUM(TRY_CONVERT(FLOAT, AmountDifference)) AS TotalVariance
FROM NQRReconMatched WHERE TRY_CONVERT(FLOAT, AmountDifference) <> 0;
*/
