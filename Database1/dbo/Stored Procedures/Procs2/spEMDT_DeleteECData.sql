Create Procedure dbo.spEMDT_DeleteECData
@EC_Id int,
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMDT_DeleteECData',
             Convert(nVarChar(10),@EC_Id) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
create table #ids(theId int)
Insert Into #Ids
  select ECV_Id 
   from event_configuration_data d
   join ed_fields f on f.ed_field_id = d.ed_field_id and f.ed_field_type_id = 3 --and Max_Instances > 1
  where ec_id = @EC_Id 
Delete  event_configuration_data 
   from event_configuration_data d
   join ed_fields f on f.ed_field_id = d.ed_field_id and f.ed_field_type_id = 3 --and Max_Instances > 1
  where ec_id = @EC_Id 
delete from event_configuration_values
where event_configuration_values.ecv_id in (select theId from #Ids)
drop table #ids
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
