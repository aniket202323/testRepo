CREATE PROCEDURE dbo.spBF_EquipmentSetSingleUnitOrder
  @UnitId Int,
  @UnitOrder Int,
  @UserId int = 1
  AS
Declare @Units Table (NewOrder int Identity(1,1),UnitId int,PlId Int,OldOrder int)
DECLARE @PLId Int
DECLARE @OldOrder Int
DECLARE @OrderBelow Int
DECLARE @MaxUnits Int
SELECT @PLId = PL_Id,@OldOrder = PU_Order FROM Prod_Units WHERE PU_Id = @UnitId
if @PLId Is Null
BEGIN
 	 SELECT Error = 'Error:  Unit Not Found'
 	 Return
END
if @PLId Is Null
BEGIN
 	 SELECT Error = 'Error:  Unit Not Found'
 	 Return
END
SELECT @MaxUnits = Count(*) FROM Prod_Units_Base WHERE PL_Id = @PLId
IF @UnitOrder is NULL 
 	 SET @UnitOrder = 1
IF @UnitOrder < 1 
 	 SET @UnitOrder = 1
IF  @UnitOrder > @MaxUnits
 	 SET @UnitOrder = @MaxUnits
if @OldOrder = @UnitOrder
BEGIN
 	 GOTO SuccessContinue
END
IF Not exists(SELECT 1 FROM  Prod_Units WHERE PL_Id = @PLId and PU_Order = @UnitOrder)
 	 AND Not EXISTS(SELECT 1 FROM  Prod_Units WHERE PL_Id = @PLId and pu_Id != @UnitId and PU_Order is null)
BEGIN
 	 Update Prod_Units_Base set PU_Order = @UnitOrder
 	  	 WHERE PU_Id = @UnitId
 	 GOTO SuccessContinue
END
SET @OrderBelow = @UnitOrder - 1
--select @OrderBelow
IF @OrderBelow > 0
BEGIN
 	 SET RowCount @OrderBelow
 	 INSERT INTO @Units(UnitId,PlId,OldOrder)
 	  	 SELECT PU_Id,PL_Id,pu_Order
 	  	  	 FROM Prod_Units_Base
 	  	  	 WHERE PL_Id = @PLId and PU_id <> @UnitId 
 	  	  	 ORDER BY PU_order,PU_Desc
 	 INSERT INTO @Units(UnitId,PlId,OldOrder)
 	  	 SELECT PU_Id,PL_Id,pu_Order
 	  	  	 FROM Prod_Units_Base
 	  	  	 WHERE  PU_id = @UnitId 
 	 SET RowCount 0
END
IF @UnitOrder = 1
BEGIN
 	 INSERT INTO @Units(UnitId,PlId,OldOrder)
 	  	 SELECT PU_Id,PL_Id,pu_Order
 	  	  	 FROM Prod_Units_Base
 	  	  	 WHERE  PU_id = @UnitId 
END
INSERT INTO @Units(UnitId,PlId,OldOrder)
 	 SELECT PU_Id,PL_Id,pu_Order
 	  	 FROM Prod_Units_Base
 	  	 WHERE PL_Id = @PLId and PU_id not in (SELECT UnitId from @Units)
 	  	 ORDER BY PU_order,PU_Desc
Update Prod_Units_Base set PU_Order = neworder
 	 FROM Prod_Units_Base a
 	 Join @Units b on a.PU_Id = b.UnitId 
 	 WHERE b.NewOrder <> a.PU_Order or a.PU_Order is null
SuccessContinue:
 	 SELECT UnitName = PU_Desc, PU_Id = PU_Id, PU_Order = coalesce(PU_Order,0)
 	 FROM Prod_Units_Base PUB
 	 WHERE PUB.PL_Id = @PLId
 	 ORDER BY PUB.PU_Order
