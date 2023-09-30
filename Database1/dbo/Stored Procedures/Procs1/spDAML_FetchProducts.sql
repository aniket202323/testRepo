Create Procedure dbo.spDAML_FetchProducts
    @ProdId 	  	 INT = NULL,
 	 @FamId 	  	 INT = NULL,
 	 @UserId 	  	 INT 	 = NULL
AS
-- Local variables
DECLARE 	 
   @SecurityClause VARCHAR(100),
    @IdClause 	  	 VARCHAR(50),
    @OptionsClause  VARCHAR(1000),
    @TimeClause 	  	 VARCHAR(500),
 	 @WhereClause 	 VARCHAR(1000),
    @SelectClause   VARCHAR(4000),
    @OrderClause 	 VARCHAR(500)
-- product families have security
SET @SecurityClause = ' WHERE (COALESCE(pfs.Access_Level, 3) >= 2) '
-- Only one of the following id values, if any, is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@ProdId<>0 AND @ProdId IS NOT NULL) THEN 'AND p.Prod_Id = ' + CONVERT(VARCHAR(10),@ProdId) 
   WHEN (@FamId<>0 AND @FamId IS NOT NULL) THEN 'AND (p.Prod_Id<>1) AND p.Product_Family_Id = ' + CONVERT(VARCHAR(10),@FamId)
   ELSE ''
END
-- Products have no options clause
SET @OptionsClause = ''
-- Products have no time clause
SET @TimeClause = ''
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
--   All DATES are converted to UTC
SET @SelectClause =
 	 'SELECT 	 ProductId = p.Prod_Id,
 	  	  	 ProductCode = p.Prod_Code, 
 	  	  	 ProductDescription = p.Prod_Desc,
 	  	  	 ProductFamilyId = IsNull(p.Product_Family_Id,0),
 	  	  	 ProductFamily = ISNULL(pf.Product_Family_Desc,''''),
 	  	  	 IsManufacturingProduct = COALESCE(Is_Manufacturing_Product, 1),
 	  	  	 IsSalesProduct = COALESCE(Is_Sales_Product, 0),
 	  	  	 CommentId = ISNULL(p.Comment_Id,0)
 	 FROM 	 Product_Family pf
 	 JOIN 	 Products p 	 ON pf.Product_Family_Id = p.Product_Family_Id
 	 LEFT JOIN User_Security pfs 	 ON pf.Group_Id = pfs.Group_Id 
                                AND 	 pfs.User_Id = ' + CONVERT(VARCHAR(10), @UserId)
-- products have no order clause
SET @OrderClause = ' ORDER BY p.Prod_Code '
--SELECT sc = @SelectClause, wc = @WhereClause, oc = @OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause)
