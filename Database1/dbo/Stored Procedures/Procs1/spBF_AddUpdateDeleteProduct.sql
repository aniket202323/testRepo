CREATE PROCEDURE dbo.spBF_AddUpdateDeleteProduct
  @MaterialDescription  nvarchar(50),
  @MaterialCode nvarchar(25),
  @MaterialId Int,
  @TargetRate nvarchar(25),
  @TransactionType Int = 0,
  @UserId Int = 1,
  @PlantCSV nvarchar(255) = NULL
  AS
/*
@TransactionType
1 - Add
2 - Update
3 - Delete
*/
DECLARE @PropId Int
DECLARE @CharId Int
DECLARE @SpecId Int
DECLARE @ProdChanged Int
DECLARE @CodeChanged Int
DECLARE @SpecChanged Int
DECLARE @FamilyId Int
DECLARE @ProdFamilyDesc nVarChar(100) 
DECLARE @PropDesc nVarChar(100) 
DECLARE @SpecDesc nVarChar(100)
DECLARE @Target nvarchar(25)
DECLARE @AsId Int 
DECLARE @TransId Int
DECLARE @TransDesc nVarChar(100)
DECLARE @Now DateTime
DECLARE @OldProdCode  	  nVarChar(100)
DECLARE @OldProd  	      nVarChar(100)
DECLARE @NextId Int
DECLARE @DeptID Int
DECLARE @PlantCode nvarchar(50)
DECLARE @authorizedPlants table(
 	 PlantCode nvarchar(50)
 	 )
SELECT @MaterialDescription = ltrim(rtrim(@MaterialDescription))
SELECT @MaterialCode = ltrim(rtrim(@MaterialCode))
SELECT @TargetRate = ltrim(rtrim(@TargetRate))
IF @MaterialCode = '' SELECT @MaterialCode = Null
IF @MaterialDescription = '' SELECT @MaterialDescription = Null
IF @TargetRate = '' SELECT @TargetRate = Null
SELECT @Now = GETUTCDATE()
SET @Now = DATEADD(millisecond,-DatePart(millisecond,@Now),@Now)
SET @Now = DATEADD(SECOND,2,@Now)
SET @Now = dbo.fnServer_CmnConvertToDbTime(@Now,'UTC')
--PlantCSV contains a single valid PlantCode if adding a product
IF @TransactionType =1
BEGIN
 	 SET 	 @Plantcode  = @PlantCSV
END
--parse PlantCSV for authorized plants if updating an existing product
IF @TransactionType in (2,3)
BEGIN
 	 INSERT INTO @authorizedPlants
 	 SELECT * from fnLocal_CmnParseList(@PlantCSV, ',')
 	 SELECT TOP 1 @PlantCode = f.Product_Family_Desc
 	 FROM Products p
 	 INNER JOIN Product_Family f on p.Product_Family_Id = f.Product_Family_Id
 	 INNER JOIN @authorizedPlants a on f.Product_Family_Desc = a.PlantCode
 	 WHERE p.Prod_Id = @MaterialId
 	 IF @PlantCode is NULL
 	 BEGIN 
 	  	 SELECT Error = 'Not Authorized to update: ' + @MaterialCode
 	  	 RETURN
 	 END 
END
SET @ProdFamilyDesc = @PlantCode
SET @PropDesc = @PlantCode
SET @SpecDesc = 'Rate'
SET @UserId = 1
SET @ProdChanged = 0
SET @CodeChanged = 0
SET @SpecChanged = 0
SELECT @DeptID = Dept_ID FROM Departments WHERE Dept_Desc = @ProdFamilyDesc
IF @DeptID is NULL
BEGIN
 	 SELECT Error = 'No Plant found for PlantCode:' + @ProdFamilyDesc
 	 RETURN
END 
SELECT @FamilyId = Product_Family_Id  FROM Product_Family WHERE Product_Family_Desc = @ProdFamilyDesc --enforce one Property/Family per Department.
IF @FamilyId is Null
BEGIN
  	 EXECUTE spEM_CreateProductFamily  @ProdFamilyDesc,@UserId,@FamilyId output
END
SELECT @PropId = Prop_Id FROM Product_Properties a WHERE a.Prop_Desc = @PropDesc
IF @PropId is Null
BEGIN
  	  EXECUTE spEM_CreateProp @PropDesc,1,@userId,@PropId Output
  	  EXECUTE spEM_PutPropertyData  @propId,@FamilyId,1,@UserId
END
IF @MaterialCode is null
BEGIN
  	  SELECT  @NextId = Max(prod_Id) + 1 FROM Products
  	  IF @NextId Is Null
  	    	  SET @NextId = 1
  	  SET @MaterialCode = 'NewCode' + '<' + Convert(nvarchar(10),@NextId) + '>'
END
SELECT @SpecId = Spec_Id FROM Specifications a WHERE a.Spec_Desc = @SpecDesc and a.Prop_Id = @PropId 
IF @SpecId is Null
BEGIN
  	  EXECUTE spEM_CreateSpec  @SpecDesc,@propId,2,2,@userId,@SpecId Output,Null
END
IF @TransactionType = 1  -- Add
BEGIN
  	  IF EXISTS(SELECT 1 FROM Products WHERE Prod_Code = @MaterialCode)
  	  BEGIN
  	    	  SELECT Error = 'Error: Material Code Not Unique'
  	    	  RETURN
  	  END
  	  IF EXISTS(SELECT 1 FROM Products WHERE Prod_Desc = @MaterialDescription)
  	  BEGIN
  	    	  SELECT Error = 'Error: Material Description Not Unique'
  	    	  RETURN
  	  END
  	  IF @MaterialId Is Not Null
  	  BEGIN
  	    	  SELECT Error = 'Error: Material Id Passed in with add'
  	    	  RETURN
  	  END
  	  EXECUTE spEM_CreateProd @MaterialDescription,@MaterialCode,@FamilyId,@UserId,0,@MaterialId output 
  	  IF @MaterialId is Null
  	  BEGIN
  	    	  SELECT Error = 'Error: Unknown Material Not Created'
  	    	  RETURN
  	  END
END
ELSE IF @TransactionType = 2  -- Update
BEGIN
  	  IF @MaterialId is Null
  	  BEGIN
  	    	   SELECT Error = 'Error: Material Id Required To Delete'
  	    	   Return
  	  END
  	  SELECT @OldProdCode  = Prod_Code,@OldProd = Prod_Desc FROM Products WHERE Prod_Id = @MaterialId
  	  SELECT @MaterialDescription = coalesce(@MaterialDescription,@OldProd)
  	  SELECT @MaterialCode = coalesce(@MaterialCode,@OldProdCode)
  	  IF @OldProd <> @MaterialDescription
  	  BEGIN
  	    	  SELECT Error = 'Error: Renaming of Material Not Currently Supported'
  	    	  RETURN
  	  END
  	  IF  @OldProdCode <>  @MaterialCode
  	  BEGIN
  	    	  IF EXISTS(SELECT 1 FROM Products WHERE Prod_Code = @MaterialCode)
  	    	  BEGIN
  	    	    	  SELECT Error = 'Error: Material Code Not Unique'
  	    	    	  RETURN
  	    	  END
  	    	  EXECUTE spEM_RenameProdCode @MaterialId,@MaterialCode,@UserId
  	    	  SELECT @CharId = Char_Id FROM Characteristics WHERE Prod_Id = @MaterialId
  	    	  IF @CharId is  NOT Null
  	    	  BEGIN
  	    	    	  EXECUTE spEM_RenameChar @CharId,@MaterialCode,@UserId 
  	    	  END
  	  END
END
ELSE IF @TransactionType = 3
BEGIN
  	  IF @MaterialId is Null
  	  BEGIN
  	    	   SELECT Error = 'Error: Material Id Required To Delete'
  	    	   Return
  	  END
  	  IF Not Exists( SELECT 1 FROM Products where Prod_Id = @MaterialId)
  	  BEGIN
  	    	   SELECT Error = 'Error: Material Not Found To Delete'
  	    	   Return
  	  END
  	  EXECUTE spEM_DropProd @MaterialId,@UserId
  	  SELECT 'Success'
  	  RETURN
END
ELSE
BEGIN
  	  SELECT Error = 'Error: Invalid Trans Type'
  	  Return
END
/****** SPEC WORK *********/
IF @TargetRate Is Not Null
BEGIN
  	  SELECT @CharId = Char_Id FROM Characteristics WHERE  Prod_Id = @MaterialId 
  	  IF @CharId is Null
  	  BEGIN
  	    	  SELECT Error = 'Error: Characteristic for Material Not Found'
  	    	  RETURN
  	  END
  	  SELECT @Target = a.Target,@AsId = AS_Id   
  	    	  FROM Active_Specs a 
  	    	  WHERE a.Spec_Id = @SpecId 
  	    	    	  and a.Char_Id = @CharId 
  	    	    	  and a.Expiration_Date is null
  	  IF @AsId Is Null
  	  BEGIN
  	    	  SET @Now = Dateadd(Month,-1,@Now)
  	  END
  	  IF @AsId Is Null and @TargetRate Is Not Null
  	    	  SET @SpecChanged = 1
  	  ELSE IF @Target is Null and @TargetRate Is Null
  	    	  SET @SpecChanged = 0
  	  ELSE IF @Target is Not Null and @TargetRate Is Null
  	    	  SET @SpecChanged = 0
  	  ELSE IF @Target is  Null and @TargetRate Is Not Null
  	    	  SET @SpecChanged = 1
  	  ELSE IF @Target <> @TargetRate 
  	    	  SET @SpecChanged = 1
  	  IF @SpecChanged = 1
  	  BEGIN
  	    	  SELECT @TransId = Coalesce(max(Trans_Id),0) + 1 FROM Transactions 
  	    	  SELECT @TransDesc = '<' + Convert(nvarchar(10),@TransId) + '> ' + @PropDesc
  	    	  SET  @TransId = Null
  	    	  EXECUTE spEM_CreateTransaction  @TransDesc,Null,1,Null,@UserId,@TransId Output
  	    	  EXECUTE spEM_PutTransPropValues @TransId,@SpecId,@CharId
  	    	  ,Null,Null,Null,Null,@TargetRate
  	    	  ,Null,Null,Null,Null,Null
  	    	  ,Null,Null,Null,Null,Null
  	    	  ,Null,@UserId,0
  	    	  EXECUTE spEM_ApproveTrans  @TransId,@UserId,1,Null,@Now,@Now
  	  END
END
SELECT MaterialId = a.Prod_Id,
  	    	  MaterialDescription = Prod_Desc,
  	    	  MaterialCode   = Prod_Code,
  	    	  Rate = Target
FROM Products a
LEFT JOIN Characteristics c on c.Prod_Id = a.Prod_Id
LEFT JOIN Active_Specs d on d.Spec_Id = @SpecId and d.char_id = c.Char_Id and Effective_Date <= @Now and (Expiration_Date >  @Now or Expiration_Date is null)
WHERE a.Prod_Id  = @MaterialId
