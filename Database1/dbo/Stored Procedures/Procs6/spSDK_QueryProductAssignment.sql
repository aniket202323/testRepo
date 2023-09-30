CREATE PROCEDURE dbo.spSDK_QueryProductAssignment
 	 @LineMask 	  	 nvarchar(50) 	 = NULL,
 	 @UnitMask 	  	 nvarchar(50) 	 = NULL,
 	 @ProductMask 	 nvarchar(50) 	 = NULL,
 	 @UserId 	  	  	 INT 	  	  	  	 = NULL
AS
SET 	 @LineMask = REPLACE(COALESCE(@LineMask, '*'), '*', '%')
SET 	 @LineMask = REPLACE(REPLACE(@LineMask, '?', '_'), '[', '[[]')
SET 	 @UnitMask = REPLACE(COALESCE(@UnitMask, '*'), '*', '%')
SET 	 @UnitMask = REPLACE(REPLACE(@UnitMask, '?', '_'), '[', '[[]')
SET 	 @ProductMask = REPLACE(COALESCE(@ProductMask, '*'), '*', '%')
SET 	 @ProductMask = REPLACE(REPLACE(@ProductMask, '?', '_'), '[', '[[]')
--Mask For Name Has Been Specified
SELECT 	 DISTINCT
 	  	  	 ProductId = p.Prod_Id,
 	  	  	 ProductCode = p.Prod_Code, 
 	  	  	 ProductDesc = p.Prod_Desc,
 	  	  	 ProductFamily = pf.Product_Family_Desc,
 	  	  	 IsManufacturingProduct = COALESCE(Is_Manufacturing_Product, 1),
 	  	  	 IsSalesProduct = COALESCE(Is_Sales_Product, 0),
 	  	  	 CommentId = p.Comment_Id
 	 FROM 	  	  	  	 Departments d
 	 JOIN 	  	  	 Prod_Lines pl 	  	 ON 	  	 d.Dept_Id = pl.Dept_Id 
 	  	  	  	  	  	  	  	  	  	  	 AND 	 pl.PL_Desc LIKE @LineMask 
 	 JOIN 	  	  	 Prod_Units pu  	  	 ON 	  	 pl.PL_Id = pu.PL_Id
 	  	  	  	  	  	  	  	  	  	  	 AND  	 pu.PU_Desc LIKE @UnitMask
 	 JOIN 	  	  	 PU_Products pp  	 ON 	  	 pu.PU_Id = pp.PU_Id 
 	 JOIN 	  	  	 Products p  	  	  	 ON 	  	 p.Prod_id = pp.Prod_Id
 	  	  	  	  	  	  	  	  	  	  	 AND  	 p.Prod_Code LIKE @ProductMask
 	 JOIN 	  	  	 Product_Family pf 	 ON  	 p.Product_Family_Id = pf.Product_Family_Id
 	 LEFT JOIN 	 User_Security pls 	 ON  	 pl.Group_Id = pls.Group_Id
 	  	  	  	  	  	  	  	  	  	  	 AND  	 pls.User_Id = @UserId
 	 LEFT JOIN 	 User_Security pus 	 ON  	 pu.Group_Id = pus.Group_Id
 	  	  	  	  	  	  	  	  	  	  	 AND  	 pus.User_Id = @UserId
 	 WHERE 	 COALESCE(pus.Access_Level, COALESCE(pls.Access_Level, 3)) >= 2
