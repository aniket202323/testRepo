Create Procedure dbo.spEMAC_UpdateDetailsVariable
@AT_Id int,
@Var_Id int = NULL,
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMAC_UpdateDetailsVariable',
             Convert(nVarChar(10),@AT_Id) + ','  + 
 	 Convert(nVarChar(10),@Var_Id) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
if @Var_Id is NULL
    update alarm_templates set DQ_Var_Id = NULL, DQ_Criteria = NULL, DQ_Value = NULL where at_id = @AT_Id
else  
  update alarm_templates set DQ_Var_Id = @Var_Id where at_id = @AT_Id
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
