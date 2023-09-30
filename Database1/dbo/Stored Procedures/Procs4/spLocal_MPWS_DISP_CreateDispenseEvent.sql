CREATE PROCEDURE [dbo].[spLocal_MPWS_DISP_CreateDispenseEvent]
@ErrorCode INT NULL OUTPUT, @ErrorMessage VARCHAR (255) NULL OUTPUT, @DispenseEvent VARCHAR (255) NULL OUTPUT, @DispenseEventId INT NULL OUTPUT, @PUId INT NULL, @UserName VARCHAR (255) NULL, @ProdId INT NULL, @DispenseQty FLOAT (53) NULL, @TareQty FLOAT (53) NULL, @Tare2Qty FLOAT (53) NULL, @UOM VARCHAR (255) NULL, @BOMFIId INT NULL, @ParentEventNum1 VARCHAR (50) NULL, @ParentEventQty1 FLOAT (53) NULL, @ParentEventNum2 VARCHAR (50) NULL, @ParentEventQty2 FLOAT (53) NULL, @ScalePUDesc VARCHAR (255) NULL, @DispenseMethod VARCHAR (255) NULL, @ESigName VARCHAR (50) NULL, @VerifierName VARCHAR (50) NULL, @Comment NVARCHAR (MAX) NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


