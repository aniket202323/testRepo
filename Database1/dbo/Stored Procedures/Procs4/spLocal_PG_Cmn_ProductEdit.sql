CREATE PROCEDURE [dbo].[spLocal_PG_Cmn_ProductEdit]
@op_ErrorGUID UNIQUEIDENTIFIER NULL OUTPUT, @op_ValidationCode INT NULL OUTPUT, @op_ValidationMessage VARCHAR (MAX) NULL OUTPUT, @p_DebugFlag BIT NULL, @op_ProdId INT NULL OUTPUT, @p_ProdFamilyId INT NULL, @p_ProdCode VARCHAR (25) NULL, @p_ProdDesc VARCHAR (50) NULL, @p_ExtendedInfo VARCHAR (255) NULL, @p_IsActiveProduct BIT NULL, @p_IsManufacturingProduct BIT NULL, @p_IsSalesProduct BIT NULL, @p_AliasForProduct INT NULL, @p_ProductChangeEsignatureLevel INT NULL, @p_EventEsignatureLevel INT NULL, @p_UseManufacturingProduct INT NULL, @p_Tag VARCHAR (50) NULL, @p_ExternalLink VARCHAR (255) NULL, @p_UserId INT NULL, @p_TransactionType INT NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


