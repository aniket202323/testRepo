CREATE PROCEDURE dbo.spSDK_QueryCharAssignments
  	  @LineMask  	    	    	    	  nvarchar(50) = NULL,
  	  @UnitMask  	    	    	    	  nvarchar(50) = NULL,
  	  @ProductMask  	    	    	  nvarchar(50) = NULL,
  	  @PropertyMask  	    	    	  nvarchar(50) = NULL,
  	  @CharacteristicMask  	  nvarchar(50) = NULL
AS 
SET  	  @LineMask = REPLACE(COALESCE(@LineMask, '*'), '*', '%')
SET  	  @LineMask = REPLACE(@LineMask, '?', '_')
SET  	  @UnitMask = REPLACE(COALESCE(@UnitMask, '*'), '*', '%')
SET  	  @UnitMask = REPLACE(@UnitMask, '?', '_')
SET  	  @ProductMask = REPLACE(COALESCE(@ProductMask, '*'), '*', '%')
SET  	  @ProductMask = REPLACE(@ProductMask, '?', '_')
SET  	  @PropertyMask = REPLACE(COALESCE(@PropertyMask, '*'), '*', '%')
SET  	  @PropertyMask = REPLACE(@PropertyMask, '?', '_')
SET  	  @CharacteristicMask = REPLACE(COALESCE(@CharacteristicMask, '*'), '*', '%')
SET  	  @CharacteristicMask = REPLACE(@CharacteristicMask, '?', '_')
--Mask For Name Has Been Specified
SELECT  	  DISTINCT
  	    	    	  LineName = pl.PL_Desc,
  	    	    	  UnitName = pu.PU_Desc,
  	    	    	  PropertyName = pp.Prop_Desc,
  	    	    	  CharacteristicName = c.Char_Desc,
  	    	    	  ProductCode = p.Prod_Code
  	  FROM  	  Prod_Lines pl   	    	  
  	  JOIN  	  Prod_Units pu   	    	    	    	  ON  	    	  pl.PL_Id = pu.PL_Id 
  	    	    	    	    	    	    	    	    	    	    	  AND   	  pl.PL_Desc LIKE @LineMask 
  	    	    	    	    	    	    	    	    	    	    	  AND   	  pu.PU_Desc LIKE @UnitMask 
  	  JOIN  	  PU_Products pup   	    	    	  ON  	    	  pu.PU_Id = pup.PU_Id 
  	  JOIN  	  PU_Characteristics puc  	  ON  	    	  puc.PU_Id = pu.PU_Id
  	    	    	    	    	    	    	    	    	    	    	  AND  	  puc.Prod_Id = pup.Prod_Id
  	  JOIN  	  Products p   	    	    	    	    	  ON  	    	  p.Prod_id = pup.Prod_Id
  	    	    	    	    	    	    	    	    	    	    	  AND   	  p.Prod_Code LIKE @ProductMask 
  	  JOIN  	  Characteristics c  	    	    	  ON  	    	  puc.Char_Id = c.Char_Id
  	    	    	    	    	    	    	    	    	    	    	  AND  	  c.Char_Desc LIKE @CharacteristicMask
  	  JOIN  	  Product_Properties pp  	  ON  	    	  pp.Prop_Id = c.Prop_Id
  	    	    	    	    	    	    	    	    	    	    	  AND  	  pp.Prop_Desc LIKE @PropertyMask
