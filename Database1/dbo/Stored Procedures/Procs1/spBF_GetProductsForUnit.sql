CREATE PROCEDURE [dbo].[spBF_GetProductsForUnit] 
@InputId 	  	  	  	  	 int = null,
@pageSize 	  	  	  	  	 Int = 20,
@pageNum 	  	  	  	  	 Int = 1
AS 
SET @pageNum = coalesce(@pageNum,1)
SET @pageSize = coalesce(@pageSize,20)
SET @pageNum = @pageNum -1
SELECT p.prod_id, p.prod_code 
FROM  dbo.pu_products pp WITH(NOLOCK) 
JOIN products p WITH(NOLOCK) 
ON pp.prod_id=p.prod_id 
WHERE pp.pu_id = @InputId
