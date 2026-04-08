-- ============================================================
-- Stored Procedure: sp_InsertInvoicePaymentRecord
-- Project : Invoice Processing Automation (SDD-RPA-001)
-- Platform : UiPath — called from Process.xaml on success
-- Author   : Blessing Nnabugwu — RPA Developer
-- Date     : April 2026
-- ============================================================
-- Purpose:
--   Called by the bot ONLY after sp_ValidateInvoiceAgainstPO
--   returns 'Passed'. Inserts the approved invoice as a
--   payment record and returns the new PaymentID for the
--   audit log.
--
--   Wrapped in a transaction — if the insert fails partway,
--   the entire operation rolls back cleanly.
-- ============================================================

USE InvoiceProcessingDB;
GO

IF OBJECT_ID('dbo.sp_InsertInvoicePaymentRecord', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_InsertInvoicePaymentRecord;
GO

CREATE PROCEDURE dbo.sp_InsertInvoicePaymentRecord
    @InvoiceNumber    NVARCHAR(50),
    @VendorName       NVARCHAR(200),
    @InvoiceDate      DATE,
    @PONumber         NVARCHAR(50),
    @InvoiceTotal     DECIMAL(18,2),
    @TaxAmount        DECIMAL(18,2) = 0.00,
    @FilePath         NVARCHAR(500),
    @ProcessedByBot   NVARCHAR(100) = 'InvoiceProcessingBot',
    @QueueItemID      NVARCHAR(100),
    @RunID            UNIQUEIDENTIFIER,
    @NewPaymentID     INT OUTPUT,
    @ErrorMessage     NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @NewPaymentID = NULL;
    SET @ErrorMessage = NULL;

    -- ── Safety check: do not insert if already exists ─────────
    -- Belt-and-braces check even though validation already caught this
    IF EXISTS (
        SELECT 1 FROM dbo.InvoicePayments
        WHERE InvoiceNumber = @InvoiceNumber
    )
    BEGIN
        SET @ErrorMessage = 'Duplicate invoice detected at insert stage: ' + @InvoiceNumber;
        RETURN;
    END

    -- ── Look up VendorID ──────────────────────────────────────
    DECLARE @VendorID INT;

    SELECT @VendorID = VendorID
    FROM dbo.Vendors
    WHERE LOWER(LTRIM(RTRIM(VendorName))) = LOWER(LTRIM(RTRIM(@VendorName)));

    IF @VendorID IS NULL
    BEGIN
        SET @ErrorMessage = 'VendorID not found for vendor: ' + @VendorName;
        RETURN;
    END

    -- ── Insert payment record inside transaction ───────────────
    BEGIN TRANSACTION;

    BEGIN TRY

        INSERT INTO dbo.InvoicePayments (
            InvoiceNumber,
            VendorID,
            InvoiceDate,
            PONumber,
            InvoiceTotal,
            TaxAmount,
            NetAmount,
            PaymentStatus,
            ProcessedByBot,
            SourceFilePath,
            QueueItemID,
            RunID,
            CreatedAt
        )
        VALUES (
            @InvoiceNumber,
            @VendorID,
            @InvoiceDate,
            @PONumber,
            @InvoiceTotal,
            @TaxAmount,
            @InvoiceTotal - @TaxAmount,      -- Net amount computed at insert
            'PendingApproval',               -- Awaits finance sign-off before payment released
            @ProcessedByBot,
            @FilePath,
            @QueueItemID,
            @RunID,
            GETUTCDATE()
        );

        -- Return the new record ID for the audit log
        SET @NewPaymentID = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH

        ROLLBACK TRANSACTION;

        SET @ErrorMessage =
            'Insert failed for invoice ' + @InvoiceNumber + '. ' +
            'Error ' + CAST(ERROR_NUMBER() AS NVARCHAR) + ': ' + ERROR_MESSAGE();

        SET @NewPaymentID = NULL;

    END CATCH;

END;
GO


-- ============================================================
-- SAMPLE USAGE (for testing / reference)
-- ============================================================
/*
DECLARE
    @NewID    INT,
    @ErrorMsg NVARCHAR(500);

EXEC dbo.sp_InsertInvoicePaymentRecord
    @InvoiceNumber  = 'INV-2024-0891',
    @VendorName     = 'Acme Supplies Ltd',
    @InvoiceDate    = '2024-04-01',
    @PONumber       = 'PO-2024-0044',
    @InvoiceTotal   = 4250.00,
    @TaxAmount      = 250.00,
    @FilePath       = '\\invoices\2024\04\INV-2024-0891.pdf',
    @ProcessedByBot = 'InvoiceProcessingBot',
    @QueueItemID    = 'ORCH-QI-00247',
    @RunID          = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890',
    @NewPaymentID   = @NewID    OUTPUT,
    @ErrorMessage   = @ErrorMsg OUTPUT;

SELECT
    @NewID    AS NewPaymentID,
    @ErrorMsg AS ErrorMessage;
*/
