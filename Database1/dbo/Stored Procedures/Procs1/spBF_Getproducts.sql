CREATE PROCEDURE [dbo].[spBF_Getproducts]
  @FamilyId Int  = Null,
  @UnitId Int = Null,
  @PlantCSV nvarchar(255) = NULL
  AS
DECLARE @ProdFamilyDesc nVarChar(100)
DECLARE @SpecId Int
DECLARE @SpecDesc nVarChar(100)
DECLARE @PropId Int
DECLARE @Now DateTime
SET @SpecDesc = 'Rate'
SET @Now = GETUTCDATE()
SET @Now = DATEADD(millisecond,-DatePart(millisecond,@Now),@Now)
SET @Now = DATEADD(SECOND,2,@Now)
SET @Now = dbo.fnServer_CmnConvertToDbTime(@Now,'UTC')
-----------------------------Return all products for Departments a user has OpsLeader on-----------
IF @PlantCSV is NOT NULL
BEGIN
 	  SELECT MaterialId = a.Prod_Id,
  	    	     MaterialDescription = Prod_Desc,
  	    	     MaterialCode   = Prod_Code,
  	    	     Rate = Target
  	  FROM Products a
  	  JOIN Product_Family b ON a.Product_Family_Id = b.Product_Family_Id
  	  JOIN Product_Properties c on b.Product_Family_Id = c.Product_Family_Id
  	  JOIN Characteristics d on a.Prod_Id = d.Prod_Id
  	  JOIN Specifications e on d.Prop_Id = e.Prop_Id
  	  LEFT JOIN Active_Specs f on f.Spec_Id = e.Spec_Id and f.char_id = d.Char_Id and Effective_Date < @Now and (Expiration_Date > = @Now or Expiration_Date is null)
  	  WHERE b.Product_Family_Desc In (SELECT * from fnLocal_CmnParseList(@PlantCSV,',')) and a.Prod_Id > 1
  	  Order by Prod_Desc
 	  RETURN
END
IF @FamilyId is Null
BEGIN
  	  SELECT @FamilyId = Product_Family_Id  
  	  FROM Product_Family f
  	  JOIN Departments d on f.Product_Family_Desc = d.dept_desc
  	  JOIN Prod_lines pl on d.dept_id = pl.dept_id
  	  JOIN Prod_units pu on pl.pl_id = pu.pl_id
  	  WHERE pu.pu_id = @UnitId
END
IF @FamilyId is Null
BEGIN
  	  SELECT Error = 'Error: Material Family not found'
  	  RETURN
END
SELECT @PropId = min(Prop_Id) FROM Product_Properties a WHERE a.Product_Family_Id  = @FamilyId
IF @PropId is Null
BEGIN
  	  SELECT Error = 'Error: Material Rate Property not found'
  	  RETURN
END 
SELECT @SpecId = Spec_Id FROM Specifications a WHERE a.Spec_Desc = @SpecDesc and a.Prop_Id = @PropId 
IF @SpecId is Null
BEGIN
  	  SELECT Error = 'Error: Material Rate Spec not found'
  	  RETURN
END
---------------------------Return all products for a FamilyID ------------
IF  @UnitId Is Null 
BEGIN
  	  SELECT MaterialId = a.Prod_Id,
  	    	     MaterialDescription = Prod_Desc,
  	    	     MaterialCode   = Prod_Code,
  	    	     Rate = Target
  	  FROM Products a
  	  JOIN Product_Family b ON a.Product_Family_Id = b.Product_Family_Id
  	  LEFT JOIN Characteristics c on c.Prod_Id = a.Prod_Id
  	  LEFT JOIN Active_Specs d on d.Spec_Id = @SpecId and d.char_id = c.Char_Id and Effective_Date < @Now and (Expiration_Date > = @Now or Expiration_Date is null)
  	  WHERE b.Product_Family_Id = @FamilyId and a.Prod_Id > 1
  	  Order by Prod_Desc
END
ELSE
---------------------------Return all products for a Unit ------------
BEGIN
  	  SELECT MaterialId = a.Prod_Id,
  	    	     MaterialDescription = Prod_Desc,
  	    	     MaterialCode   = Prod_Code,
  	    	     Rate = Target
  	  FROM Products a
  	  JOIN PU_Products e on e.Prod_Id = a.Prod_Id and e.PU_Id = @UnitId 
  	  JOIN Product_Family b ON a.Product_Family_Id = b.Product_Family_Id
  	  LEFT JOIN Characteristics c on c.Prod_Id = a.Prod_Id
  	  LEFT JOIN Active_Specs d on d.Spec_Id = @SpecId and d.char_id = c.Char_Id and Effective_Date < @Now and (Expiration_Date > = @Now or Expiration_Date is null)
  	  WHERE a.Prod_Id > 1
  	  Order by Prod_Desc
END
