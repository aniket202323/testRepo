Create Procedure dbo.spEMDT_UpdateEventCfg
@EC_Id int,
@EC_Desc nvarchar(50),
@User_Id int
AS
declare @Id int, @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMDT_UpdateEventCfg',
             Convert(nVarChar(10),@EC_Id) + ','  + 
             @EC_Desc + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
Update Event_Configuration set EC_Desc = @EC_Desc Where EC_Id = @EC_Id
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
