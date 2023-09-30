CREATE PROCEDURE [dbo].[spDAML_FetchProductTree] 
AS
BEGIN
    -- The first part of the dataset contains a list of product families and products
    --   Note the outer joins are needed to pick up empty items.
    SELECT      TreeCode = 1,
 	  	  	  	 ProductFamilyId = IsNull(pf.Product_Family_Id,0),
                ProductFamilyName = pf.Product_Family_Desc,
 	  	         ProductId = isNull(p.Prod_Id,0),
 	  	  	  	 ProductName = p.Prod_Desc + ' (' + p.Prod_Code + ')',
 	  	         ProductPropertyId = 0,
 	  	  	  	 ProductPropertyName = '',
 	  	         ProductSpecificationId = 0,
 	  	  	  	 ProductSpecificationName = '',
 	  	         ProductCharacteristicId = 0,
 	  	  	  	 ProductCharacteristicName = ''
 	         FROM Product_Family pf 
 	  	     LEFT OUTER JOIN Products p ON pf.Product_Family_Id = p.Product_Family_Id
 	  	  	  	  	  	  	  	  	 
  UNION
   -- The second part of the dataset contains a list of properties
   --   Note the outer joins are needed to pick up empty items.
    SELECT      TreeCode = 2,
 	  	  	  	 ProductFamilyId = 0,
                ProductFamilyName = '',
 	  	         ProductId = 0, 
                ProductName = '',
 	  	         ProductPropertyId = IsNull(pp.Prop_Id,0), 
 	  	  	  	 ProductPropertyName = pp.Prop_Desc,
 	  	         ProductSpecificationId = IsNull(s.Spec_Id,0),
 	  	  	  	 ProductSpecificationName = s.Spec_Desc,
 	  	         ProductCharacteristicId = IsNull(c.Char_Id,0),
 	  	  	  	 ProductCharacteristicName = c.Char_Desc
 	         FROM Product_Properties pp 
 	  	     left outer join Characteristics c ON pp.Prop_Id = c.Prop_id
            left outer join Specifications s ON pp.Prop_Id = s.Prop_id
 	 
    -- order is critical if the load is to be successful 	  	  	  	  	  	  	  	 
 	 ORDER BY TreeCode, ProductFamilyId, ProductId, ProductPropertyId, ProductSpecificationId, ProductCharacteristicId
END
