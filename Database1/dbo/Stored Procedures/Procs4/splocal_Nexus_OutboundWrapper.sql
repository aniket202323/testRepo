CREATE PROCEDURE [dbo].[splocal_Nexus_OutboundWrapper]
@op_ErrorGUID UNIQUEIDENTIFIER NULL OUTPUT, @op_ValidationCode INT NULL OUTPUT, @op_ValidationMessage VARCHAR (MAX) NULL OUTPUT, @p_DebugFlag BIT NULL, @p_Endpoint VARCHAR (200) NULL, @p_CommandName VARCHAR (100) NULL, @p_HTTPVerb VARCHAR (5) NULL, @p_XML XML NULL, @op_XML XML NULL OUTPUT, @op_HTTPResponseCode INT NULL OUTPUT, @op_RawOutput VARCHAR (MAX) NULL OUTPUT
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


