CREATE PROCEDURE [dbo].[spLocal_Util_UpdateWorkOrderMessage]
@ErrorCode INT NULL OUTPUT, @ErrorMessage VARCHAR (1000) NULL OUTPUT, @PPId INT NULL, @StartTime DATETIME NULL, @Duration INT NULL, @ExpirationDate VARCHAR (8) NULL, @Qty FLOAT (53) NULL, @ConfirmedQty FLOAT (53) NULL, @Comment NVARCHAR (MAX) NULL, @IsTeco INT NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


