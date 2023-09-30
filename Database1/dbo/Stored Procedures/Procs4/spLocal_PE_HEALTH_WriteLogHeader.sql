CREATE PROCEDURE [dbo].[spLocal_PE_HEALTH_WriteLogHeader]
@ErrorCode INT NULL OUTPUT, @ErrorMessage NVARCHAR (255) NULL OUTPUT, @LogHeaderId INT NULL OUTPUT, @LogType NVARCHAR (255) NULL, @LogCategory NVARCHAR (255) NULL, @UserId INT NULL, @User NVARCHAR (255) NULL, @EntryOn DATETIME NULL, @Message NVARCHAR (MAX) NULL, @WithResultest BIT NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


