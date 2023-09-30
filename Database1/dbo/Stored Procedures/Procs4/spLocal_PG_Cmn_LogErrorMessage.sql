CREATE PROCEDURE [dbo].[spLocal_PG_Cmn_LogErrorMessage]
@p_uidErrorId UNIQUEIDENTIFIER NULL, @p_intNestingLevel INT NULL, @p_vchNestedObjectName VARCHAR (256) NULL, @p_vchObjectName VARCHAR (256) NULL, @p_vchErrorSection VARCHAR (100) NULL, @p_nvchErrorMessage NVARCHAR (2048) NULL, @p_intErrorSeverity INT NULL, @p_intErrorState INT NULL, @p_intErrorCode INT NULL, @p_bitPrimaryObjectFlag BIT NULL, @p_intErrorSeverityLevel INT NULL, @p_intKeyId INT NULL, @p_intTableId INT NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


