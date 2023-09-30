CREATE PROCEDURE [dbo].[spLocal_PG_Cmn_CommentEdit]
@op_ErrorGUID UNIQUEIDENTIFIER NULL OUTPUT, @op_ValidationCode INT NULL OUTPUT, @op_ValidationMessage VARCHAR (MAX) NULL OUTPUT, @p_DebugFlag BIT NULL, @p_UserId INT NULL, @op_CommentId INT NULL OUTPUT, @p_CommentText VARCHAR (MAX) NULL, @p_CommentTimeStamp DATETIME NULL, @p_TopOfChainId INT NULL, @p_CommentTypeId INT NULL, @p_WriteDirect BIT NULL, @p_SourceKeyId INT NULL, @p_SourceTableName VARCHAR (100) NULL, @p_TransactionType INT NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


