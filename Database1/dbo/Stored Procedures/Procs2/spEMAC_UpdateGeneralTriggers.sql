Create Procedure dbo.spEMAC_UpdateGeneralTriggers
@AT_Id int,
@Alarm_Variable_Rule_Id int,
@AP_Id int,
@Check bit,
@User_Id int
AS
Declare @Insert_Id int
Declare @Exists int
Declare @ATVRDId Int
DECLARE @EGId 	 INT
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMAC_UpdateGeneralTriggers',
             Convert(nVarChar(10),@AT_Id) + ','  + 
             Convert(nVarChar(10),@Alarm_Variable_Rule_Id) + ','  + 
             Convert(nVarChar(10),@AP_Id) + ','  + 
             Convert(nVarChar(10),@Check) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
if @Check = 1
  Begin
    Select @Exists = count(*) from Alarm_Template_Variable_Rule_Data Where AT_Id = @AT_Id and Alarm_Variable_Rule_Id = @Alarm_Variable_Rule_Id
    if @Exists = 0
      Begin
        Insert into Alarm_Template_Variable_Rule_Data (AT_Id, Alarm_Variable_Rule_Id, AP_Id)
          values (@AT_Id, @Alarm_Variable_Rule_Id, @AP_Id)
 	  	 Select @ATVRDId = Scope_Identity()
 	  	 Insert into Alarm_Template_Var_Data (AT_Id, Var_Id, EG_Id, ATVRD_Id)
 	  	  	 Select Distinct AT_Id,Var_Id, Max(EG_Id),@ATVRDId
 	  	  	  From Alarm_Template_Var_Data Where AT_Id = @AT_Id
 	  	  	 GROUP BY AT_Id,Var_Id
      End
    else
      Begin
        Update Alarm_Template_Variable_Rule_Data set  AP_Id = @AP_Id
        Where AT_Id = @AT_Id and Alarm_Variable_Rule_Id = @Alarm_Variable_Rule_Id
      End
  End
else
  Begin
    Delete from Alarm_Template_Var_Data
 	 From Alarm_Template_Var_Data a
 	 Join Alarm_Template_Variable_Rule_Data b on b.ATVRD_Id = a.ATVRD_Id
       	 Where b.AT_Id = @AT_Id and b.Alarm_Variable_Rule_Id = @Alarm_Variable_Rule_Id
    Delete from Alarm_Template_Variable_Rule_Data
      Where AT_Id = @AT_Id and Alarm_Variable_Rule_Id = @Alarm_Variable_Rule_Id
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
