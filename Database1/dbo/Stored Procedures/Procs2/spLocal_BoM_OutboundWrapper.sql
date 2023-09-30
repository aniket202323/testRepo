CREATE PROCEDURE [dbo].[spLocal_BoM_OutboundWrapper]
@op_ErrorGUID UNIQUEIDENTIFIER NULL OUTPUT, @op_ValidationCode INT NULL OUTPUT, @op_ValidationMessage VARCHAR (MAX) NULL OUTPUT, @p_DebugFlag BIT NULL, @p_HTTPVerb VARCHAR (10) NULL, @p_CommandName VARCHAR (500) NULL, @p_BearerToken VARCHAR (MAX) NULL, @p_InputXML XML NULL, @op_OutputXML XML NULL OUTPUT, @op_HTTPResponseCode INT NULL OUTPUT
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


