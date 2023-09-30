CREATE PROCEDURE [dbo].[splocal_PrIME_EditOpenRequest]
@op_ErrorGUID UNIQUEIDENTIFIER NULL OUTPUT, @op_ValidationCode INT NULL OUTPUT, @op_ValidationMessage VARCHAR (MAX) NULL OUTPUT, @p_DebugFlag BIT NULL, @p_TransactionType INT NULL, @p_RequestId VARCHAR (50) NULL, @p_PrIMEReturnCode INT NULL, @p_RequestTime DATETIME NULL, @p_ResponseTime DATETIME NULL, @p_LocationId VARCHAR (50) NULL, @p_CurrentLocation VARCHAR (50) NULL, @p_PlantID VARCHAR (50) NULL, @p_WarehouseID VARCHAR (50) NULL, @p_ULID VARCHAR (50) NULL, @p_Batch VARCHAR (50) NULL, @p_ProcessOrder VARCHAR (50) NULL, @p_PrimaryGCas VARCHAR (50) NULL, @p_AlternateGCas VARCHAR (50) NULL, @p_GCas VARCHAR (50) NULL, @p_Quantity DECIMAL (19, 5) NULL, @p_UoM VARCHAR (50) NULL, @p_Status VARCHAR (50) NULL, @p_EstimatedDeliveryTime DATETIME NULL, @p_LastUpdatedTime DATETIME NULL, @p_UserId INT NULL, @p_EventId INT NULL, @p_Comment VARCHAR (8000) NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


