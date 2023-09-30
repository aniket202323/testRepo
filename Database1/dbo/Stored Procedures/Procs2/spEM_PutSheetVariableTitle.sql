CREATE PROCEDURE dbo.spEM_PutSheetVariableTitle
 	 @SheetId  	 Integer,
 	 @Title 	  	 nvarchar(50),
 	 @Priority 	 Integer,
 	 @Duration 	 Integer,
 	 @TimeToExecute 	  	 Integer,
 	 @UserId 	 Integer,
 	 @ActivityAlias nvarchar(20) =NULL,
 	 @AutoCompleteDuration Integer,
 	 @External_URL_link nvarchar(255),
 	 @Open_URL_Configuration integer,
 	 @User_Login nvarchar(50),
 	 @Password nvarchar(50)
 AS
 /* ##### spEM_PutSheetVariableTitle #####
Description 	 : Updates priority, execution_start_duration, Target duration & alias values which can be passed from Admin - Activity Data Module
Creation Date 	 : NA
Created By 	 : NA
#### Update History ####
DATE 	  	  	  	 Modified By 	  	 UserStory/Defect No 	  	 Comments 	 
---- 	  	  	  	 ----------- 	  	  	 ------------------- 	  	  	  	 --------
2018/02/08 	 Prasad 	  	  	  	  	  	  	  	  	  	  	  	  	 Added Alias column in the update part
*/
  DECLARE @Insert_Id integer
 	 DECLARE @ECId Int,@Isactive tinyint 	  	  	  	  	  	  	  	  
       INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@UserId,'spEM_PutSheetVariableTitle',
                Convert(nVarChar(10),@SheetId) + ','  + 
                	 @Title + ','  + 
                Convert(nVarChar(10),@Priority) + ','  + 
                Convert(nVarChar(10),@Duration) + ','  + 
                Convert(nVarChar(10),@TimeToExecute) + ','  + 
                 Convert(nVarChar(10),@UserId)+','+Convert(nvarchar(20),@ActivityAlias)+','+
 	  	  	  	  Convert(nVarChar(10),@AutoCompleteDuration),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  UPDATE Sheet_Variables SET Activity_Order = @Priority,Execution_Start_Duration = @TimeToExecute,Target_Duration = @Duration   
  ,Activity_Alias = @ActivityAlias --<Changed by Prasad: Added alias column>
  ,AutoComplete_Duration = @AutoCompleteDuration --<KP- Updating AutoCOmplete column>
  ,External_Url_Link = @External_URL_link
  ,Open_URL_Configuration = @Open_URL_Configuration
  ,User_Login = @User_Login
  ,Password = @Password
 	 WHERE  Sheet_Id = @SheetId  AND Title = @Title
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
 	 SELECT @ECId = ec_id,@IsActive = Is_Active FROM Event_Configuration WHERE ED_Model_Id = 49300
 	  --if @AutoCompleteDuration > 0 call the sproc
 	  IF @AutoCompleteDuration > 0 AND @Isactive = 0
 	  	 BEGIN
 	  	  	 EXECUTE dbo.spEM_SystemCompleteActivityAddModel 1
 	  	 END
 	 ELSE IF (Select count(0)  from dbo.Sheet_Variables where AutoComplete_Duration > 0) < 1 AND @Isactive = 1 AND @ECId IS NOT NULL
 	  	 AND (Select count(0) from Sheet_Display_Options where Display_Option_Id = 460 and value > 0) < 1
 	  	 BEGIN
 	  	  	 EXECUTE dbo.spEM_SystemCompleteActivityAddModel 0
 	  	 END
 	  	 
 	  	  	  	  	  	  	  	  	  	  	 
RETURN(0)
