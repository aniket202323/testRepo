
CREATE PROCEDURE dbo.spPS_GetProducts
		 @ProductGroupIds	nvarchar(max) = null
		,@ProductFamilyIds	nvarchar(max) = Null
		,@UserId			Int
		,@ProductId			Int = Null
		,@ProdDescription   nvarchar(50) = null
		,@ProductCode		nvarchar(100) = null
		,@IsSerialized BIT = null


  AS

IF NOT EXISTS(SELECT 1 FROM Users WHERE User_id = @UserId )
BEGIN
	SELECT  Error = 'ERROR: Valid User Required'
	RETURN
END

CREATE TABLE #AllGroups(Group_Id Int)
CREATE TABLE #AllFamilies(Family_Id Int)

CREATE TABLE  #ProductData (ProductId int, ProductCode nVarchar(25), ProductDesc nvarchar(50), ProductFamilyId int ,IsSerialized BIT,ProductGroupId int)

DECLARE @SQLStr nvarchar(max)

Declare @TmpRsrvdParmTbl dbo.ReservedKeywordsParms;

Insert Into @TmpRsrvdParmTbl
Select @ProductGroupIds
UNION
Select @ProductFamilyIds
union
select @ProdDescription
union
select @ProductCode
Declare @IsReservedKeywordUsed int 
set @IsReservedKeywordUsed =0;
EXEC sp_checkforReservedKeywords @TmpRsrvdParmTbl, @IsReservedKeywordUsed = @IsReservedKeywordUsed OUTPUT

IF @IsReservedKeywordUsed >0 
Begin
SELECT  Error = 'ERROR: SQL Reserved keyword is used', 'EPS2124' as code
	RETURN
End

IF @ProductId Is NULL
BEGIN

--if (@ProductGroupIds is not null)
--		INSERT INTO #AllGroups (Group_Id)  SELECT Id FROM dbo.fnCMN_IdListToTable('Product_Groups', @ProductGroupIds, ',')
--	if (@ProductFamilyIds is not null)
--		INSERT INTO #AllFamilies (Family_Id)  SELECT Id FROM dbo.fnCMN_IdListToTable('Product_Family', @ProductFamilyIds, ',')

		SET @SQLStr =  ''
		SET @SQLStr =  @SQLStr + 'INSERT INTO #ProductData (ProductId, ProductCode, ProductDesc, ProductFamilyId ,IsSerialized, ProductGroupId)'
		SET @SQLStr =  @SQLStr + '
			SELECT Distinct p.Prod_Id, p.Prod_Code, p.Prod_Desc, p.Product_Family_Id ,s.isSerialized, g.Product_Grp_Id
		'
		SET @SQLStr =  @SQLStr + ' FROM Products_Base p with (nolock) '
		SET @SQLStr =  @SQLStr + '
			Join Product_Family f with(nolock) on f.Product_Family_Id = p.Product_Family_Id '
		SET @SQLStr =  @SQLStr + '
			Left Join	Product_Group_Data g with(nolock) on g.Prod_Id = p.Prod_Id '
		SET @SQLStr =  @SQLStr + '
			Left Join	Product_Serialized s with(nolock) on s.product_id = p.Prod_Id '
		
		IF (@ProductCode IS NOT NULL) OR (@IsSerialized IS NOT NULL) OR (@ProductFamilyIds IS NOT NULL) OR (@ProductGroupIds IS NOT NULL) OR (@ProdDescription IS NOT NULL)
		SET @SQLStr =  @SQLStr + 'where (1=1)'
		 
		IF @ProductFamilyIds IS NOT NULL
		SET @SQLStr =  @SQLStr + '
			 AND ((p.Product_Family_Id in ('+@ProductFamilyIds+')))'

		IF @ProductGroupIds IS NOT NULL
		SET @SQLStr =  @SQLStr + '
			 AND ((g.Product_Grp_Id in ('+@ProductGroupIds+')))'

		IF @ProdDescription IS NOT NULL
		SET @SQLStr =  @SQLStr + '
				AND ((p.Prod_Desc = N'''+@ProdDescription+'''))'

		IF @ProductCode IS NOT NULL
		SET @SQLStr =  @SQLStr + '
			AND ((p.Prod_Code = N'''+@ProductCode+'''))'

		IF @IsSerialized = 1
		SET @SQLStr =  @SQLStr + '
			AND ('+Cast(@IsSerialized as nvarchar)+' = 1 AND s.isSerialized ='+Cast(@IsSerialized as nvarchar)+' AND s.isSerialized is not null ) 
				'
		IF @IsSerialized = 0
		SET @SQLStr =  @SQLStr + '
			 AND ('+Cast(@IsSerialized as nvarchar)+' = 0 AND (s.isSerialized = 0 OR  s.isSerialized is null))'

		EXEC (@SQLStr)

END
ELSE
BEGIN
	INSERT INTO #ProductData(ProductId, ProductCode, ProductDesc, ProductFamilyId, IsSerialized, ProductGroupId)
		SELECT	p.Prod_Id, p.Prod_Code, p.Prod_Desc, p.Product_Family_Id, s.isSerialized, f.Group_Id
		FROM	Products_Base p with(nolock)
		Left Join	Product_Serialized s with(nolock) on s.product_id = p.Prod_Id
		Left Join   Product_Family f with(nolock) on f.Product_Family_Id = p.Product_Family_Id
		WHERE	p.Prod_Id = @ProductId
END

SELECT   ProductId = p.ProductId
		,ProductCode = p.ProductCode
		,ProductDescription = p.ProductDesc
		,ProductFamilyId = p.ProductFamilyId
		,IsSerialized = p.isSerialized
		,ProductGroupId = p.ProductGroupId
	FROM  #ProductData p
	ORDER BY p.ProductId
