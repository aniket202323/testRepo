CREATE Procedure dbo.spEMTFV_PutFieldValues
 	 @KeyId 	  	 int,
 	 @TableId 	 int,
 	 @TableFieldId int,
 	 @StoreId 	 Int,
 	 @UserId int,
 	 @Value nvarchar(3000),
 	 @tz varchar(100) = 'UTC'
AS
Declare @InsertId int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@UserId,'spEMTFV_PutFieldValues',
             Convert(nVarChar(10),@KeyId) + ','  + 
             Convert(nVarChar(10),@TableId) + ','  + 
             Convert(nVarChar(10),@TableFieldId) + ','  + 
             Convert(nVarChar(10),@StoreId) + ','  + 
             Convert(nVarChar(10),@UserId) + ','  + 
             @Value, dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @InsertId = Scope_Identity()
SELECT @Value = LTrim(RTrim(@Value))
IF @Value = '' 
 	 SET @Value = NULL
IF @Value = '-1' and @StoreId = 1 
 	 SET @Value = NULL
 	 
IF EXISTS( 	 
Select 1 from Tables T join Table_Fields TF on TF.TableId = T.TableId AND TF.Table_Field_Id = @TableFieldId Join ED_FieldTypes EF on EF.ED_Field_Type_Id = TF.ED_Field_Type_Id
WHere T.TableId = @TableId AND EF.ED_Field_Type_Id=12) and @TableId = 7 --Only handling for Production Plan Table
Begin
 	 SET @Value = dbo.fnServer_CmnConvertToDbTime(@value, @tz)
End
If @Value is NULL
BEGIN
-- 	 IF @TableFieldId > 0 ***** No way to know if these are "system defaults so allow delete *****
 	  	 Delete From Table_Fields_Values Where KeyId = @KeyId and TableId = @TableId and Table_Field_Id = @TableFieldId
-- 	 ELSE
-- 	 BEGIN
-- 	  	 UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = -100
-- 	  	 WHERE Audit_Trail_Id = @InsertId
-- 	  	 RETURN -100
-- 	 END
END
ELSE
BEGIN
 	 IF EXISTS(SELECT * FROM Table_Fields_Values WHERE KeyId = @KeyId and TableId = @TableId and Table_Field_Id = @TableFieldId)
 	 BEGIN
 	  	 UPDATE Table_Fields_Values Set [Value] = @Value Where KeyId = @KeyId and TableId = @TableId and Table_Field_Id = @TableFieldId
 	 END
 	 ELSE
 	 BEGIN
 	  	 INSERT INTO Table_Fields_Values (TableId,KeyId,Table_Field_Id,[Value]) VALUES (@TableId,@KeyId,@TableFieldId,@Value)
 	 END
END
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @InsertId
RETURN 0
