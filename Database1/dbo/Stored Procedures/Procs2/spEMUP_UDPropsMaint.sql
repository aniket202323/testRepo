CREATE Procedure dbo.spEMUP_UDPropsMaint
@KeyId int,
@TableId int,
@Table_Field_Id int,
@User_Id int,
@Value varchar(7000) = NULL,
@Description nvarchar(50) = NULL
AS
Declare @Insert_Id int
Declare @StoreId   Int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMUP_UDPropsMaint',
             Convert(nVarChar(10),@KeyId) + ','  + 
             Convert(nVarChar(10),@TableId) + ','  + 
             Convert(nVarChar(10),@Table_Field_Id) + ','  + 
             Convert(nVarChar(10),@User_Id) + ','  + 
             @Value, dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
select @StoreId = Store_Id from Ed_FieldTypes where ED_Field_Type_Id = (select ED_Field_Type_Id from Table_Fields where  Table_Field_Id = @Table_Field_Id)
Select @StoreId = isnull(@StoreId,0)
Select @Value = LTrim(RTrim(@Value))
If @Value is NULL
  Begin
    Delete From Table_Fields_Values Where KeyId = @KeyId and TableId = @TableId and Table_Field_Id = @Table_Field_Id
  End
Else
  Begin
    If @Value = '' or (@Value = '-1' and @StoreId = 1)
 	  Select @Value = NULL
    Update Table_Fields_Values Set Value = @Value Where KeyId = @KeyId and TableId = @TableId and Table_Field_Id = @Table_Field_Id
    Update Table_Fields Set Table_Field_Desc = @Description Where Table_Field_Id = @Table_Field_Id
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
