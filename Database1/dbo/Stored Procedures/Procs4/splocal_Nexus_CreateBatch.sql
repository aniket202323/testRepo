CREATE PROCEDURE [dbo].[splocal_Nexus_CreateBatch]
@op_ErrorGUID UNIQUEIDENTIFIER NULL OUTPUT, @op_ValidationCode INT NULL OUTPUT, @op_ValidationMessage VARCHAR (MAX) NULL OUTPUT, @op_HTTPResponseCode INT NULL OUTPUT, @p_DebugFlag BIT NULL, @p_IsReprocess BIT NULL, @p_TransactionType INT NULL, @op_NexusBatchId VARCHAR (MAX) NULL OUTPUT, @p_BatchUDEId INT NULL, @p_PPId INT NULL, @p_ReferenceKey VARCHAR (50) NULL, @p_ProductionSiteId VARCHAR (50) NULL, @p_ExpiryDt VARCHAR (50) NULL, @p_ReceivedDt VARCHAR (50) NULL, @p_ProductId VARCHAR (50) NULL, @p_PrecedingProductId VARCHAR (50) NULL, @p_PrecedingBatchId VARCHAR (256) NULL, @p_ManufacturingLine VARCHAR (50) NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


