Create Procedure dbo.spEMEC_UpdEventConfigAdvanced
@EC_Id int,
@Extended_Info nvarchar(255),
@Exclusions nvarchar(255),
@User_Id int
AS
declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEC_UpdEventConfigAdvanced',
             Convert(nVarChar(10),@EC_Id) + ','  + 
             @Extended_Info + ','  + 
             @Exclusions + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
update event_configuration set extended_info = @Extended_Info, exclusions = @Exclusions
where ec_id = @EC_Id
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
