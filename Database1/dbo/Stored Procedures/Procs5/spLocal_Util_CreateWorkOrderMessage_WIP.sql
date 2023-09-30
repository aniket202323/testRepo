CREATE PROCEDURE [dbo].[spLocal_Util_CreateWorkOrderMessage_WIP]
@ErrorCode INT NULL OUTPUT, @ErrorMessage NVARCHAR (1000) NULL OUTPUT, @MasterBOMFormulationId INT NULL, @PathId INT NULL, @ProcessOrder NVARCHAR (255) NULL, @ProdId INT NULL, @BOMId INT NULL, @StartTime DATETIME NULL, @Duration INT NULL, @BatchNumber NVARCHAR (255) NULL, @Qty FLOAT (53) NULL, @ExpirationDate NVARCHAR (8) NULL, @Comment NVARCHAR (MAX) NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


