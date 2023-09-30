CREATE PROCEDURE [dbo].[spLocal_CreateProductChangeEvent]
@Success INT NULL OUTPUT, @ErrorMsg VARCHAR (255) NULL OUTPUT, @JumpToTime DATETIME NULL OUTPUT, @ECId INT NULL, @Reserved1 VARCHAR (30) NULL, @Reserved2 VARCHAR (30) NULL, @Reserved3 VARCHAR (30) NULL, @ChangedTagNum INT NULL, @ChangedPrevValue VARCHAR (30) NULL, @ChangedNewValue VARCHAR (30) NULL, @ChangedPrevTime DATETIME NULL, @ChangedNewTime DATETIME NULL, @ProductPrevValue VARCHAR (30) NULL, @ProductNewValue VARCHAR (30) NULL, @ProductPrevTime DATETIME NULL, @ProductNewTime DATETIME NULL, @DowntimePrevValue VARCHAR (30) NULL, @DowntimeNewValue VARCHAR (30) NULL, @DowntimePrevTime DATETIME NULL, @DowntimeNewTime DATETIME NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


