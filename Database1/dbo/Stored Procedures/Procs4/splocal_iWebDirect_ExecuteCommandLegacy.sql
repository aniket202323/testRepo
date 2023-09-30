CREATE PROCEDURE [dbo].[splocal_iWebDirect_ExecuteCommandLegacy]
@op_ErrorGUID UNIQUEIDENTIFIER NULL OUTPUT, @op_ValidationCode INT NULL OUTPUT, @op_ValidationMessage VARCHAR (MAX) NULL OUTPUT, @p_DebugFlag BIT NULL, @p_InputXML XML NULL, @p_HTTPVerb VARCHAR (10) NULL, @p_CommandName VARCHAR (50) NULL, @p_ExternalComponentName VARCHAR (50) NULL, @p_RemoteIP VARCHAR (16) NULL, @p_RemoteHostName VARCHAR (256) NULL, @p_Username VARCHAR (50) NULL, @op_OutputXML XML NULL OUTPUT, @op_HttpStatusCode INT NULL OUTPUT
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


