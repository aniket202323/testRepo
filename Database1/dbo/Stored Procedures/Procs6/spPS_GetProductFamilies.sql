
CREATE PROCEDURE dbo.spPS_GetProductFamilies
		 @ProductId			Int
		,@UserId			Int
		,@ProductFamilyId	Int = Null

  AS


IF NOT EXISTS(SELECT 1 FROM Users WHERE User_id = @UserId )
BEGIN
	SELECT  Error = 'ERROR: Valid User Required'
	RETURN
END

Declare @ProductFamilyData table (ProductFamilyId int, FamilyDesc nvarchar(50))
IF @ProductFamilyId Is NULL
BEGIN
	INSERT INTO @ProductFamilyData(ProductFamilyId, FamilyDesc)
		SELECT		Distinct f.Product_Family_Id, f.Product_Family_Desc
		FROM		Product_Family f
		WHERE		((@ProductId is null) or (@ProductId in (select Prod_Id from Products_Base where Product_Family_Id = f.Product_Family_Id)))
END
ELSE
BEGIN
	INSERT INTO @ProductFamilyData(ProductFamilyId, FamilyDesc)
		SELECT	f.Product_Family_Id, f.Product_Family_Desc
		FROM	Product_Family f
		WHERE	f.Product_Family_Id = @ProductFamilyId
END

SELECT   ProductFamilyId = f.ProductFamilyId
		,Description = f.FamilyDesc
	FROM  @ProductFamilyData f
	ORDER BY f.ProductFamilyId
