CREATE PROCEDURE dbo.spSDK_GetSpecificationVariableById
 	 @SpecificationVariableId 	  	  	  	 INT
AS
SELECT 	 SpecificationId = s.Spec_Id,
 	  	  	 PropertyName = pp.Prop_Desc,
 	  	  	 SpecificationName = s.Spec_Desc,
 	  	  	 DataType = dt.Data_Type_Desc, 
 	  	  	 SpecPrecision = COALESCE(s.Spec_Precision, 0),
 	  	  	 EngineeringUnits = COALESCE(s.Eng_Units, ''),
 	  	  	 Tag = COALESCE(s.Tag, ''),
 	  	  	 ExtendedInfo = s.Extended_Info,
 	  	  	 CommentId = s.Comment_Id
 	 FROM 	  	  	  	  	 Product_Properties pp
 	  	  	 JOIN 	  	  	 Specifications s 	  	  	 ON 	  	 pp.Prop_Id = s.Prop_Id AND s.Spec_Id = @SpecificationVariableId
 	  	  	 JOIN 	  	  	 Data_Type dt 	  	  	  	 ON 	  	 s.Data_Type_Id = dt.Data_Type_Id 
