CREATE Procedure dbo.spEMDT_DeleteEC
@EC_Id int,
@User_Id int
as
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMDT_DeleteEC',
             Convert(nVarChar(10),@EC_Id) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
create table #ids(theId int)
Insert Into #Ids
  select ECV_Id from event_configuration_data where ec_id = @EC_Id
delete from event_configuration_data 
where ec_id = @EC_Id
delete from event_configuration_values
where event_configuration_values.ecv_id in (select theId from #Ids)
Declare @Comment_Id int
Select @Comment_Id = Comment_Id from Event_Configuration where EC_Id = @EC_Id
if @Comment_Id is not null
  exec spCSS_InsertDeleteComment @EC_Id, 27, @User_Id, 1, null, @Comment_Id
delete from event_configuration 
where ec_id = @EC_Id
drop table #ids
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
