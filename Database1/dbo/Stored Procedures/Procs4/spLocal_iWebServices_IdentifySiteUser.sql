CREATE PROCEDURE [dbo].[spLocal_iWebServices_IdentifySiteUser]
@op_ErrorGUID UNIQUEIDENTIFIER NULL OUTPUT, @op_ValidationCode INT NULL OUTPUT, @op_ValidationMessage VARCHAR (MAX) NULL OUTPUT, @p_DebugFlag BIT NULL, @p_IsSiteUser BIT NULL, @p_GroupNames [dbo].[GroupNameTableType] NULL READONLY, @p_UserName VARCHAR (50) NULL, @op_UserAuthorized BIT NULL OUTPUT
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


