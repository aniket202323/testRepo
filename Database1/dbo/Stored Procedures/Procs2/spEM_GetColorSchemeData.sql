CREATE PROCEDURE dbo.spEM_GetColorSchemeData
  @CS_Id               int
  AS
Select Group_Desc =  csc.Color_Scheme_Category_Desc,Field_Desc = csf.Color_Scheme_Field_Desc,
  Color = Coalesce(csd.Color_Scheme_Value, csf.Default_Color_Scheme_Color),Field_Id = csf.Color_Scheme_Field_Id
From Color_Scheme_Fields csf
Left Join Color_Scheme_Data csd on csf.Color_Scheme_Field_Id =  csd.Color_Scheme_Field_Id and csd.CS_Id = @CS_Id
Left Join Color_Scheme_categories csc On csc.Color_Scheme_Category_Id = csf.Color_Scheme_Category_Id
Order By Group_Desc,Field_Desc
-- 
