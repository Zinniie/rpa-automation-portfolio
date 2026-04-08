-- ============================================================
-- Stored Procedure: sp_ValidateInvoiceAgainstPO
-- Project : Invoice Processing Automation (SDD-RPA-001)
-- Platform : UiPath — called from ValidateAgainstPO.xaml
-- Author   : Blessing Nnabugwu — RPA Developer
-- Date     : April 2026
-- ============================================================
-- Purpose:
--   Called by the bot for every invoice transaction.
--   Validates the extracted invoice data against the Purchase
--   Order record in the database and returns a validation
--   result code that drives the bot's exception handling logic.
--
-- Returns:
--   ValidationResult  — Passed | PONotFound | AmountMismatch |
--                        VendorMismatch | DuplicateInvoice | InvalidDate
--   POTotal           — Approved PO amount (for audit log)
--   POVendorName      — Vendor name from PO (for comparison)
--   ErrorMessage      — Human-readable reason if validation fails
-- ============================================================

USE InvoiceProcessingDB;
GO

IF OBJECT_ID('dbo.sp_ValidateInvoiceAgainstPO', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ValidateInvoiceAgainstPO;
GO

CREATE PROCEDURE dbo.sp_ValidateInvoiceAgainstPO
    @InvoiceNumber     NVARCHAR(50),
    @VendorName        NVARCHAR(200),
    @InvoiceDate       DATE,
    @PONumber          NVARCHAR(50),
    @InvoiceTotal      DECIMAL(18,2),
    @TolerancePct      DECIMAL(5,2) = 0.5,   -- Allowable % variance (default 0.5%)
    @ValidationResult  NVARCHAR(50)  OUTPUT,
    @POTotal           DECIMAL(18,2) OUTPUT,
    @POVendorName      NVARCHAR(200) OUTPUT,
    @ErrorMessage      NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Initialise outputs
    SET @ValidationResult = NULL;
    SET @POTotal          = NULL;
    SET @POVendorName     = NULL;
    SET @ErrorMessage     = NULL;

    -- ── Step 1: Check for duplicate invoice ──────────────────
    IF EXISTS (
        SELECT 1
        FROM dbo.InvoicePayments
        WHERE InvoiceNumber = @InvoiceNumber
    )
    BEGIN
        SET @ValidationResult = 'DuplicateInvoice';
        SET @ErrorMessage     = 'Invoice ' + @InvoiceNumber + ' already exists in InvoicePayments table.';
        RETURN;
    END

    -- ── Step 2: Validate invoice date ────────────────────────
    IF @InvoiceDate > CAST(GETDATE() AS DATE)
    BEGIN
        SET @ValidationResult = 'InvalidDate';
        SET @ErrorMessage     = 'Invoice date ' + CAST(@InvoiceDate AS NVARCHAR) + ' is in the future.';
        RETURN;
    END

    -- ── Step 3: Look up Purchase Order ───────────────────────
    DECLARE
        @POApprovedAmount  DECIMAL(18,2),
        @POVendorID        INT,
        @POStatus          NVARCHAR(20);

    SELECT
        @POApprovedAmount = po.ApprovedAmount,
        @POVendorID       = po.VendorID,
        @POStatus         = po.Status,
        @POVendorName     = v.VendorName
    FROM dbo.PurchaseOrders po
    INNER JOIN dbo.Vendors v ON po.VendorID = v.VendorID
    WHERE po.PONumber = @PONumber;

    -- PO not found
    IF @POApprovedAmount IS NULL
    BEGIN
        SET @ValidationResult = 'PONotFound';
        SET @ErrorMessage     = 'PO Number ' + @PONumber + ' not found in PurchaseOrders table.';
        RETURN;
    END

    -- PO found — set output for audit log
    SET @POTotal = @POApprovedAmount;

    -- ── Step 4: Validate vendor name ─────────────────────────
    -- Case-insensitive comparison with SOUNDEX fallback for minor spelling variations
    IF LOWER(LTRIM(RTRIM(@VendorName))) <> LOWER(LTRIM(RTRIM(@POVendorName)))
       AND SOUNDEX(@VendorName) <> SOUNDEX(@POVendorName)
    BEGIN
        SET @ValidationResult = 'VendorMismatch';
        SET @ErrorMessage     = 'Vendor on invoice ("' + @VendorName + '") does not match PO vendor ("' + @POVendorName + '").';
        RETURN;
    END

    -- ── Step 5: Validate amount within tolerance ──────────────
    DECLARE @AllowedVariance DECIMAL(18,2);
    SET @AllowedVariance = @POApprovedAmount * (@TolerancePct / 100.0);

    IF ABS(@InvoiceTotal - @POApprovedAmount) > @AllowedVariance
    BEGIN
        SET @ValidationResult = 'AmountMismatch';
        SET @ErrorMessage     =
            'Invoice total $' + CAST(@InvoiceTotal AS NVARCHAR) +
            ' differs from PO approved amount $' + CAST(@POApprovedAmount AS NVARCHAR) +
            ' by more than ' + CAST(@TolerancePct AS NVARCHAR) + '% tolerance.';
        RETURN;
    END

    -- ── Step 6: Check PO status ───────────────────────────────
    IF @POStatus NOT IN ('Approved', 'Open')
    BEGIN
        SET @ValidationResult = 'PONotApproved';
        SET @ErrorMessage     = 'PO ' + @PONumber + ' has status "' + @POStatus + '" — must be Approved or Open.';
        RETURN;
    END

    -- ── All checks passed ─────────────────────────────────────
    SET @ValidationResult = 'Passed';
    SET @ErrorMessage     = NULL;

END;
GO


-- ============================================================
-- SAMPLE USAGE (for testing / reference)
-- ============================================================
/*
DECLARE
    @Result       NVARCHAR(50),
    @POTotal      DECIMAL(18,2),
    @POVendor     NVARCHAR(200),
    @ErrorMsg     NVARCHAR(500);

EXEC dbo.sp_ValidateInvoiceAgainstPO
    @InvoiceNumber    = 'INV-2024-0891',
    @VendorName       = 'Acme Supplies Ltd',
    @InvoiceDate      = '2024-04-01',
    @PONumber         = 'PO-2024-0044',
    @InvoiceTotal     = 4250.00,
    @TolerancePct     = 0.5,
    @ValidationResult = @Result    OUTPUT,
    @POTotal          = @POTotal   OUTPUT,
    @POVendorName     = @POVendor  OUTPUT,
    @ErrorMessage     = @ErrorMsg  OUTPUT;

SELECT
    @Result   AS ValidationResult,
    @POTotal  AS POApprovedAmount,
    @POVendor AS POVendorName,
    @ErrorMsg AS ErrorMessage;
*/
