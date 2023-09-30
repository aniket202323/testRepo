CREATE PROCEDURE [dbo].[splocal_Nexus_CreateSampleReport]
@op_ErrorGUID UNIQUEIDENTIFIER NULL OUTPUT, @op_ValidationCode INT NULL OUTPUT, @op_ValidationMessage VARCHAR (MAX) NULL OUTPUT, @op_HTTPResponseCode INT NULL OUTPUT, @p_DebugFlag BIT NULL, @p_IsReprocess BIT NULL, @p_ProductCode VARCHAR (50) NULL, @p_NexusBatchId VARCHAR (255) NULL, @p_ProcessOrder VARCHAR (50) NULL, @p_BatchUDEId INT NULL, @p_SystemId VARCHAR (10) NULL, @p_Timezone VARCHAR (50) NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


