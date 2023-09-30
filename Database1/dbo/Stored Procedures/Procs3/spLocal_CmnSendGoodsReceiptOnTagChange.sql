CREATE PROCEDURE [dbo].[spLocal_CmnSendGoodsReceiptOnTagChange]
@ReturnStatus INT NULL OUTPUT, @ReturnMessage VARCHAR (255) NULL OUTPUT, @JumptoTime DATETIME NULL OUTPUT, @EC_Id INT NULL, @Reserved1 VARCHAR (30) NULL, @Reserved2 VARCHAR (30) NULL, @Reserved3 VARCHAR (30) NULL, @TriggerTagNum INT NULL, @TriggerPrevValue VARCHAR (30) NULL, @TriggerNewValue VARCHAR (30) NULL, @TriggerPrevTime DATETIME NULL, @TriggerNewTime DATETIME NULL, @TTPrevValue VARCHAR (50) NULL, @TTNewValue VARCHAR (50) NULL, @TTPrevTime DATETIME NULL, @TTNewTime DATETIME NULL, @VendorLotPrevValue VARCHAR (50) NULL, @VendorLotNewValue VARCHAR (50) NULL, @VendorLotPrevTime DATETIME NULL, @VendorLotNewTime DATETIME NULL, @GCASPrevValue VARCHAR (30) NULL, @GCASNewValue VARCHAR (30) NULL, @GCASPrevTime DATETIME NULL, @GCASNewTime DATETIME NULL, @QtyPrevValue VARCHAR (30) NULL, @QtyNewValue VARCHAR (30) NULL, @QtyPrevTime DATETIME NULL, @QtyNewTime DATETIME NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


