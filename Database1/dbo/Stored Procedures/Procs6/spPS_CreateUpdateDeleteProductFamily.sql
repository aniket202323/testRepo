
CREATE PROCEDURE [dbo].[spPS_CreateUpdateDeleteProductFamily]
@ProductFamilyId int = null,
@Description    nvarchar(255) = null,
@UserId int = 1,
@paramType    nVarChar(10)
  AS


  IF NOT EXISTS(SELECT 1 FROM Users WHERE User_id = @UserId )
	BEGIN
		SELECT  Auth_Error = 'Valid User Required' , 'EPS1094' as Code
		RETURN
	END
	
	-- checking for user have admin Privilege
  IF NOT EXISTS(select 1 from User_Security us where us.user_id =@UserId and us.Access_Level =4 and Group_Id =1)
	BEGIN
		SELECT  Auth_Error = 'Logged In User Do not Have Privilege To Create/Update/Delete Product' , 'EPS1095' as Code
		RETURN
	END
  
IF(@paramType ='CREATE')
BEGIN
	IF EXISTS(SELECT 1 FROM Product_Family WHERE Product_Family_Desc = @Description)
	 BEGIN
		 SELECT Error = 'Product Family Description Not Unique', 'EPS1106' as Code
		 RETURN
	 END
	-- Calling Core Sproc to Create Product Family
	EXECUTE spEM_CreateProductFamily @Description,@UserId,@ProductFamilyId
	-- PRINT 'CREATED';
	SELECT Product_Family_Id as ProductFamilyId ,Product_Family_Desc as Description FROM Product_Family
	WHERE Product_Family_Desc = @Description; 
END

ELSE IF(@paramType='UPDATE')
BEGIN
	IF EXISTS(SELECT 1 FROM Product_Family WHERE Product_Family_Desc = @Description)
		 BEGIN
			 SELECT Error = 'Product Family Description  Not Unique', 'EPS1107' as Code
			 RETURN
		 END
	IF NOT EXISTS(SELECT 1 FROM Product_Family WHERE Product_Family_Id = @ProductFamilyId)
		 BEGIN
			 SELECT Error = 'Product Family Not Found To Update', 'EPS1108' as Code
			 RETURN
		 END
		 
    -- Calling Core Sproc to Update Product Family
    EXECUTE spEM_RenameProductFamily @ProductFamilyId,@Description,@UserId
    Update Product_Family Set Product_Family_Desc_Local = @Description Where Product_Family_Id = @ProductFamilyId
	-- PRINT 'UPDATED'
	
	SELECT Product_Family_Id as ProductFamilyId ,Product_Family_Desc as Description FROM Product_Family
    WHERE Product_Family_Id = @ProductFamilyId; 
 END
 
ELSE IF(@paramType='DELETE')
BEGIN
	 IF NOT EXISTS(SELECT 1 FROM Product_Family WHERE Product_Family_Id = @ProductFamilyId)
		 BEGIN
			 SELECT Error = 'Product Family Not Found To Delete', 'EPS1109' as Code
			 RETURN
		 END
	 EXECUTE spEM_DropProductFamily @ProductFamilyId,@UserId
	-- PRINT 'DELETED'
END

