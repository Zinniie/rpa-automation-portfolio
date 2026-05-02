-- ============================================================
-- BN Bank RPA Database Schema
-- Project : Cross Currency Posting Automation (SDD-BN-002)
-- Platform : Blue Prism 7.1.0
-- Author   : Blessing Nnabugwu — RPA Developer
-- Date     : April 2024
-- ============================================================
-- Purpose:
--   Creates the core database tables used by the Cross Currency
--   Posting bot. Two tables are used:
--
--   1. BNProducts       — Master product configuration
--   2. BNProductList    — Daily run tracking (populated at 02:00 AM)
--   3. BNProductFileList — Daily file list per product session
--
--   Two scheduled database jobs run at 02:00 AM each day to
--   pre-populate BNProductList and BNProductFileList before
--   the first posting session begins at 10:00 AM.
-- ============================================================

USE BNRPA;
GO

-- ============================================================
-- TABLE: dbo.BNProducts
-- Master configuration table for all automated products.
-- Read by the bot to determine session settings and parameters.
-- ============================================================
IF OBJECT_ID('dbo.BNProducts', 'U') IS NOT NULL
    DROP TABLE dbo.BNProducts;
GO

CREATE TABLE dbo.BNProducts (
    ProductCode                  NVARCHAR(20)     NOT NULL,  -- Unique session identifier e.g. FXP1, FXP2, FXP3
    ProductName                  NVARCHAR(200)    NOT NULL,  -- Descriptive name of the product
    ActiveStatus                 BIT              NOT NULL   -- 1 = Active, 0 = Disabled (bot will skip)
        CONSTRAINT DF_BNProducts_Active DEFAULT (1),
    StartTime                    TIME             NOT NULL,  -- Scheduled start time for this session
    RunsOnNonBusinessDays        BIT              NOT NULL   -- Controls if session runs on non-business days
        CONSTRAINT DF_BNProducts_NonBizDay DEFAULT (0),
    MaxDaysBeforeReversal        INT              NULL,      -- Days before reversal posting is triggered
    MaxDaysBeforeRecoup          INT              NULL,      -- Days before recoup posting is triggered
    IsPostingOnForReconciliation BIT              NOT NULL   -- Enables automatic reconciliation posting
        CONSTRAINT DF_BNProducts_Recon DEFAULT (0),
    IsPostingOnForReversal       BIT              NOT NULL   -- Enables automatic reversal posting
        CONSTRAINT DF_BNProducts_Reversal DEFAULT (0),
    IsPostingOnForRecoup         BIT              NOT NULL   -- Enables automatic recoup posting
        CONSTRAINT DF_BNProducts_Recoup DEFAULT (0),
    MaxNoOfRetrials              INT              NOT NULL   -- Max processing attempts before session abandoned
        CONSTRAINT DF_BNProducts_Retries DEFAULT (3),
    OutputFilePath               NVARCHAR(500)    NULL,      -- Network path for bot output Excel workbook
    From_Account_ID              NVARCHAR(50)     NULL,      -- Originating account for transactions
    STAN                         NVARCHAR(50)     NULL,      -- System Trace Audit Number

    CONSTRAINT PK_BNProducts PRIMARY KEY CLUSTERED (ProductCode)
);
GO

-- ── SEED DATA: Three Cross Currency Posting sessions ─────────
INSERT INTO dbo.BNProducts (
    ProductCode, ProductName, ActiveStatus, StartTime,
    RunsOnNonBusinessDays, MaxNoOfRetrials,
    IsPostingOnForReconciliation, IsPostingOnForReversal, IsPostingOnForRecoup,
    OutputFilePath
)
VALUES
    ('FXP1', 'Cross Currency Posting — Session 1', 1, '10:00:00', 0, 3, 1, 0, 0,
     '\\bn-rpa-bot\rpa-production\BOT REPORT\BOT OUTPUT\[yyyy]\[MMM yyyy]\[dd MMM yyyy]\CROSS POSTING\'),
    ('FXP2', 'Cross Currency Posting — Session 2', 1, '13:00:00', 0, 3, 1, 0, 0,
     '\\bn-rpa-bot\rpa-production\BOT REPORT\BOT OUTPUT\[yyyy]\[MMM yyyy]\[dd MMM yyyy]\CROSS POSTING\'),
    ('FXP3', 'Cross Currency Posting — Session 3', 1, '16:00:00', 0, 3, 1, 0, 0,
     '\\bn-rpa-bot\rpa-production\BOT REPORT\BOT OUTPUT\[yyyy]\[MMM yyyy]\[dd MMM yyyy]\CROSS POSTING\');
GO


-- ============================================================
-- TABLE: dbo.BNProductList
-- Daily run tracker — populated at 02:00 AM by the Load Products
-- database job. Updated by the bot throughout the day.
-- ============================================================
IF OBJECT_ID('dbo.BNProductList', 'U') IS NOT NULL
    DROP TABLE dbo.BNProductList;
GO

CREATE TABLE dbo.BNProductList (
    ProductListID            INT IDENTITY(1,1)   NOT NULL,
    ProductCode              NVARCHAR(20)         NOT NULL,  -- FK to BNProducts
    PostingDate              DATE                 NOT NULL,  -- Date of this posting instance
    HasProductCompleted      BIT                  NOT NULL   -- Session completed successfully
        CONSTRAINT DF_BNProductList_Completed DEFAULT (0),
    HasPostedCompleted       BIT                  NOT NULL   -- Reversal posting completed
        CONSTRAINT DF_BNProductList_Posted DEFAULT (0),
    HasPostedReconciliation  BIT                  NOT NULL   -- Reconciliation posting completed
        CONSTRAINT DF_BNProductList_Reconciled DEFAULT (0),
    NoOfRetries              INT                  NOT NULL   -- Attempts made by bot for this session
        CONSTRAINT DF_BNProductList_Retries DEFAULT (0),
    LastAttemptedAt          DATETIME2            NULL,      -- Timestamp of most recent processing attempt
    CompletedAt              DATETIME2            NULL,      -- Timestamp of successful completion
    CreatedAt                DATETIME2            NOT NULL
        CONSTRAINT DF_BNProductList_Created DEFAULT (GETUTCDATE()),

    CONSTRAINT PK_BNProductList PRIMARY KEY CLUSTERED (ProductListID),
    CONSTRAINT FK_BNProductList_Products
        FOREIGN KEY (ProductCode) REFERENCES dbo.BNProducts (ProductCode),
    CONSTRAINT UQ_BNProductList_ProductDate
        UNIQUE (ProductCode, PostingDate)
);
GO

-- Index for fast product eligibility queries
-- Bot queries: product not completed + retries not exceeded + scheduled time not passed
CREATE NONCLUSTERED INDEX IX_BNProductList_EligibilityCheck
    ON dbo.BNProductList (PostingDate, HasProductCompleted, NoOfRetries)
    INCLUDE (ProductCode, LastAttemptedAt);
GO


-- ============================================================
-- TABLE: dbo.BNProductFileList
-- Populated at 02:00 AM daily. Stores the list of files
-- required for each product session.
-- ============================================================
IF OBJECT_ID('dbo.BNProductFileList', 'U') IS NOT NULL
    DROP TABLE dbo.BNProductFileList;
GO

CREATE TABLE dbo.BNProductFileList (
    FileListID       INT IDENTITY(1,1)   NOT NULL,
    ProductCode      NVARCHAR(20)         NOT NULL,  -- FK to BNProducts
    PostingDate      DATE                 NOT NULL,
    FileName         NVARCHAR(500)        NOT NULL,  -- Expected filename (dynamic tokens resolved at runtime)
    SourcePath       NVARCHAR(500)        NOT NULL,  -- Network path where file should be found
    FileRetrieved    BIT                  NOT NULL   -- Bot sets to 1 after successful file retrieval
        CONSTRAINT DF_BNProductFileList_Retrieved DEFAULT (0),
    RetrievedAt      DATETIME2            NULL,
    CreatedAt        DATETIME2            NOT NULL
        CONSTRAINT DF_BNProductFileList_Created DEFAULT (GETUTCDATE()),

    CONSTRAINT PK_BNProductFileList PRIMARY KEY CLUSTERED (FileListID),
    CONSTRAINT FK_BNProductFileList_Products
        FOREIGN KEY (ProductCode) REFERENCES dbo.BNProducts (ProductCode)
);
GO

CREATE NONCLUSTERED INDEX IX_BNProductFileList_ProductDate
    ON dbo.BNProductFileList (ProductCode, PostingDate, FileRetrieved);
GO


-- ============================================================
-- TABLE: dbo.CrossCurrencyItems
-- Staging table — truncated and repopulated on each session run.
-- Holds entries read from the posting file before validation.
-- ============================================================
IF OBJECT_ID('dbo.CrossCurrencyItems', 'U') IS NOT NULL
    DROP TABLE dbo.CrossCurrencyItems;
GO

CREATE TABLE dbo.CrossCurrencyItems (
    ItemID              INT IDENTITY(1,1)   NOT NULL,
    ProductCode         NVARCHAR(20)         NOT NULL,
    PostingDate         DATE                 NOT NULL,
    TransactionDate     DATE                 NULL,
    FromAccountID       NVARCHAR(50)         NULL,     -- Originating account
    ToAccountID         NVARCHAR(50)         NULL,     -- Destination account
    CurrencyFrom        NCHAR(3)             NULL,     -- Source currency code
    CurrencyTo          NCHAR(3)             NULL,     -- Target currency code
    Amount              DECIMAL(18,2)        NULL,     -- Transaction amount
    ExchangeRate        DECIMAL(18,6)        NULL,     -- Applied exchange rate
    ConvertedAmount     DECIMAL(18,2)        NULL,     -- Amount in target currency
    STAN                NVARCHAR(50)         NULL,     -- System Trace Audit Number
    ItemStatus          NVARCHAR(30)         NULL,     -- Pending | Posted | Exception | MismatchedPair
    PostedAt            DATETIME2            NULL,
    ExceptionReason     NVARCHAR(500)        NULL,
    LoadedAt            DATETIME2            NOT NULL
        CONSTRAINT DF_CrossCurrencyItems_Loaded DEFAULT (GETUTCDATE()),

    CONSTRAINT PK_CrossCurrencyItems PRIMARY KEY CLUSTERED (ItemID),
    CONSTRAINT CK_CrossCurrencyItems_Status CHECK (
        ItemStatus IN ('Pending', 'Posted', 'Exception', 'MismatchedPair') OR ItemStatus IS NULL
    )
);
GO


-- ============================================================
-- STORED PROCEDURE: sp_GetEligibleProducts
-- Called by BN Operations Process at the start of each run.
-- Returns product sessions eligible to run for today.
-- ============================================================
IF OBJECT_ID('dbo.sp_GetEligibleProducts', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetEligibleProducts;
GO

CREATE PROCEDURE dbo.sp_GetEligibleProducts
    @PostingDate  DATE,
    @CurrentTime  TIME
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        pl.ProductCode,
        p.ProductName,
        p.StartTime,
        p.MaxNoOfRetrials,
        p.OutputFilePath,
        pl.NoOfRetries,
        pl.HasProductCompleted
    FROM dbo.BNProductList pl
    INNER JOIN dbo.BNProducts p ON pl.ProductCode = p.ProductCode
    WHERE pl.PostingDate         = @PostingDate
      AND pl.HasProductCompleted = 0              -- Not yet successfully completed
      AND pl.NoOfRetries         < p.MaxNoOfRetrials  -- Retry limit not exceeded
      AND p.ActiveStatus         = 1              -- Product is active
      AND p.StartTime            <= @CurrentTime  -- Scheduled time has arrived
    ORDER BY p.StartTime ASC;

END;
GO


-- ============================================================
-- STORED PROCEDURE: sp_UpdateProductStatus
-- Called by the bot after each session attempt.
-- ============================================================
IF OBJECT_ID('dbo.sp_UpdateProductStatus', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_UpdateProductStatus;
GO

CREATE PROCEDURE dbo.sp_UpdateProductStatus
    @ProductCode         NVARCHAR(20),
    @PostingDate         DATE,
    @HasCompleted        BIT,
    @IncrementRetryCount BIT = 1,
    @ErrorMessage        NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    BEGIN TRY

        UPDATE dbo.BNProductList
        SET
            HasProductCompleted = @HasCompleted,
            NoOfRetries         = CASE WHEN @IncrementRetryCount = 1
                                       THEN NoOfRetries + 1
                                       ELSE NoOfRetries END,
            LastAttemptedAt     = GETUTCDATE(),
            CompletedAt         = CASE WHEN @HasCompleted = 1
                                       THEN GETUTCDATE()
                                       ELSE NULL END
        WHERE ProductCode  = @ProductCode
          AND PostingDate  = @PostingDate;

    END TRY
    BEGIN CATCH
        SET @ErrorMessage =
            'Failed to update product status for ' + @ProductCode +
            '. Error: ' + ERROR_MESSAGE();
    END CATCH;

END;
GO


-- ============================================================
-- GRANT permissions to bot service account
-- Replace 'DOMAIN\rpa-crosscurrency-svc' with actual account
-- ============================================================
GRANT SELECT, INSERT, UPDATE ON dbo.BNProducts           TO [DOMAIN\rpa-crosscurrency-svc];
GRANT SELECT, INSERT, UPDATE ON dbo.BNProductList        TO [DOMAIN\rpa-crosscurrency-svc];
GRANT SELECT, INSERT, UPDATE ON dbo.BNProductFileList    TO [DOMAIN\rpa-crosscurrency-svc];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.CrossCurrencyItems TO [DOMAIN\rpa-crosscurrency-svc];
GRANT EXECUTE ON dbo.sp_GetEligibleProducts              TO [DOMAIN\rpa-crosscurrency-svc];
GRANT EXECUTE ON dbo.sp_UpdateProductStatus              TO [DOMAIN\rpa-crosscurrency-svc];
GO


-- ============================================================
-- SAMPLE QUERIES
-- ============================================================

-- Today's session status dashboard
/*
SELECT
    pl.ProductCode,
    p.ProductName,
    p.StartTime,
    pl.HasProductCompleted,
    pl.NoOfRetries,
    pl.LastAttemptedAt,
    pl.CompletedAt
FROM dbo.BNProductList pl
INNER JOIN dbo.BNProducts p ON pl.ProductCode = p.ProductCode
WHERE pl.PostingDate = CAST(GETDATE() AS DATE)
ORDER BY p.StartTime ASC;
*/

-- All items from today's cross currency run by status
/*
SELECT
    ItemStatus,
    COUNT(*) AS ItemCount,
    SUM(Amount) AS TotalAmount,
    SUM(ConvertedAmount) AS TotalConverted
FROM dbo.CrossCurrencyItems
WHERE PostingDate = CAST(GETDATE() AS DATE)
GROUP BY ItemStatus;
*/

-- Sessions that have not completed today and still have retries remaining
/*
SELECT
    pl.ProductCode,
    p.ProductName,
    pl.NoOfRetries,
    p.MaxNoOfRetrials,
    pl.LastAttemptedAt
FROM dbo.BNProductList pl
INNER JOIN dbo.BNProducts p ON pl.ProductCode = p.ProductCode
WHERE pl.PostingDate         = CAST(GETDATE() AS DATE)
  AND pl.HasProductCompleted = 0
  AND pl.NoOfRetries         < p.MaxNoOfRetrials
ORDER BY p.StartTime ASC;
*/
