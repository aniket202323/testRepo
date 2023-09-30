CREATE PROCEDURE [dbo].[splocal_Nexus_CreateSamples]
@op_ErrorGUID UNIQUEIDENTIFIER NULL OUTPUT, @op_ValidationCode INT NULL OUTPUT, @op_ValidationMessage VARCHAR (MAX) NULL OUTPUT, @op_HTTPResponseCode INT NULL OUTPUT, @p_DebugFlag BIT NULL, @p_IsReprocess BIT NULL, @op_NexusSampleIds VARCHAR (MAX) NULL OUTPUT, @p_BatchUDEId INT NULL, @p_SPName VARCHAR (MAX) NULL, @p_PPId INT NULL, @p_NexusBatchId VARCHAR (50) NULL, @p_Copies INT NULL, @p_ReferenceKey VARCHAR (MAX) NULL, @p_SourcesPSourceLabel VARCHAR (50) NULL, @p_ManufactSubresource VARCHAR (50) NULL, @p_IsClosingSample BIT NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


