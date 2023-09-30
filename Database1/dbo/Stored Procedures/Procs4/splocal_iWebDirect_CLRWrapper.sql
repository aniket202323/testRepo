CREATE PROCEDURE [dbo].[splocal_iWebDirect_CLRWrapper]
@op_ErrorGUID UNIQUEIDENTIFIER NULL OUTPUT, @op_ValidationCode INT NULL OUTPUT, @op_ValidationMessage VARCHAR (MAX) NULL OUTPUT, @p_DebugFlag BIT NULL, @op_TransactionId INT NULL OUTPUT, @p_InputPayload VARCHAR (MAX) NULL, @p_URL VARCHAR (500) NULL, @p_ExternalComponentName VARCHAR (50) NULL, @p_CommandName VARCHAR (500) NULL, @p_HTTPVerb VARCHAR (10) NULL, @p_UserName VARCHAR (100) NULL, @p_Password VARCHAR (MAX) NULL, @p_DataFormat VARCHAR (10) NULL, @p_ContentType VARCHAR (50) NULL, @op_OutputPayload VARCHAR (MAX) NULL OUTPUT, @op_HTTPResponseCode INT NULL OUTPUT, @op_Cookies VARCHAR (5000) NULL OUTPUT, @p_LogPayload BIT NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


