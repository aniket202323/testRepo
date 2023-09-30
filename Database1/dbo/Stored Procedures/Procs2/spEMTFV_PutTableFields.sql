CREATE Procedure dbo.spEMTFV_PutTableFields
 	 @TableId 	  	 Int,
 	 @FieldTypeId 	 Int,
 	 @FieldDesc 	  	 nvarchar(1000),
 	 @FieldId 	  	 Int,
 	 @UserId 	  	  	 Int,
 	 @NewId 	  	  	 Int OutPut,
 	 @Tag 	  	  	 nvarchar(1000) Output
AS
Declare @InsertId int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@UserId,'spEMTFV_PutTableFields',
             Convert(nVarChar(10),@TableId) + ','  + 
             Convert(nVarChar(10),@FieldTypeId) + ','  + 
             substring(@FieldDesc,1,200) + ','  + 
             Convert(nVarChar(10),@UserId) , dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @InsertId = Scope_Identity()
SELECT @FieldDesc = LTrim(RTrim(@FieldDesc))
IF @FieldDesc = '' 
 	 SET @FieldDesc = NULL
If @FieldDesc is NULL
BEGIN
 	 IF EXISTS(SELECT * FROM Table_Fields_Values WHERE Table_Field_Id = @FieldId) 
 	 BEGIN
 	  	 SELECT @NewId = -100
 	  	 GOTO spEnd
 	 END
 	 IF @FieldId IS Not NULL
 	  	 DELETE FROM Table_Fields WHERE Table_Field_Id = @FieldId
END
ELSE
BEGIN
 	 IF EXISTS(SELECT * FROM Table_Fields WHERE  TableId = @TableId AND Table_Field_Desc = @FieldDesc)
 	 BEGIN
 	  	 SELECT @NewId = -200
 	  	 GOTO spEnd
 	 END
 	 ELSE
 	 BEGIN
 	  	 INSERT INTO Table_Fields (TableId,ED_Field_Type_Id,Table_Field_Desc) VALUES (@TableId,@FieldTypeId,@FieldDesc)
 	  	 SELECT @NewId = Table_Field_Id FROM Table_Fields WHERE TableId = @TableId AND Table_Field_Desc = @FieldDesc
 	  	 IF @NewId Is Null
 	  	 BEGIN
 	  	  	 SELECT @NewId = -300
 	  	  	 GOTO spEnd
 	  	 END
 	  	 SELECT @TAG = Char(1) + '1' + Char(1) + convert(nVarChar(25),@FieldTypeId) + Char(2) + dbo.fnEM_TableFieldTagCmn(@NewId,@TableId) 
 	 END
END
spEnd:
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @InsertId
