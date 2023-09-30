CREATE PROCEDURE dbo.spEMED_DeleteUserDefined 
  @FieldId 	  	  	   Int
  AS
 	 Delete From Event_Configuration_Properties
 	  	 Where  ED_Field_Prop_Id = @FieldId
    Delete From ED_Field_Properties
 	  	 Where  ED_Field_Prop_Id = @FieldId
