CREATE PROCEDURE [dbo].[spLocal_AQRS_GetRelevantVariables]
@op_ErrorGUID UNIQUEIDENTIFIER NULL OUTPUT, @op_ValidationCode INT NULL OUTPUT, @op_ValidationMessage VARCHAR (MAX) NULL OUTPUT, @p_DebugFlag BIT NULL, @p_LineIds NVARCHAR (MAX) NULL, @p_ProdIds NVARCHAR (MAX) NULL, @p_StartTime DATETIME NULL, @p_EndTime DATETIME NULL, @p_Mode INT NULL, @p_VarIds NVARCHAR (MAX) NULL, @p_OverrideVarId INT NULL, @p_OverrideValues NVARCHAR (MAX) NULL, @p_OverrideLimits NVARCHAR (MAX) NULL, @p_OnlySpecs BIT NULL, @p_TzFlags NVARCHAR (MAX) NULL, @p_IsCalcs NVARCHAR (MAX) NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


