CREATE PROCEDURE [dbo].[spLocal_PG_Cmn_SpecificationEdit]
@op_ErrorGUID UNIQUEIDENTIFIER NULL OUTPUT, @op_ValidationCode INT NULL OUTPUT, @op_ValidationMessage VARCHAR (MAX) NULL OUTPUT, @p_DebugFlag BIT NULL, @p_UserId INT NULL, @p_TransactionType INT NULL, @op_SpecId INT NULL OUTPUT, @p_SpecDesc VARCHAR (50) NULL, @p_SecurityGroupId INT NULL, @p_PropId INT NULL, @p_DataTypeId INT NULL, @p_SpecPrecision INT NULL, @op_SpecOrder INT NULL OUTPUT, @p_Tag VARCHAR (50) NULL, @p_EngUnits VARCHAR (50) NULL, @p_SpecificationTypeId INT NULL, @p_VarId INT NULL, @p_UnitConversion FLOAT (53) NULL, @p_ExtendedInfo VARCHAR (255) NULL, @p_ExternalLink VARCHAR (255) NULL, @p_ParentId INT NULL, @p_ArraySize INT NULL, @p_RetentionLimit INT NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


