CREATE PROCEDURE [dbo].[spLocal_RTCR_VendorQA_EditTestData]
@op_ErrorGUID UNIQUEIDENTIFIER NULL OUTPUT, @op_ValidationCode INT NULL OUTPUT, @op_ValidationMessage VARCHAR (MAX) NULL OUTPUT, @p_DebugFlag BIT NULL, @p_TransactionType INT NULL, @p_VQATestId INT NULL OUTPUT, @p_VQAHeaderId INT NULL, @p_DataName VARCHAR (100) NULL, @p_DataValue VARCHAR (25) NULL, @p_DataMin VARCHAR (25) NULL, @p_DataAvg VARCHAR (25) NULL, @p_DataMax VARCHAR (25) NULL, @p_NumSamples INT NULL, @p_TimeTaken DATETIME NULL, @p_UoM VARCHAR (15) NULL, @p_Use VARCHAR (1000) NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


