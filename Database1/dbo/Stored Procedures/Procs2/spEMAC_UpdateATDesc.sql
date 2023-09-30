Create Procedure dbo.spEMAC_UpdateATDesc
@AT_Desc nvarchar(50),
@AT_Id int,
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMAC_UpdateATDesc',
 	 @AT_Desc + ',' +
             Convert(nVarChar(10),@AT_Id) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
Declare @Exists int
select @Exists = count(*) from alarm_templates 
where AT_Desc = @AT_Desc
and AT_Id <> @AT_Id
if @Exists > 0
  BEGIN
    UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = -100
    WHERE Audit_Trail_Id = @Insert_Id
    RETURN(-100)
  END
update alarm_templates set AT_Desc = @AT_Desc where at_id = @AT_Id
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
RETURN(0)
