CREATE procedure [dbo].[spSDK_AU_DBTableField_Bak_177]
@AppUserId int,
@Id int OUTPUT,
@DBTableField varchar(100),
@FieldTypeId int,
@DBTableId int,
@DBTable varchar(100)
AS
 	 Declare
 	  	 @AllowUserDefinedProperty int
 	 If (@DBTableId Is NULL)
 	  	 Select @DBTableId = TableId From Tables Where TableName = @DBTable
 	 If (@DBTableId Is NULL)
 	  	 Begin
 	  	  	 Select 'Error: Unable to determine DBTableId'
 	  	  	 Return(0)
 	  	 End
 	  	 
 	 Select @AllowUserDefinedProperty = NULL
 	 Select @AllowUserDefinedProperty = Allow_User_Defined_Property From Tables Where TableId = @DBTableId
 	 If (@AllowUserDefinedProperty Is NULL) Or (@AllowUserDefinedProperty <> 1)
 	  	 Begin
 	  	  	 Select 'Error: Operation not permitted on TableId[' + CONVERT(varchar(100),@DBTableId) + ']'
 	  	  	 Return(0)
 	  	 End
 	 If (@Id Is NULL)
 	  	 Begin
 	  	  	 Insert Into Table_Fields(Table_Field_Desc,ED_Field_Type_Id,TableId) Values(@DBTableField,@FieldTypeId,@DBTableId)
 	  	  	 Select @Id = NULL
 	  	  	 Select @Id = Table_Field_Id From Table_Fields Where TableId = @DBTableId And Table_Field_Desc = @DBTableField
 	  	  	 If (@Id Is NULL)
 	  	  	  	 Begin
 	  	  	  	  	 Select 'Error: Adding Table Field'
 	  	  	  	  	 Return(0)
 	  	  	  	 End
 	  	 End
 	 Else
 	  	 Begin
 	  	  	 Update Table_Fields Set Table_Field_Desc = @DBTableField, ED_Field_Type_Id = @FieldTypeId, TableId = @DBTableId
 	  	  	  	 Where Table_Field_Id = @Id
 	  	 End
 	 
 	 Return(1)
 	 
