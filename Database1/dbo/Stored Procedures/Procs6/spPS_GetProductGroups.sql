
CREATE PROCEDURE dbo.spPS_GetProductGroups
		 @ProductId			Int
		,@UserId			Int
		,@ProductGroupId	Int = Null

   AS


IF NOT EXISTS(SELECT 1 FROM Users WHERE User_id = @UserId )
BEGIN
	SELECT  Error = 'ERROR: Valid User Required'
	RETURN
END

Declare @ProductGroupData table (ProductGroupId int, GroupDesc nvarchar(50))
IF @ProductGroupId Is NULL
BEGIN
	INSERT INTO @ProductGroupData(ProductGroupId, GroupDesc)
		SELECT		Distinct g.Product_Grp_Id, g.Product_Grp_Desc
		FROM		Product_Groups g
		Left Join	Product_Group_Data gd on gd.Product_Grp_Id = g.Product_Grp_Id -- Left join because Not all products are in groups and we need all groups to apear at least once in the result
		WHERE		((@ProductId is null) or (gd.Prod_Id = @ProductId))
END
ELSE
BEGIN
	INSERT INTO @ProductGroupData(ProductGroupId, GroupDesc)
		SELECT	g.Product_Grp_Id, g.Product_Grp_Desc
		FROM	Product_Groups g
		WHERE	g.Product_Grp_Id = @ProductGroupId
END

SELECT   ProductGroupId = g.ProductGroupId
		,Description = g.GroupDesc
	FROM  @ProductGroupData g
	ORDER BY g.ProductGroupId
