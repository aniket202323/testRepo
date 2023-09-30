CREATE PROCEDURE [dbo].[spLocal_PG_Cmn_ProductPropertyEdit]
@op_ErrorGUID UNIQUEIDENTIFIER NULL OUTPUT, @op_ValidationCode INT NULL OUTPUT, @op_ValidationMessage VARCHAR (MAX) NULL OUTPUT, @p_DebugFlag BIT NULL, @op_PropId INT NULL OUTPUT, @p_PropDesc VARCHAR (50) NULL, @p_AutoSyncChars BIT NULL, @p_SecurityGroupId INT NULL, @p_PropertyOrder INT NULL, @p_PropertyTypeId INT NULL, @p_ProdUnitId INT NULL, @p_DefaultSize REAL NULL, @p_IsUnitSpecific BIT NULL, @p_IsHidden BIT NULL, @p_Tag VARCHAR (50) NULL, @p_EngUnits VARCHAR (50) NULL, @p_ExternalLink VARCHAR (255) NULL, @p_ProductFamilyId INT NULL, @p_UserId INT NULL, @p_TransactionType INT NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


