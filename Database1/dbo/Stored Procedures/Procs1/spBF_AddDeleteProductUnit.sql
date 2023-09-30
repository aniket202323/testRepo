CREATE PROCEDURE dbo.spBF_AddDeleteProductUnit
  @ProdId Int,
  @UnitId Int,
  @IsAdd Int,
  @UserId Int = 1
  AS
DECLARE @PropId Int, 	 @CharId INT
SELECT @PropId = Prop_Id,@CharId = Char_Id
 	 FROM Characteristics 
 	 WHERE prod_id = @ProdId
IF Not Exists(SELECT 1 FROM Products WHERE Prod_Id = @ProdId)
BEGIN
 	  	 SELECT Error = 'Error: Material Not Found '
 	  	 Return
END
IF Not Exists(SELECT 1 FROM Prod_Units WHERE PU_Id = @UnitId)
BEGIN
 	  	 SELECT Error = 'Error: Unit Not Found '
 	  	 Return
END
IF @IsAdd = 1
BEGIN
 	 IF Not Exists(SELECT 1 FROM PU_Products WHERE PU_Id = @UnitId and Prod_Id = @ProdId)
 	 BEGIN
 	  	  EXECUTE spEM_CreateUnitProd  @UnitId,@ProdId,@UserId
 	  	  IF @CharId Is Not Null
 	  	  	 EXECUTE spEM_PutUnitCharacteristic @UnitId,@ProdId,@PropId,@CharId,@UserId
 	 END
 	 SELECT  	  UnitId = b.PU_Id
 	 ,UnitDescription = b.PU_Desc
 	 FROM PU_Products a
 	 JOIN Prod_Units b on a.PU_Id = b.PU_Id
 	 WHERE a.Prod_Id = @ProdId and b.pu_id  = @UnitId
END
ELSE IF @IsAdd = 0
BEGIN
 	 IF  Exists(SELECT 1 FROM PU_Products WHERE PU_Id = @UnitId and Prod_Id = @ProdId)
 	 BEGIN
 	  	  EXECUTE spEM_DropUnitProd   @UnitId,@ProdId,@UserId
 	 END
 	 SELECT 'Success'
END
ELSE
BEGIN
 	 SELECT Error = 'Error: Invalid type (should be 0 or 1)'
END
