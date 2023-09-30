CREATE PROCEDURE [dbo].[spLocal_PG_Cmn_ProductGroupEdit]
@op_ErrorGUID UNIQUEIDENTIFIER NULL OUTPUT, @op_ValidationCode INT NULL OUTPUT, @op_ValidationMessage VARCHAR (MAX) NULL OUTPUT, @p_DebugFlag BIT NULL, @op_ProductGrpId INT NULL OUTPUT, @p_ProductGrpDesc VARCHAR (50) NULL, @p_Tag VARCHAR (50) NULL, @p_ExternalLink VARCHAR (255) NULL, @p_UserId INT NULL, @p_TransactionType INT NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


