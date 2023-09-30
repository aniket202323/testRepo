CREATE PROCEDURE [dbo].[spServer_DBMgrUpdProdPlan_BAK_New]
@PPId INT NULL OUTPUT, @TransType INT NULL, @TransNum INT NULL, @PathId INT NULL, @CommentId INT NULL, @ProdId INT NULL, @ImpliedSequence INT NULL OUTPUT, @PPStatusId INT NULL, @PPTypeId INT NULL, @SourcePPId INT NULL, @UserId INT NULL, @ParentPPId INT NULL, @ControlType TINYINT NULL, @ForecastStartTime DATETIME NULL, @ForecastEndTime DATETIME NULL, @EntryOn DATETIME NULL OUTPUT, @ForecastQuantity FLOAT (53) NULL, @ProductionRate FLOAT (53) NULL, @AdjustedQuantity FLOAT (53) NULL, @BlockNumber VARCHAR (50) NULL, @ProcessOrder VARCHAR (50) NULL, @TransactionTime DATETIME NULL, @Misc1 INT NULL, @Misc2 INT NULL, @Misc3 INT NULL, @Misc4 INT NULL, @BOMFormulationId BIGINT NULL, @UserGeneral1 VARCHAR (255) NULL, @UserGeneral2 VARCHAR (255) NULL, @UserGeneral3 VARCHAR (255) NULL, @ExtendedInfo VARCHAR (255) NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


