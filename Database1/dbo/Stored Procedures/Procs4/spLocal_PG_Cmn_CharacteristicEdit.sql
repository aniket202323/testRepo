CREATE PROCEDURE [dbo].[spLocal_PG_Cmn_CharacteristicEdit]
@op_ErrorGUID UNIQUEIDENTIFIER NULL OUTPUT, @op_ValidationCode INT NULL OUTPUT, @op_ValidationMessage VARCHAR (MAX) NULL OUTPUT, @p_DebugFlag BIT NULL, @op_CharId INT NULL OUTPUT, @p_CharDesc VARCHAR (50) NULL, @p_PropId INT NULL, @p_SecurityGroupId INT NULL, @p_ProdId INT NULL, @p_DerivedFromParent INT NULL, @p_DerivedFromException INT NULL, @p_NextException INT NULL, @p_CharacteristicType INT NULL, @p_ExceptionType INT NULL, @p_ExtendedInfo VARCHAR (255) NULL, @p_Tag VARCHAR (50) NULL, @p_CharCode VARCHAR (50) NULL, @p_ExternalLink VARCHAR (255) NULL, @p_UserId INT NULL, @p_TransactionType INT NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


