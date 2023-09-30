Create Procedure dbo.spDAML_FetchProductAssignments
    @LineId         INT = NULL,
    @UnitId         INT = NULL,
    @ProductCode 	 VARCHAR(25) = NULL,
 	 @UserId 	  	  	 INT 	 = NULL
AS
-- Local variables
DECLARE 	 
    @SecurityClause VARCHAR(100),
    @IdClause 	  	 VARCHAR(50),
    @OptionsClause  VARCHAR(1000),
 	 @TimeClause 	  	 VARCHAR(500),
 	 @WhereClause 	 VARCHAR(2000),
    @SelectClause   VARCHAR(4000),
 	 @OrderClause 	 VARCHAR(500)
-- The production unit and production line have security levels
SET @SecurityClause = ' WHERE COALESCE(pus.Access_Level, pls.Access_Level, 3) >= 2 '
-- One and only one of the following id values is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@UnitId<>0 AND @UnitId IS NOT NULL) THEN 'AND pu.PU_Id = ' + CONVERT(VARCHAR(10),@UnitId)
   WHEN (@LineId<>0 AND @LineId IS NOT NULL) THEN 'AND pl.PL_Id = ' + CONVERT(VARCHAR(10),@LineId)
   ELSE ''
END
-- All of the following are optional and some or none can apply
SET @OptionsClause = ''
IF (@ProductCode<>'' AND @ProductCode IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @ProductCode)=0 AND CHARINDEX('_', @ProductCode)=0 )
     SET @OptionsClause = @OptionsClause + ' AND p.Prod_Code = ''' + CONVERT(VARCHAR(25),@ProductCode) + ''' '
   ELSE
      SET @OptionsClause = @OptionsClause + ' AND p.Prod_Code LIKE ''' + CONVERT(VARCHAR(25),@ProductCode) + ''' '
END
-- Product Assignments have no time clause
SET @TimeClause = ''
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
SET @SelectClause =
'SELECT 	 DISTINCT
 	  	  	 ProductionUnitId = pu.PU_Id,
 	  	  	 ProductionUnit = pu.PU_Desc,
 	  	  	 ProductionLineId = pl.PL_Id,
 	  	  	 ProductionLine = pl.PL_Desc,
 	  	  	 DepartmentId = d.Dept_Id,
 	  	  	 Department = d.Dept_Desc,
 	  	  	 ProductId = p.Prod_Id,
 	  	  	 ProductCode = p.Prod_Code, 
 	  	  	 ProductDescription = p.Prod_Desc,
 	  	  	 ProductFamilyId = p.Product_Family_Id,
 	  	  	 ProductFamily = pf.Product_Family_Desc,
 	  	  	 IsManufacturingProduct = IsNull(Is_Manufacturing_Product, 1),
 	  	  	 IsSalesProduct = IsNull(Is_Sales_Product, 0)
 	 FROM 	 Departments d
 	 JOIN 	 Prod_Lines pl 	  	 ON 	 d.Dept_Id = pl.Dept_Id 
 	 JOIN 	 Prod_Units pu  	  	 ON 	 pl.PL_Id = pu.PL_Id
 	 JOIN 	 PU_Products pp  	  	 ON 	 pu.PU_Id = pp.PU_Id 
 	 JOIN 	 Products p  	  	  	 ON 	 p.Prod_id = pp.Prod_Id
 	 JOIN 	 Product_Family pf 	 ON  	 p.Product_Family_Id = pf.Product_Family_Id
 	 LEFT JOIN 	 User_Security pls 	 ON  	 pl.Group_Id = pls.Group_Id
 	  	  	  	  	  	  	  	  	  	 AND pls.User_Id = ' + CONVERT(VARCHAR(10),@UserId) +
' 	 LEFT JOIN 	 User_Security pus 	 ON  	 pu.Group_Id = pus.Group_Id
 	  	  	  	  	  	  	  	  	  	 AND  	 pus.User_Id = ' + CONVERT(VARCHAR(10),@UserId)
-- order clause
SET @OrderClause = ' ORDER BY pu.PU_Desc, p.Prod_Code '
--SELECT sc = @SelectClause, wc = @WhereClause, oc = @OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause)
