CREATE PROCEDURE [dbo].[spLocal_WAMAS_IncomingRequestCancellation]
@op_ErrorGUID UNIQUEIDENTIFIER NULL OUTPUT, @op_ValidationCode INT NULL OUTPUT, @op_ValidationMessage VARCHAR (MAX) NULL OUTPUT, @p_DebugFlag BIT NULL, @p_InputXML XML NULL, @p_UserId INT NULL, @op_OutputXML XML NULL OUTPUT, @op_HTTPStatusCode INT NULL OUTPUT
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


