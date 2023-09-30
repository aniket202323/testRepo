CREATE PROCEDURE [dbo].[splocal_Nexus_CreateSamplesFromList]
@op_ErrorGUID UNIQUEIDENTIFIER NULL OUTPUT, @op_ValidationCode INT NULL OUTPUT, @op_ValidationMessage VARCHAR (MAX) NULL OUTPUT, @p_DebugFlag BIT NULL, @p_PUId INT NULL, @p_PPId INT NULL, @p_SampleTypes [dbo].[udtLocal_PG_NexusSampleTypes] NULL READONLY, @p_EventSubtypeId INT NULL, @p_BatchUDEId INT NULL, @p_NexusBatchId INT NULL, @p_IsClosingSample BIT NULL, @p_ManufactSubresource VARCHAR (50) NULL, @p_PrevGCAS VARCHAR (25) NULL, @p_NextGCAS VARCHAR (25) NULL, @p_PrevComponentBatch VARCHAR (25) NULL, @p_NextComponentBatch VARCHAR (25) NULL, @p_Note VARCHAR (MAX) NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


