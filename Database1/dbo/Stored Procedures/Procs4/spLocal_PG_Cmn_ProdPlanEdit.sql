CREATE PROCEDURE [dbo].[spLocal_PG_Cmn_ProdPlanEdit]
@op_uidErrorId UNIQUEIDENTIFIER NULL OUTPUT, @op_vchErrorMessage VARCHAR (1000) NULL OUTPUT, @p_bitWriteDirect BIT NULL, @p_intTransType INT NULL, @p_intUserId INT NULL, @op_intPPId INT NULL OUTPUT, @p_intPathId INT NULL, @p_intCommentId INT NULL, @p_intProdId INT NULL, @op_intImpliedSequence INT NULL OUTPUT, @p_intPPStatusId INT NULL, @p_intPPTypeId INT NULL, @p_intSourcePPId INT NULL, @p_intParentPPId INT NULL, @p_intControlType TINYINT NULL, @p_dtmForecastStartTime DATETIME NULL, @p_dtmForecastEndTime DATETIME NULL, @op_dtmEntryOn DATETIME NULL OUTPUT, @p_fltForecastQuantity FLOAT (53) NULL, @p_fltProductionRate FLOAT (53) NULL, @p_fltAdjustedQuantity FLOAT (53) NULL, @p_vchBlockNumber VARCHAR (50) NULL, @p_vchProcessOrder VARCHAR (50) NULL, @p_intBOMFormulationId BIGINT NULL, @p_vchUserGeneral1 VARCHAR (255) NULL, @p_vchUserGeneral2 VARCHAR (255) NULL, @p_vchUserGeneral3 VARCHAR (255) NULL, @p_vchExtendedInfo VARCHAR (255) NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


