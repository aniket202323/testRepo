Create Procedure dbo.spEMAC_CreateNewAT
@User_Id int,
@NewATDesc nvarchar(50) OUTPUT
AS
declare @x int,
@ID int,
@Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMAC_CreateNewAT', 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
select @x = 0
NextAvailDesc:
select @x = @x + 1
select @ID = Null
select @ID = at_id from alarm_templates
where at_desc = 'Alarm Template ' + Convert(nVarChar(10), @x)
if @ID is Null
  Begin
    select @NewATDesc = 'Alarm Template ' + Convert(nVarChar(10), @x)
  End
else
  Begin
    goto NextAvailDesc
  End
insert into alarm_templates(AT_Desc, AP_Id) values (@NewATDesc, 1)
select @NewATDesc
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
