CREATE PROCEDURE dbo.spCMN_GetEventConfigProperty
 @Value 	  	  VarChar(1000) Output,
 @Field_Desc VarChar(255),
 @EC_Id int
AS
  --
  Select  @Value = Case When ecp.value Is Null Then efp.Default_Value
 	  	  	  	    Else ecp.Value
 	  	  	  	   End
   From Event_Configuration ec
   Join  ED_Field_Properties efp on ec.ED_Model_Id = efp.ED_Model_Id and efp.Field_Desc = @Field_Desc
   Left Join Event_Configuration_Properties ecp on ecp.ED_Field_Prop_Id = efp.ED_Field_Prop_Id
 	  WHERE   ec.EC_Id = @EC_Id   
