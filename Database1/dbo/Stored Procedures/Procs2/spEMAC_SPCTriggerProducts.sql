Create Procedure dbo.spEMAC_SPCTriggerProducts
@ATSRDId int,
@TransType int,
@ProdId Int,
@UserId int
AS
If @TransType = 0 -- Read
BEGIN
 	 SELECT ASDP_Id,Prod_Id
 	 FROM Alarm_SPC_Disabled_Products
 	 WHERE ATSRD_Id = @ATSRDId
END
If @TransType = 1 and @ProdId Is Not Null -- Add
BEGIN
 	 IF Not Exists(SELECT 1 FROM Alarm_SPC_Disabled_Products
 	 WHERE ATSRD_Id = @ATSRDId and Prod_Id = @ProdId)
 	  	 INSERT INTO Alarm_SPC_Disabled_Products(Prod_Id,ATSRD_Id)
 	  	  	 VALUES (@ProdId,@ATSRDId)
 	 
END
If @TransType = 3 and @ProdId Is Not Null -- Add
BEGIN
 	 DELETE FROM  Alarm_SPC_Disabled_Products WHERE Prod_Id = @ProdId and ATSRD_Id = @ATSRDId
END
