Create Procedure dbo.spEMAC_UpdateAttachedVariables 
 	 @AT_Id 	  	 int,
 	 @Var_Id 	  	 int,
 	 @Data 	  	 int,
 	 @User_Id 	 int,
 	 @updateSize 	 Int = 0
AS
Declare @Insert_Id int, @Alarm_Type_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMAC_UpdateAttachedVariables',
             Convert(nVarChar(10),@AT_Id) + ','  + 
 	            Convert(nVarChar(10),@Var_Id) + ','  + 
 	            Convert(nVarChar(10),@Data) + ','  + 
 	            Convert(nVarChar(10),@updateSize) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
IF @updateSize Is Null SET @updateSize = 0
IF @updateSize = 0
BEGIN
 	 IF @Data = 0 SET @Data = NULL
END
ELSE
BEGIN
 	 IF @Data Is Null SET @Data = 0
END
IF @updateSize = 0
BEGIN
 	 Update Alarm_template_var_data Set EG_Id = @Data
 	 Where AT_Id = @AT_Id
 	 and Var_Id = @Var_Id
END
ELSE
 	 BEGIN
 	  	 Update Alarm_template_var_data Set Sampling_Size = @Data
 	  	  	 Where AT_Id = @AT_Id and Var_Id = @Var_Id
 	  	 IF @Data > 0 
 	  	  	 Update Alarm_template_var_data Set Sampling_Size = @Data
 	  	  	  	 Where  Var_Id = @Var_Id and Sampling_Size > 0 and AT_Id != @AT_Id
 	 END
Select @Alarm_Type_Id = Alarm_Type_Id from Alarm_Templates Where AT_Id = @AT_Id
If @Alarm_Type_Id = 4
Begin
 	 IF @updateSize = 0
 	  	 Update Alarm_Template_Var_Data Set EG_Id = @Data
 	  	   Where AT_Id = @AT_Id and Var_Id in (Select Var_Id from Variables Where PVar_Id = @Var_Id)
 	 ELSE
 	  	 BEGIN
 	  	  	 Update Alarm_Template_Var_Data Set Sampling_Size = @Data
 	  	  	   Where AT_Id = @AT_Id and Var_Id in (Select Var_Id from Variables Where PVar_Id = @Var_Id)
 	  	  	 IF @Data > 0 
 	  	  	  	 Update Alarm_Template_Var_Data Set Sampling_Size = @Data
 	  	  	  	   Where AT_Id != @AT_Id and Var_Id in (Select Var_Id from Variables Where PVar_Id = @Var_Id) and Sampling_Size > 0 
 	  	 END
End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
