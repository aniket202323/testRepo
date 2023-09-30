CREATE PROCEDURE dbo.spEMED_GetUserDefined 
  @ModelId 	  	  	   Int
  AS
    Select ED_Field_Prop_Id,ED_Field_Type_Id,Default_Value,Field_Desc,Optional,Locked 
 	  	 From ED_Field_Properties
 	  	 Where  ED_Model_Id = @ModelId
 	  	 Order by Field_Desc
