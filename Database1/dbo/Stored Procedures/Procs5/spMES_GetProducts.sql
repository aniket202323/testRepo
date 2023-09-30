
CREATE PROCEDURE dbo.spMES_GetProducts
		 @ProductGroupIds	nvarchar(max) = null
		,@ProductFamilyIds	nvarchar(max) = Null
		,@UserId			Int
		,@ProductId			Int = Null
AS

IF NOT EXISTS(SELECT 1 FROM Users_Base WHERE User_id = @UserId )
BEGIN
	SELECT  Error = 'ERROR: Valid User Required'
	RETURN
END

DECLARE @AllGroups Table (Group_Id Int)
DECLARE @AllFamilies Table (Family_Id Int)

Declare @ProductData table (ProductId int, ProductCode nVarchar(25), ProductDesc nvarchar(50), ProductFamilyId int)
IF @ProductId Is NULL
BEGIN

	if (@ProductGroupIds is not null)
		INSERT INTO @AllGroups (Group_Id)  SELECT Id FROM dbo.fnCMN_IdListToTable('Product_Groups', @ProductGroupIds, ',')
	if (@ProductFamilyIds is not null)
		INSERT INTO @AllFamilies (Family_Id)  SELECT Id FROM dbo.fnCMN_IdListToTable('Product_Family', @ProductFamilyIds, ',')

	INSERT INTO @ProductData(ProductId, ProductCode, ProductDesc, ProductFamilyId)
		SELECT		Distinct p.Prod_Id, p.Prod_Code, p.Prod_Desc, p.Product_Family_Id
		FROM		Products_Base p
		Join		Product_Family f on f.Product_Family_Id = p.Product_Family_Id
		Left Join	Product_Group_Data g on g.Prod_Id = p.Prod_Id
		WHERE		((@ProductFamilyIds is null) or (p.Product_Family_Id in (select Family_Id from @AllFamilies)))
			And		((@ProductGroupIds is null) or (g.Product_Grp_Id in (select Group_Id from @AllGroups)))
END
ELSE
BEGIN
	INSERT INTO @ProductData(ProductId, ProductCode, ProductDesc, ProductFamilyId)
		SELECT	p.Prod_Id, p.Prod_Code, p.Prod_Desc, p.Product_Family_Id
		FROM	Products_Base p
		WHERE	p.Prod_Id = @ProductId
END

SELECT   ProductId = p.ProductId
		,ProductCode = p.ProductCode
		,ProductDescription = p.ProductDesc
		,ProductFamilyId = p.ProductFamilyId
	FROM  @ProductData p
	ORDER BY p.ProductId
