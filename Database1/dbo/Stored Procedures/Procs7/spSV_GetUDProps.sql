--   spSV_GetUDProps 19,54685,3,7,1
CREATE Procedure dbo.spSV_GetUDProps
@Sheet_Id int,
@PP_Id int,
@Path_Id int,
@TableId int,
@RegionalServer Int = 0,
@tz varchar(200)='UTC'
AS
If @RegionalServer Is Null
 	 Select @RegionalServer = 0
Declare @TableFields Table (
  TableFieldId int,
  TableFieldDesc nvarchar(50),
  EDFieldTypeId int,
  MyValue varchar(7000),
  ValueId int,
  FieldTypeDesc nvarchar(100),
  SPLookup tinyint,
  StoreId tinyint
)
Declare @User_General_1 varchar(7000),
@User_General_2 varchar(7000),
@User_General_3 varchar(7000)
Select @User_General_1 = Value
  From Sheet_Display_Options
  Where Sheet_Id = @Sheet_Id
  And Display_Option_Id = 71
Select @User_General_2 = Value
  From Sheet_Display_Options
  Where Sheet_Id = @Sheet_Id
  And Display_Option_Id = 72
Select @User_General_3 = Value
  From Sheet_Display_Options
  Where Sheet_Id = @Sheet_Id
  And Display_Option_Id = 73
Insert Into @TableFields   (TableFieldId,TableFieldDesc, EDFieldTypeId , MyValue, ValueId , FieldTypeDesc, SPLookup,StoreId)
  Select -1, Coalesce(@User_General_1, 'User General 1'), 1, User_General_1, NULL, 'Text', 0, 0 From Production_Plan Where PP_Id = @PP_Id
Insert Into @TableFields (TableFieldId,TableFieldDesc, EDFieldTypeId , MyValue, ValueId , FieldTypeDesc, SPLookup,StoreId)
  Select -2, Coalesce(@User_General_2, 'User General 2'), 1, User_General_2, NULL, 'Text', 0, 0 From Production_Plan Where PP_Id = @PP_Id
Insert Into @TableFields (TableFieldId,TableFieldDesc, EDFieldTypeId , MyValue, ValueId , FieldTypeDesc, SPLookup,StoreId)
  Select -3, Coalesce(@User_General_3, 'User General 3'), 1, User_General_3, NULL, 'Text', 0, 0 From Production_Plan Where PP_Id = @PP_Id
Insert Into @TableFields (TableFieldId,TableFieldDesc, EDFieldTypeId , MyValue, ValueId , FieldTypeDesc, SPLookup,StoreId)
  Select -4, 'Control Type', -4, NULL, Control_Type, 'Control Type', 1, 1 From Production_Plan Where PP_Id = @PP_Id
Insert Into @TableFields (TableFieldId,TableFieldDesc, EDFieldTypeId , MyValue, ValueId , FieldTypeDesc, SPLookup,StoreId)
  Select -5, 'Process Order Type', -5, NULL, PP_Type_Id, 'Process Order Type', 1, 1 From Production_Plan Where PP_Id = @PP_Id
Insert Into @TableFields (TableFieldId,TableFieldDesc, EDFieldTypeId , MyValue, ValueId , FieldTypeDesc, SPLookup,StoreId)
  Select -6, 'Product', -6, NULL, Prod_Id, 'Product', 1, 1 From Production_Plan Where PP_Id = @PP_Id
If @Path_Id is NOT NULL
 	 Insert Into @TableFields (TableFieldId,TableFieldDesc, EDFieldTypeId , MyValue, ValueId , FieldTypeDesc, SPLookup,StoreId)
 	   Select TF.Table_Field_Id, TF.Table_Field_Desc, TF.ED_Field_Type_Id, 
 	     Value = Case When EDFT.Store_Id = 0 Then TFV_PATH.Value Else NULL End, ValueId = Case When EDFT.Store_Id = 1 Then TFV_PATH.Value Else NULL End, 
 	     EDFT.Field_Type_Desc, EDFT.SP_Lookup, EDFT.Store_Id
 	     From Table_Fields TF
 	     Join Table_Fields_Values TFV_PATH on TFV_PATH.KeyId = @Path_Id and TFV_PATH.Table_Field_Id = TF.Table_Field_Id and TFV_PATH.TableId = 13 --PrdExec_Paths
 	     Join ED_FieldTypes EDFT On EDFT.ED_Field_Type_Id = TF.ED_Field_Type_Id
Insert Into @TableFields (TableFieldId,TableFieldDesc, EDFieldTypeId , MyValue, ValueId , FieldTypeDesc, SPLookup,StoreId)
  Select TF.Table_Field_Id, TF.Table_Field_Desc, TF.ED_Field_Type_Id, 
    Value = Case When EDFT.Store_Id = 0 Then TFV_PP.Value Else NULL End, ValueId = Case When EDFT.Store_Id = 1 Then TFV_PP.Value Else NULL End, 
    EDFT.Field_Type_Desc, EDFT.SP_Lookup, EDFT.Store_Id
    From Table_Fields TF
    Join Table_Fields_Values TFV_PP on TFV_PP.KeyId = @PP_Id and TFV_PP.Table_Field_Id = TF.Table_Field_Id and TFV_PP.TableId = @TableId
    Join ED_FieldTypes EDFT On EDFT.ED_Field_Type_Id = TF.ED_Field_Type_Id
IF @TableId = 7
Begin 
 	 UPDATE @TableFields SET  MyValue= dbo.fnServer_CmnConvertFromDbTime(MyValue, @tz) where EDFieldTypeId = 12
End
IF @RegionalServer = 1
BEGIN
-- 	 DECLARE @T Table  (TimeColumns nvarchar(100))
 	 DECLARE @CHT Table  (HeaderTag Int,Idx Int)
 	 Insert into @CHT(HeaderTag,Idx) Values (20318,1) -- Item Name
 	 Insert into @CHT(HeaderTag,Idx) Values (20312,2) -- Value
-- 	 Select TimeColumns From @T
 	 Select HeaderTag From @CHT Order by Idx
 	 Select [Item Name] = TableFieldDesc, 
 	  	  	 [Value] = MyValue, 
 	  	  	 ValueId, 
 	  	  	 EDFieldTypeId, 
 	  	  	 FieldTypeDesc, 
 	  	  	 SPLookup, 
 	  	  	 StoreId, 
 	  	  	 TableFieldId 
 	  	 From @TableFields
 	  	 Order By TableFieldDesc Asc
END
ELSE
BEGIN
Select TableFieldDesc As 'Name', [Value] = MyValue, ValueId, EDFieldTypeId, FieldTypeDesc, SPLookup, StoreId, TableFieldId From @TableFields
  Order By TableFieldDesc Asc
END
