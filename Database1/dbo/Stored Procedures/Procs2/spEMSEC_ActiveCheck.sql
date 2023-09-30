/*
spEMSEC_ActiveCheck 360,1
*/
CREATE Procedure dbo.spEMSEC_ActiveCheck
@ECId 	  	 INT,
@UserId 	  	 INT
AS
DECLARE @ModelId INt
DECLARE @SpName nVarChar(100)
DECLARE  @xTypeId 	 INT,
 	  	 @FieldDesc nVarChar(100),
 	  	 @FieldOrder INT,
 	  	 @ISError 	 Int,
 	  	 @ExpectedCount 	 Int
DECLARE @Errors TABLE (ID Integer,[Error Description] nvarchar(1000))
DECLARE @NonOptionalFields TABLE (FieldId Int,FieldDesc nVarChar(100),FieldOrder Int Null)
SELECT @ModelId = ED_Model_Id
 	 FROM Event_Configuration
 	 WHERE EC_ID = @ECId
/* Check For Model Number */
IF @ModelId Is Null
BEGIN
 	 INSERT INTO  @Errors(Id,[Error Description]) 
 	  	 SELECT  1,'Error - No Model assigned'
 	 GOTO myExit
END
/* Check Optional Fields */
INSERT INTO @NonOptionalFields(FieldId,FieldDesc)
 	 SELECT ed_Field_Id,Field_Desc
 	 FROM ed_Fields
 	 WHere ed_Model_Id = @ModelId and Optional = 0 and Field_Desc not like '%reserved%'
INSERT INTO  @Errors(Id,[Error Description]) 
 	 SELECT  FieldId,'Field Error - [' + FieldDesc + '] is not optional'
 	 FROM @NonOptionalFields
 	 WHERE FieldId Not IN (SELECT ED_Field_Id FROM event_configuration_Data ecd
 	  	  	  	  	  	  	 Join  event_configuration_Values ecv ON ecv.ECV_Id = ecd.ECV_Id and (ecv.Value is not null and ltrim(rtrim(substring(ecv.Value,1,2))) != '')
 	  	  	  	  	  	  	 WHERE EC_Id = @ECId)
DELETE FROM @NonOptionalFields
/* Check for triggers on VB SCript models (downtime/Waste/UDE/CrewShift,GradeChange,Production Event) */
IF @ModelId IN(30,31,32,5401,5402,5403,5404,5404)
BEGIN
 	 INSERT INTO @NonOptionalFields(FieldId,FieldDesc)
 	  	 SELECT ed_Field_Id,Field_Desc
 	  	 FROM ed_Fields
 	  	 WHere ed_Model_Id = @ModelId and Max_Instances > 1 and ED_Field_Type_Id = 3
 	 INSERT INTO  @Errors(Id,[Error Description]) 
 	  	 SELECT  FieldId,'Field Error - [' + FieldDesc + '] no trigger tag found'
 	  	 FROM @NonOptionalFields
 	  	 WHERE FieldId Not IN (SELECT ED_Field_Id FROM event_configuration_Data ecd
 	  	  	  	  	  	  	  	 Join  event_configuration_Values ecv ON ecv.ECV_Id = ecd.ECV_Id and ecd.IsTrigger = 1 and (ecv.Value is not null and ltrim(rtrim(substring(ecv.Value,1,2))) != '')
 	  	  	  	  	  	  	  	 WHERE EC_Id = @ECId)
END
DELETE FROM @NonOptionalFields
IF @ModelId IN (select ed_Model_Id from ed_Models where ed_Model_Id = 5191 or Derived_From = 603)
BEGIN
 	 SELECT @SpName = ecv.Value
 	 FROM event_configuration_Data ecd
 	 Join  event_configuration_Values ecv ON ecv.ECV_Id = ecd.ECV_Id
 	 WHERE EC_Id = @ECId and (ed_Field_Id =  1337 or ed_Field_Id IN (select ed_Field_Id from ed_fields where  Derived_From = 1337))
 	 INSERT INTO @NonOptionalFields(FieldId,FieldDesc,FieldOrder)
 	  	 select sc.xtype,sc.Name,sc.colid
 	  	 from sysobjects so
 	  	 JOIN syscolumns sc on sc.id = so.id
 	  	 where so.name = @SpName
 	 IF @SpName Is Null
 	  	 GOTO myExit
 	 Declare @NumFields 	 Int
 	 SELECT @NumFields = COUNT(*) FROM @NonOptionalFields
 	 SELECT @ExpectedCount = 12 + COUNT(*) * 4 
 	  	 FROM Event_configuration_Data ecd
 	  	 Join  event_configuration_Values ecv ON ecv.ECV_Id = ecd.ECV_Id and (ecv.Value is not null and ltrim(rtrim(substring(ecv.Value,1,2))) != '')
 	  	 JOIN ED_FIELDS ef 	 On ef.ED_Field_Id = ecd.ED_Field_Id and ef.ED_Field_Type_Id = 3
 	     WHERE EC_Id = @ECId
 	 IF @NumFields < 16
 	 BEGIN
 	  	 INSERT INTO  @Errors(Id,[Error Description]) 
 	  	  	  	 SELECT  1,'Stored Procedure [' + @SpName + '] needs a minimum of 16 Inputs/Outputs'
 	  	 
 	  	 GOTO myExit
 	 END
 	 IF @ExpectedCount < 16
 	 BEGIN
 	  	 INSERT INTO  @Errors(Id,[Error Description]) 
 	  	  	  	 SELECT  1,'Stored Procedure [' + @SpName + '] must have the minimum of 1 Tag'
 	  	 GOTO myExit
 	 END
 	 IF @NumFields <> @ExpectedCount
 	 BEGIN
 	  	 INSERT INTO  @Errors(Id,[Error Description]) 
 	  	  	  	 SELECT  1,'Expected [' + Convert(nVarChar(10),@ExpectedCount)+ '] Inputs/Outputs for [' + @SpName + '] '
 	  	 
 	  	 GOTO myExit
 	 END
 	 DECLARE FieldCursor Cursor For
 	  	 SELECT  FieldId,FieldDesc,FieldOrder
 	  	 FROM @NonOptionalFields
 	 OPEN FieldCursor
FieldCursorLoop:
 	 Fetch Next From FieldCursor Into @xTypeId,@FieldDesc,@FieldOrder
 	 If @@Fetch_Status = 0
 	 BEGIN
 	  	 SELECT @ISError = 0
 	  	 Select @ISError = Case WHEN @FieldOrder in (1,4,8) And @xTypeId <> 56 THEN 1
 	  	  	  	  	  	  	    WHEN @FieldOrder in (2,5,6,7,9,10,13,14) And @xTypeId <> 167 THEN 1
 	  	  	  	  	  	  	    WHEN @FieldOrder in (3,11,12,15,16) And @xTypeId <> 61 THEN 1
 	  	  	  	  	  	  	    WHEN (@FieldOrder > 16) AND (@FieldOrder % 4 = 1) And @xTypeId <> 167 THEN 1 
 	  	  	  	  	  	  	    WHEN (@FieldOrder > 16) AND (@FieldOrder % 4 = 2) And @xTypeId <> 167 THEN 1 
 	  	  	  	  	  	  	    WHEN (@FieldOrder > 16) AND (@FieldOrder % 4 = 3) And @xTypeId <> 61 THEN 1 
 	  	  	  	  	  	  	    WHEN (@FieldOrder > 16) AND (@FieldOrder % 4 = 0) And @xTypeId <> 61 THEN 1 
 	  	  	  	  	  	  	    ELSE 0
 	  	  	  	  	  	   END
 	  	 IF  @ISError = 1
 	  	 BEGIN
 	  	  	 INSERT INTO  @Errors(Id,[Error Description]) 
 	  	  	  	 SELECT  @FieldOrder,'Stored Procedure Error [' + @FieldDesc + '] should NOT be Data Type [' + name  + ']'
 	  	  	  	 from systypes
 	  	  	  	 WHERE xusertype = @xTypeId
 	  	 END
 	  	 GOTO FieldCursorLoop
 	 END
 	 Close FieldCursor
 	 Deallocate FieldCursor
END
myExit:
SELECT * FROM @Errors
