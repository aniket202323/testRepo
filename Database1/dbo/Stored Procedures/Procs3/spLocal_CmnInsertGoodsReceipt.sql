CREATE PROCEDURE [dbo].[spLocal_CmnInsertGoodsReceipt]
@ProcessOrder VARCHAR (12) NULL, @StartTime DATETIME NULL, @EndTime DATETIME NULL, @EventID INT NULL, @ProdCode VARCHAR (18) NULL, @Quantity FLOAT (53) NULL, @UOM VARCHAR (30) NULL, @SAPLocation VARCHAR (18) NULL, @BatchNumber VARCHAR (20) NULL, @vendorLot VARCHAR (30) NULL, @ProcessSegmentId VARCHAR (30) NULL, @QualityStatus VARCHAR (30) NULL, @IsVendorLot BIT NULL, @proficyLocation VARCHAR (50) NULL, @ManualDebug BIT NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


