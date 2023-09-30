
CREATE PROCEDURE [dbo].[spPS_CreateUpdateDeleteProducts]
@ProductId       int = null,
@ProductCode  nVarchar(25) = null,
@ProductDescription  nvarchar(50) = null,
@ProductFamilyId int = null,
@UserId int = null,
@IsSerialized BIT = null,
@paramType    nVarChar(10)

   AS

DECLARE @OldFamilyId int
DECLARE @OldProdCode nVarchar(25)

  IF NOT EXISTS(SELECT 1 FROM Users WHERE User_id = @UserId )
	BEGIN
		SELECT  Auth_Error = 'Valid User Required', 'EPS1094' as Code
		RETURN
	END
	-- checking for user have admin Privilege
  IF NOT EXISTS(select 1 from User_Security us where us.user_id =@UserId and us.Access_Level =4 and Group_Id =1)
	BEGIN
		SELECT  Auth_Error = 'Logged In User Do not Have Privilege To Create/Update/Delete Product', 'EPS1095' as Code
		RETURN
	END
-- triming the left / right spaces
SELECT @ProductCode = LTRIM(RTRIM(@ProductCode))
SELECT @ProductDescription = LTRIM(RTRIM(@ProductDescription))

-- Create Products
 IF(@paramType ='CREATE')
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM Product_Family WHERE Product_Family_Id = @ProductFamilyId)
		 	 BEGIN
		 	  	 SELECT Error = 'Product Family Id Does Not Exist', 'EPS1096' as Code
		 	  	 RETURN
		 	 END
	      IF EXISTS(SELECT 1 FROM Products WHERE Prod_Code = @ProductCode)
		 	 BEGIN
		 	  	 SELECT Error = 'Product Code Is Not Unique', 'EPS1097' as Code
		 	  	 RETURN
		 	 END
					 	 
	 	 IF EXISTS(SELECT 1 FROM Products WHERE Prod_Desc = @ProductDescription)
		 	 BEGIN
		 	  	 SELECT Error = 'Product Description Is Not Unique','EPS1098' as Code
		 	  	 RETURN
		 	 END
	    	EXECUTE dbo.spEM_CreateProd @ProductDescription,@ProductCode,@ProductFamilyId,@UserId,@ProductId,@IsSerialized

			SELECT TOP 1  Prod_Id as ProductId ,Prod_Code as ProductCode,Prod_Desc as ProductDescription,Product_Family_Id as ProductFamilyId , @IsSerialized as IsSerialized FROM Products
            WHERE Product_Family_Id = @ProductFamilyId order by Prod_Id desc 
	END
-- Update Products
ELSE IF(@paramType='UPDATE')

	BEGIN
	       SELECT @OldProdCode  = Prod_Code FROM Products WHERE Prod_Id = @ProductId
		   SELECT @OldFamilyId  = Product_Family_Id FROM Products WHERE Prod_Id = @ProductId

			-- checking ProductId Is Valid OR Not
		 	 IF NOT EXISTS(SELECT 1 FROM Products WHERE Prod_Id = @ProductId)
		 	 BEGIN
		 	  	 SELECT Error = 'Product Not Found To Update','EPS1099' as Code
		 	  	 RETURN
		 	 END

		 	 IF((@OldProdCode = @ProductCode) AND (@OldFamilyId = @ProductFamilyId))
			 BEGIN
				SELECT Error = 'Product Code and Product Family Id Already Exists','EPS1110' as Code
		 	  	RETURN
			 END
			 				 
		 	 -- checking ProductCode Is Unique OR Not
			IF  @OldProdCode <> @ProductCode
			BEGIN
				 IF EXISTS(SELECT 1 FROM Products WHERE Prod_Code = @ProductCode)
		 		 BEGIN
		 	  		 SELECT Error = 'Product Code  Not Unique','EPS1201' as Code
		 	  		 RETURN
		 		 END

				-- Updating Product Code
				EXECUTE spEM_RenameProdCode @ProductId,@ProductCode,@UserId
			END

		   	  -- checking ProductFamilyId Is Valid OR Not
		 	IF  @OldFamilyId <> @ProductFamilyId
			BEGIN
		 		 IF NOT EXISTS(SELECT 1 FROM Product_Family WHERE Product_Family_Id = @ProductFamilyId)
		 		 BEGIN
		 	  		 SELECT Error = 'Product Family Id Does Not Exist','EPS1101' as Code
		 	  		 RETURN
		 		 END
				  -- Updating Product Family
				 EXECUTE spEM_ChangeProductFamily @ProductId,@ProductFamilyId,@UserId
		 	END	
			
			SELECT  Prod_Id as ProductId ,Prod_Code as ProductCode,Prod_Desc as ProductDescription,Product_Family_Id as ProductFamilyId ,s.isSerialized FROM Products
			Left Join	Product_Serialized s on s.product_id = Prod_Id
	        WHERE Prod_Id = @ProductId 
    END
-- Delete Products
 ELSE IF(@paramType='DELETE')
    BEGIN
		   
			  IF @ProductId is Null
			 	 BEGIN
			 	  	  SELECT Error = 'Product Id Required To Delete','EPS1102' as Code
			 	  	  Return
			 	 END
			 	 
			  IF NOT EXISTS(SELECT 1 FROM Products WHERE Prod_Id = @ProductId)
			 	 BEGIN
			 	  	 SELECT Error = 'Product Not Found To Delete','EPS1103' as Code
			 	  	 RETURN
			 	 END
		 	 EXECUTE spEM_DropProd @ProductId,@UserId
	END

