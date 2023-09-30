CREATE Procedure dbo.spSV_UDPropsMaint
@ToKeyId int,
@ToTableId int,
@Table_Field_Id int,
@Value varchar(7000) = NULL
AS
If LTrim(RTrim(@Value)) = '' or LTrim(RTrim(@Value)) = '-1' Select @Value = NULL
If @Table_Field_Id > 0
  Begin
    If (Select Count(*) From Table_Fields_Values Where KeyId = @ToKeyId and TableId = @ToTableId and Table_Field_Id = @Table_Field_Id) = 0
      Begin
        Insert Into Table_Fields_Values (KeyId, TableId, Table_Field_Id, Value) Values (@ToKeyId, @ToTableId, @Table_Field_Id, @Value)
      End
    Else
      Begin
        Update Table_Fields_Values Set Value = @Value Where KeyId = @ToKeyId and TableId = @ToTableId and Table_Field_Id = @Table_Field_Id
      End
  End
Else
  Begin
    If @Table_Field_Id = -1
      Update Production_Plan Set User_General_1 = @Value Where PP_Id = @ToKeyId
    Else If @Table_Field_Id = -2
      Update Production_Plan Set User_General_2 = @Value Where PP_Id = @ToKeyId
    Else If @Table_Field_Id = -3
      Update Production_Plan Set User_General_3 = @Value Where PP_Id = @ToKeyId    
  End
