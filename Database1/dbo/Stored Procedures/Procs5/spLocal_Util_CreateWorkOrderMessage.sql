CREATE PROCEDURE [dbo].[spLocal_Util_CreateWorkOrderMessage]
@ErrorCode INT NULL OUTPUT, @ErrorMessage VARCHAR (1000) NULL OUTPUT, @MasterBOMFormulationId INT NULL, @PathId INT NULL, @ProcessOrder VARCHAR (255) NULL, @ProdId INT NULL, @BOMId INT NULL, @StartTime DATETIME NULL, @Duration INT NULL, @BatchNumber VARCHAR (255) NULL, @Qty FLOAT (53) NULL, @ExpirationDate VARCHAR (8) NULL, @Comment VARCHAR (MAX) NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


