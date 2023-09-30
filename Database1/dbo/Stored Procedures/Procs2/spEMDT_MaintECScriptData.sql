Create Procedure dbo.spEMDT_MaintECScriptData
@ECID int, 
@PU_Id int, 
@EDFieldTypeId int, 
@Alias nvarchar(50),
@User_Id int,
@ECVId int OUTPUT
 AS 
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMDT_MaintECScriptData',
             Convert(nVarChar(10),@ECID) + ','  + 
             Convert(nVarChar(10),@PU_Id) + ','  + 
             Convert(nVarChar(10),@EDFieldTypeId) + ','  + 
 	 @Alias + ',' +
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
Declare @EDFieldId int
Select @EDFieldId = ED_Field_Id 
  From ED_Fields f
  JOIN Event_Configuration c on c.ED_Model_Id = f.ED_Model_Id and c.EC_id = @ECId
  Where  f.ED_Field_Type_Id = @EDFieldTypeId
if @PU_Id = 0 
  SELECT @PU_Id = NULL
SELECT @ECVId = NULL 
If @Alias IS NULL 
  SELECT @ECVId = ECV_Id
    FROM Event_Configuration_Data  d
--  JOIN Event_Configuration c on c.EC_id = d.EC_Id
--  JOIN ED_Fields f on f.ED_model_Id = c.ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.ED_Field_Type_Id = @EDFieldTypeId
    WHERE d.EC_Id = @ECId and d.Ed_Field_Id = @EDFieldId and PU_Id = @PU_Id
else 
  SELECT @ECVId = ECV_Id
    FROM Event_Configuration_Data  d
--  JOIN Event_Configuration c on c.EC_id = d.EC_Id
--  JOIN ED_Fields f on f.ED_model_Id = c.ED_Model_Id and d.ED_Field_Id = f.ED_Field_Id and f.ED_Field_Type_Id = @EDFieldTypeId
    WHERE d.EC_Id = @ECId and d.Ed_Field_Id = @EDFieldId and PU_Id = @PU_Id and Alias = @Alias
if @ECVId is null 
  BEGIN
    Insert into Event_Configuration_Values (Value) Values('')
    Select @ECVId = IDENT_CURRENT('event_configuration_values')
    Insert into Event_Configuration_Data (EC_Id, ED_Field_Id, Alias, PU_Id, ECV_Id)
      values (@ECID, @EDFieldId, @Alias, @PU_Id, @ECVId)
  END
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
