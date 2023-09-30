CREATE PROCEDURE [dbo].[spLocal_RTCR_VendorQA_EditHeaderData]
@op_ErrorGUID UNIQUEIDENTIFIER NULL OUTPUT, @op_ValidationCode INT NULL OUTPUT, @op_ValidationMessage VARCHAR (MAX) NULL OUTPUT, @p_DebugFlag BIT NULL, @p_TransactionType INT NULL, @p_VQAHeaderId INT NULL OUTPUT, @p_GCAS VARCHAR (25) NULL, @p_SupplierNumber VARCHAR (50) NULL, @p_LineName VARCHAR (50) NULL, @p_Timestamp DATETIME NULL, @p_PGSendTime DATETIME NULL, @p_MPMPNumber VARCHAR (50) NULL, @p_Status VARCHAR (50) NULL, @p_UserId INT NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


