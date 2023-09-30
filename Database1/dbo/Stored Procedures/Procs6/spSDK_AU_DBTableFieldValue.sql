CREATE procedure [dbo].[spSDK_AU_DBTableFieldValue]
@AppUserId int,
@KeyId int,
@DBTableFieldId int,
@DBTableField varchar(100),
@DBTableId int,
@DBTable varchar(100),
@Value varchar(4000)
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
 	  	 
 	 If (@DBTableFieldId Is NULL)
 	  	 Select @DBTableFieldId = Table_Field_Id From Table_Fields Where (Table_Field_Desc = @DBTableField) And (TableId = @DBTable)  	  	 
 	  	 
 	 If (@DBTableFieldId Is NULL)
 	  	 Begin
 	  	  	 Select 'Error: Unable to determine DBTableFieldId'
 	  	  	 Return(0)
 	  	 End
 	 
 	 Select @AllowUserDefinedProperty = NULL
 	 Select @AllowUserDefinedProperty = Allow_User_Defined_Property From Tables Where TableId = @DBTableId
 	 If (@AllowUserDefinedProperty Is NULL) Or (@AllowUserDefinedProperty <> 1)
 	  	 Begin
 	  	  	 Select 'Error: Operation not permitted on TableId[' + CONVERT(varchar(100),@DBTableId) + ']'
 	  	  	 Return(0)
 	  	 End
 	 If Exists(Select 1 From Table_Fields_Values Where (KeyId = @KeyId) And (TableId = @DBTableId) And (Table_Field_Id = @DBTableFieldId))
 	  	 Begin
 	  	  	 Update Table_Fields_Values 
 	  	  	  	 Set Value = @Value
 	  	  	  	  	 Where (KeyId = @KeyId) And (TableId = @DBTableId) And (Table_Field_Id = @DBTableFieldId)
 	  	 End
 	 Else
 	  	 Begin
 	  	  	 Insert Into Table_Fields_Values (KeyId,Table_Field_Id,TableId,Value)
 	  	  	  	 Values(@KeyId,@DBTableFieldId,@DBTableId,@Value)
 	  	 End
 	 
Return(1)
