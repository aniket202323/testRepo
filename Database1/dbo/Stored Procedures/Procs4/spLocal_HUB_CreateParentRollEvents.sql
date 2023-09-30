CREATE PROCEDURE [dbo].[spLocal_HUB_CreateParentRollEvents]
@op_ErrorGUId UNIQUEIDENTIFIER NULL OUTPUT, @op_ValidationCode INT NULL OUTPUT, @op_ValidationMessage VARCHAR (MAX) NULL OUTPUT, @p_DebugFlag BIT NULL, @op_OutputValue VARCHAR (25) NULL OUTPUT, @op_OutputPayload VARCHAR (MAX) NULL OUTPUT, @p_TurnoverEventId INT NULL, @p_RollVarId INT NULL, @p_RollPUId INT NULL, @p_DefaultStatus VARCHAR (25) NULL, @p_ULIDHeader VARCHAR (25) NULL, @p_ULIDReserved INT NULL, @p_PRIDHeader VARCHAR (25) NULL, @p_SafetyLimit INT NULL, @p_DowntimePUId INT NULL, @p_PRIDVarId INT NULL, @p_FalseStatus VARCHAR (25) NULL, @p_QCSWeightPUId INT NULL, @p_QCSWeightVarId INT NULL, @p_TurnoverWeightOfficialVarId INT NULL, @p_TurnoverWeight FLOAT (53) NULL, @p_TurnoverDiameter FLOAT (53) NULL, @p_AliasValuesVarId INT NULL, @p_AliasValuesByRatioVarId INT NULL, @p_AliasValuesByPositionVarId INT NULL, @p_TeardownWeightVarId INT NULL, @p_FireNextCount INT NULL, @p_IsManualTurnover BIT NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


