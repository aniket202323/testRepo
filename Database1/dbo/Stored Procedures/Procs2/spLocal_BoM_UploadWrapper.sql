CREATE PROCEDURE [dbo].[spLocal_BoM_UploadWrapper]
@op_ErrorGUID UNIQUEIDENTIFIER NULL OUTPUT, @op_ValidationCode INT NULL OUTPUT, @op_ValidationMessage VARCHAR (MAX) NULL OUTPUT, @p_DebugFlag BIT NULL, @p_InputXML XML NULL, @p_UserId INT NULL, @op_OutputXML XML NULL OUTPUT, @op_HTTPStatusCode INT NULL OUTPUT, @p_ReprocessFlag BIT NULL, @p_BearerToken VARCHAR (MAX) NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


