CREATE PROCEDURE dbo.spCSS_GetColorSchemeData
  @CS_Name    nvarchar(50),
  @CS_Id      int
  AS
--They can send in either the ID or the DESC
If @CS_Id IS NULL Or @CS_Id = 0 
  Begin
    Select @CS_Id = NULL
    Select @CS_Id = CS_Id from
       Color_Scheme
       Where CS_Desc = @CS_Name
  End
/* If the Color Scheme is not found, the default colors for each field type are returned */
Select Group_Desc =  csc.Color_Scheme_Category_Desc,Field_Desc = csf.Color_Scheme_Field_Desc,
  Color = Coalesce(csd.Color_Scheme_Value, csf.Default_Color_Scheme_Color),Field_Id = csf.Color_Scheme_Field_Id
From Color_Scheme_Fields csf
Left Join Color_Scheme_Data csd on csf.Color_Scheme_Field_Id =  csd.Color_Scheme_Field_Id and csd.CS_Id = @CS_Id
Left Join Color_Scheme_categories csc On csc.Color_Scheme_Category_Id = csf.Color_Scheme_Category_Id
Order By Field_Id
Select CS_Id, CS_Desc From Color_Scheme Where CS_Id = @CS_Id
-- 
