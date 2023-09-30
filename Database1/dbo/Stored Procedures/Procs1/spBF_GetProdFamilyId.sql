CREATE Procedure dbo.spBF_GetProdFamilyId(@PUId int,@UserId Int,@ProdFamilyId Int Output,@SpecId Int Output) 
AS 
 	 DECLARE @DeptDesc nVarChar(100)
 	 DECLARE @propId Int
 	 DECLARE @SpecDesc nVarChar(100) = 'Rate'
 	 SET @ProdFamilyId = Null 	 
 	 SET @SpecId = Null
 	 IF (@PUId is not null)
 	 BEGIN
  	  	 SELECT @DeptDesc= Dept_Desc
 	  	  	 FROM Prod_Units_Base a
 	  	  	 JOIN Prod_lines_Base b ON b.pl_Id = a.PL_Id
 	  	  	 JOIN Departments c on c.Dept_Id = b.Dept_Id
 	  	  	 WHERE a.PU_Id = @PUId
 	  	 /*  Product Family / Property / Spec */
 	  	 SELECT @ProdFamilyId = a.Product_Family_Id FROM Product_Family a WHERE Product_Family_Desc = @DeptDesc
 	  	 IF @ProdFamilyId Is Null
   	  	  	 EXECUTE spEM_CreateProductFamily @DeptDesc,@UserId,@ProdFamilyId Output 
 	  	 SELECT @propId = a.Prop_Id  
 	  	  	 FROM Product_Properties  a 
 	  	  	 WHERE a.Prop_Desc  = @DeptDesc
 	  	 IF @propId Is Null
 	  	 BEGIN
 	  	  	 EXECUTE spEM_CreateProp   @DeptDesc,1,@UserId,@propId Output
 	   	  	 EXECUTE spEM_PutPropertyData  @propId,@ProdFamilyId,1,@UserId
 	  	 END
 	  	 SELECT @specid = a.Spec_Id FROM specifications a WHERE Spec_Desc  = @SpecDesc and Prop_Id = @propId
 	  	 IF @specid Is Null
     	  	 EXECUTE spEM_CreateSpec  @SpecDesc,@propId,2,2,@userId,@specid Output,Null
 	 END
