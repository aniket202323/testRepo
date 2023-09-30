 /*  
Stored Procedure: spLocal_ValidatePerfectRoll  
Author:   Eric Perron (STI)  
Date Created: 08/16/05  
  
Description:  
=========  
This procedure is triggered by a calculation to validate   
if we need to change the status from complete to perfect OR perfect to complete  
  
  
CALLS: dbo.fnLocal_GlblParseInfo  
  
Change Date Who  What  
======== ==== =====  
08/16/05  EP  Created procedure.  
08/24/05  EP  Added validation for Quarantine  
08/30/05  EP  Removed invalid convert  
09/12/05  FGO  Added a change to the Status variable for  alamring  
10/04/05  EP  don't change the status when the roll is ‘Reject’, ‘Consumed’, ’Received’ we will only update the variable  
10/04/05  EP  If a result is null for the present column, get the latest test for that variable to do the compare.   
10/17/05  FGO  Updated for the new statused  
02/09/06    FGO   Changed to allow recalculation and updating of the recalc variable  
       Changed code to match current coding practices  
       Changed code to only look at current product  
02/15/06  FGO  Changed the method to update comments and refresh the client  
03/21/06  FGO  Changed the write back of the Recalcualte PPR variable to handle many changes  
03/23/06  FGO  Commented out the Not Perfect Stuff from the code since that status is being dropped  
03/29/06  FGO  Corrected the problem with writting back the Recalculation PPR variable  
04/04/06  FGO  Made the time wait check to write back a parm of the calc  
04/25/06  FGO  Added the Comment that goes to the PPR variable to the event as well  
      cleaned up the code  
      corrected the comment when the result has been corrected  
      added the ability to comment previous reuslts to the current event  
05/08/06  FGO  Updating the commenting stuff for v4.x  
03/14/07  FGO  Made Correction Again for time set back on start of the call  
04/07/07  FGO  Updated for the following  
       Do not update Status if the status is Fire or Hold  
       Find @CompleteStatusID correctly  
       Set the app_versions once   
08/01/07  FGO  Added with nolock  
09/27/07  fgo  updated the code moved the recalc and comment code in to the event change block of code   
       added if the current event status is one on the do not change status end the code        
*/  
  
CREATE                   PROCEDURE dbo.spLocal_ValidatePerfectRoll  
--DECLARE  
@ErrorMsg  varchar(25) OUTPUT,  
--@ErrorMsg  varchar(25),  
@Timestamp datetime,  
@varid   int,  
@WaitTime  int  
--select @timestamp = '9/27/07 17:43:31',@varid = 64305,@WaitTime = 8  
  
AS  
  
/*  
Declare  
@ErrorMsg  varchar(255)  
  
EXEC spLocal_ValidatePerfectRoll_ep @ErrorMsg OUTPUT , '21-sep-2005 22:47:43' ,57845  
  
select @ErrorMsg  
  
*/  
  
Declare     
   @ProdId      int,  
   @varcount     int,  
   @Userid      int,  
   @PerfectStatusid    int,  
   @Eventid      int,  
   @Eventstatus    int,  
   @CompleteStatusid   int,  
   @Calcid      int,  
   @newstatusid    int,  
   @NotPerfectstatusid   int,  
   @Holdstatusid    int,  
   @Rejectstatusid    int,  
   @FlaggedStatusid    int,  
   @ReceivedStatusid   int,  
   @ConsumedStatusid   int,  
   @puid      int,  
   @StrSQL     varchar(5000),  
   @StatusDesc    varchar(25),  
   @ProdDate     datetime,  
   @PPRVarID     int,  
   @Comment     varchar(500),  
   @CommentID    int,  
   @HasComment    int,  
   @PerfectValue    varchar(25),  
   @newcomment    varchar(500),  
   @curtime     datetime,  
   @LinkStr     varchar(100), --This is the external_link string to find in the sheets table to inculde the sheet  
   @PPREventComment   varchar(100),     
   @PPREventCommentFinal varchar(5000),  
   @CommentSource   int,    --this is the comment source for Autolog  
   @FireStatusID    int,    -- this was added on 4/7/07  
   @AppVersion    varchar(25)  --this was added 4/7/07  
  
DECLARE @tblvar TABLE (var_id int,Value varchar(30), L_Reject varchar(30),L_Warning varchar(30),L_Entry varchar(30),U_User varchar(30),Target varchar(30),L_User varchar(30),U_Entry varchar(30),U_Warning varchar(30),U_Reject varchar(30), result_on datetime
,var_desc varchar(50),Comment_Result varchar(3))  
DECLARE @VariableUpdates TABLE (var_id int, pu_id int, user_id int, canceled int, result varchar(25), result_on datetime, transaction_type int, postupdate int,entry_on datetime)  
  
SET NOCOUNT ON  
  
 SELECT @curtime = getdate()  
 IF abs(datediff(day,@curtime,@Timestamp)) >1  
  Begin  
   SELECT @ErrorMsg = 'DONOTHING'  
   GOTO ReturnData  
  END  
 /*  INIT  */  
 SELECT @varcount = 0  
 SELECT @Puid = Pu_id FROM dbo.variables with(nolock) where var_id = @varid  
 SELECT @CommentSource = CS_ID FROM dbo.Comment_Source with(nolock) where cs_Desc = 'Autolog'  
  
  
 /* get @AppVersion */  
  SELECT  @AppVersion = app_version FROM dbo.appversions with(nolock) WHERE app_name = 'Database'  
 /* Complete Status */  
 IF (@AppVersion) > 400000.000  
  BEGIN  
   SELECT  @CompleteStatusid = prodStatus_id  
    FROM dbo.production_status with(nolock)  
    WHERE coalesce(Prodstatus_desc_global,Prodstatus_desc_local) = 'Complete'  
  END  
 ELSE  
  SELECT @CompleteStatusid = prodStatus_id  
  FROM dbo.production_status with(nolock)  
  WHERE Prodstatus_desc = 'Complete'  
 IF @CompleteStatusid IS null  
  BEGIN  
   SELECT @ErrorMsg = 'Complete Status NOT FOUND'  
   GOTO ReturnData  
  END  
 /* Fire Status */  
 IF (@AppVersion) > 400000.000  
  BEGIN  
   SELECT  @FireStatusid = prodStatus_id  
    FROM dbo.production_status with(nolock)  
    WHERE coalesce(Prodstatus_desc_global,Prodstatus_desc_local) = 'Fire'  
  END  
 ELSE  
  SELECT @FireStatusid = prodStatus_id  
  FROM dbo.production_status with(nolock)  
  WHERE Prodstatus_desc = 'Fire'  
 IF @FireStatusid IS null  
  BEGIN  
   SELECT @ErrorMsg = 'Fire Status NOT FOUND'  
   GOTO ReturnData  
  END  
 /* Perfect Status */  
 IF (@AppVersion) > 400000.000  
  BEGIN  
   SELECT  @PerfectStatusid = prodStatus_id  
    FROM dbo.production_status with(nolock)  
    WHERE coalesce(Prodstatus_desc_global,Prodstatus_desc_local) = 'Perfect'  
  END  
 ELSE  
  SELECT @PerfectStatusid = prodStatus_id  
  FROM dbo.production_status with(nolock)  
  WHERE Prodstatus_desc = 'Perfect'  
  
 IF @PerfectStatusid IS null  
  BEGIN  
   SELECT @ErrorMsg = 'Perfect Status NOT FOUND'  
   GOTO ReturnData  
  END  
  
 /* Hold Status */  
 IF (@AppVersion) > 400000.000  
  BEGIN  
   SELECT  @HoldStatusid = prodStatus_id  
    FROM dbo.production_status with(nolock)  
    WHERE coalesce(Prodstatus_desc_global,Prodstatus_desc_local) = 'Hold'  
  END  
 ELSE  
  SELECT @Holdstatusid = prodStatus_id  
  FROM dbo.production_status with(nolock)  
  WHERE Prodstatus_desc = 'Hold'  
  
 IF @Holdstatusid IS null  
  BEGIN  
   SELECT @ErrorMsg = 'Hold Status NOT FOUND'  
   GOTO ReturnData  
  END  
  
 /* Flagged Status */  
 IF (@AppVersion) > 400000.000  
  BEGIN  
   SELECT  @FlaggedStatusid = prodStatus_id  
    FROM dbo.production_status with(nolock)  
    WHERE coalesce(Prodstatus_desc_global,Prodstatus_desc_local) = 'Flagged'  
  END  
 ELSE  
  SELECT @FlaggedStatusid = prodStatus_id  
  FROM dbo.production_status with(nolock)  
  WHERE Prodstatus_desc = 'Flagged'  
  
 IF @FlaggedStatusid IS null  
  BEGIN  
   SELECT @ErrorMsg = 'Flagged Status NOT FOUND'  
   GOTO ReturnData  
  END  
  
 /* Received Status */  
 IF (@AppVersion) > 400000.000  
  BEGIN  
   SELECT  @ReceivedStatusid = prodStatus_id  
    FROM dbo.production_status with(nolock)  
    WHERE coalesce(Prodstatus_desc_global,Prodstatus_desc_local) = 'Received'  
  END  
 ELSE  
  SELECT @ReceivedStatusid = prodStatus_id  
  FROM dbo.production_status with(nolock)  
  WHERE Prodstatus_desc = 'Received'  
  
 IF @ReceivedStatusid IS null  
  BEGIN  
   SELECT @ErrorMsg = 'Received Status NOT FOUND'  
   GOTO ReturnData  
  END  
  
 /* Consumed Status */  
 IF (@AppVersion) > 400000.000  
  BEGIN  
   SELECT  @ConsumedStatusid = prodStatus_id  
    FROM dbo.production_status with(nolock)  
    WHERE coalesce(Prodstatus_desc_global,Prodstatus_desc_local) = 'Consumed'  
  END  
 ELSE  
  SELECT @ConsumedStatusid = prodStatus_id  
  FROM dbo.production_status with(nolock)  
  WHERE Prodstatus_desc = 'Consumed'  
  
 IF @ConsumedStatusid IS null  
  BEGIN  
   SELECT @ErrorMsg = 'Consumed Status NOT FOUND'  
   GOTO ReturnData  
  END  
  
  
 /* Reject Status */  
 IF (@AppVersion) > 400000.000  
  BEGIN  
   SELECT  @RejectStatusid = prodStatus_id  
    FROM dbo.production_status with(nolock)  
    WHERE coalesce(Prodstatus_desc_global,Prodstatus_desc_local) = 'Reject'  
  END  
 ELSE  
  SELECT @RejectStatusid = prodStatus_id  
  FROM dbo.production_status with(nolock)  
  WHERE Prodstatus_desc = 'Reject'  
  
 IF @RejectStatusid IS null  
  BEGIN  
   SELECT @ErrorMsg = 'Reject Status NOT FOUND'  
   GOTO ReturnData  
  END  
  
 /*  user id for the resulset  */  
  
 SELECT @Userid = User_id   
 FROM dbo.Users with(nolock)  
 WHERE username = 'Reliability System'  
  
 IF @Userid IS null  
  BEGIN  
   SELECT @ErrorMsg = 'Calc USER NOT FOUND'  
   GOTO ReturnData  
  END  
  
/*  Get the event to update  */  
SELECT @Eventid = Event_id, @Eventstatus = Event_status  
FROM dbo.EVENTS with(nolock)  
WHERE pu_id = @puid AND  
  timestamp = @timestamp  
  
IF @Eventid IS NULL   
 BEGIN  
  SELECT @ErrorMsg = 'EVENT NOT FOUND'  
  GOTO ReturnData  
 END  
  
IF  (@Eventstatus in (@RejectStatusid,@ReceivedStatusid,@ConsumedStatusid,@FireStatusid,@HoldStatusid))  
 begin  
  SELECT @ErrorMsg = 'DONOTHING'  
  goto ReturnData  
 end  
  
/*  Get the list of variable  */  
  
  
SET @LinkStr = 'CommentResult='  
  
INSERT INTO @tblvar (var_id,Value,result_on,var_desc,comment_result)   
SELECT v.var_id, t.Result,t.result_on,v.var_desc,GBDB.dbo.fnLocal_GlblParseInfo(v.Extended_Info, @LinkStr)  
FROM dbo.Calculation_Instance_Dependencies CID with(nolock)  
  join dbo.variables v with(nolock) on v.var_id = cid.var_id  
  LEFT join dbo.Tests t with(nolock) on t.var_id = v.var_id AND t.result_on = @timestamp  
WHERE cid.result_var_id = @varid AND  
  cid.Calc_Dependency_NotActive = 0  
  
  
IF (SELECT count(*) FROM @tblvar) = 0  
 BEGIN   
  SELECT @ErrorMsg = 'NO VARIABLE FOUND'  
  GOTO ReturnData  
 END   
CompleteCode:  
  
/*  Get the running product  */  
SELECT @Prodid = Prod_id,@ProdDate = start_time   
FROM dbo.production_starts with(nolock)  
WHERE start_time <= @Timestamp AND  
 (end_time > @Timestamp or end_time is null) AND  
 Pu_id = @puid  
  
IF @Prodid IS null  
 BEGIN  
  SELECT @ErrorMsg = 'NO PRODUCT FOR PUID = ' + CONVERT(VARCHAR(5), @puid)  
  GOTO ReturnData  
 END  
  
  
UPDATE @tblvar  
SET Value = t.Result,result_on = t.result_on  
FROM   
@tblvar aa   
JOIN (select v.var_id , MAX(t.result_on) result_on   
  from @tblvar v  
   JOIN dbo.Tests t with(nolock) ON t.var_id = v.var_id and t.result_on <= @TimeStamp  and t.result_on >= @ProdDate  
  WHERE v.value is null and   
    t.result is not null  
  GROUP BY v.var_id) v on v.var_id = aa.var_id  
JOIN dbo.tests t with(nolock) on t.result_on = v.result_on and t.var_id = v.var_id  
WHERE value is null  
  
/*being the event Comment any variables that have Comment_result = Yes */  
DECLARE PPREventCursor CURSOR FOR  
 SELECT var_desc + ' at ' + convert(varchar(25),result_on ,120) + ' was ' +value FROM @tblvar WHERE upper(comment_result) = 'YES' and value is not null  
OPEN PPREventCursor  
FETCH NEXT FROM PPREventCursor INTO @PPREventComment  
WHILE @@FETCH_STATUS = 0  
 BEGIN  
  IF @newcomment is null  
   BEGIN  
    SELECT @newcomment = @PPREventComment  
   END  
  ELSE  
   BEGIN  
    SELECT @newcomment = @newcomment + ' ' + @PPREventComment  
   END  
  FETCH NEXT FROM PPREventCursor  
 END  
CLOSE PPREventCursor  
DEALLOCATE PPREventCursor  
IF len(@newcomment) >0   
 BEGIN  
  SELECT @PPREventCommentFinal = @newcomment  
  SELECT @newcomment = null  
 END  
/*  Get the Specifications for each variable  */  
UPDATE @tblvar  
SET  L_Reject  = vs.L_Reject,   
  L_Warning  = vs.L_Warning,  
  L_Entry  = vs.L_Entry,  
  U_User  = vs.U_User,  
  Target  = vs.Target,  
  L_User  = vs.L_User,  
  U_Entry  = vs.U_Entry,  
  U_Warning  = vs.U_Warning,  
  U_Reject = vs.U_Reject  
FROM @tblvar v  
  JOIN dbo.var_specs vs with(nolock) ON v.var_id = vs.var_id    
WHERE vs.Effective_Date <= @Timestamp AND   
  (vs.Expiration_Date > @Timestamp or vs.Expiration_Date is null) AND   
  prod_id = @Prodid  
  
/*  Validation for getting the right status  */  
select @newstatusid = @PerfectStatusid  
  
  
IF (EXISTS(SELECT Value,L_warning,U_warning   
   FROM @tblvar  
    WHERE (isnumeric(Value)<>0 and Value is not null)  
     and ((L_Warning is not null and (convert(float,Value) < convert(float,L_Warning))) or  
      (U_Warning is not null and (convert(float,Value) > convert(float,U_Warning))))))  
  
 BEGIN  
  SELECT @newstatusid = @Flaggedstatusid  
  SELECT TOP 1 @comment = 'Flagged for: ' + var_desc+' at '+ convert(varchar(25),result_on ,120)  
    FROM @tblvar  
    WHERE (isnumeric(Value)<>0 and Value is not null)  
     and ((L_Warning is not null and (convert(float,Value) < convert(float,L_Warning))) or  
      (U_Warning is not null and (convert(float,Value) > convert(float,U_Warning))))  
    ORDER BY result_on desc  
 END  
IF (EXISTS(SELECT *   
  FROM @tblvar  
  WHERE (Value is not null and Isnumeric(Value)=0) AND  
    (Value = L_Warning OR   
    Value = U_Warning)))   
 BEGIN  
  SELECT @newstatusid = @Flaggedstatusid  
  SELECT TOP 1 @comment = 'Flagged for: ' +var_desc+' at '+ convert(varchar(25),result_on ,120)  
   FROM @tblvar  
   WHERE (Value is not null and Isnumeric(Value)=0) and  
    (Value = L_Warning or   
    Value = U_Warning)  
   ORDER BY result_on desc  
 END  
  
--hold  
  
IF (EXISTS(SELECT Value,L_Reject,U_Reject   
   FROM @tblvar  
    WHERE (isnumeric(Value)<>0 and Value is not null)  
     and ((L_Reject is not null and (convert(float,Value) < convert(float,L_Reject))) or  
      (U_Reject is not null and (convert(float,Value) > convert(float,U_Reject))))))  
 BEGIN  
  SELECT @newstatusid = @Holdstatusid  
  SELECT TOP 1 @comment = 'Hold/Reject for: ' + var_desc+' at '+ convert(varchar(25),result_on ,120)  
    FROM @tblvar  
    WHERE (isnumeric(Value)<>0 and Value is not null)  
     and ((L_Reject is not null and (convert(float,Value) < convert(float,L_Reject))) or  
      (U_Reject is not null and (convert(float,Value) > convert(float,U_Reject))))  
    ORDER BY result_on desc  
 END  
IF (EXISTS(SELECT *  
  FROM @tblvar  
  WHERE (Value is not null and Isnumeric(Value)=0) and  
    (Value = L_Reject or  
    Value = U_Reject)))  
 BEGIN  
  SELECT @newstatusid = @Holdstatusid  
  SELECT TOP 1 @comment = 'Hold/Reject for: ' + var_desc+' at '+ convert(varchar(25),result_on ,120)  
   FROM @tblvar  
   WHERE (Value is not null AND Isnumeric(Value)=0) AND  
    (Value = L_Reject OR   
    Value = U_Reject)  
   ORDER BY result_on desc  
 END  
  
  
/* check to see if the event needs to be updated */  
IF (@newstatusid <> @Eventstatus) AND (@Eventstatus not in (@RejectStatusid,@ReceivedStatusid,@ConsumedStatusid,@FireStatusid,@HoldStatusid))  
 BEGIN  
   
/*update the comment if required */  
 IF @PPREventCommentFinal is not null  
  BEGIN  
   IF @comment is null  
    BEGIN  
     SELECT @comment = @PPREventCommentFinal  
    END  
   ELSE  
     SELECT @comment = @PPREventCommentFinal + ' ' + @comment  
  END  
 IF @comment is not null  
  BEGIN  
   SELECT @HasComment = comment_id FROM dbo.tests WHERE var_id = @varid and result_on = @timestamp  
   IF @HasComment is null  
    BEGIN  
     INSERT INTO dbo.comments(modified_on,user_id,cs_id,comment,comment_text)  
     SELECT @TimeStamp,@UserID,@CommentSource,@Comment,@Comment  
     /*set @CommentID */  
      SELECT @CommentID = comment_id  
       FROM dbo.comments with(nolock)  
      WHERE modified_on = @timestamp and user_id = @UserID  
     /* update the test table */  
      UPDATE dbo.tests  
       SET comment_id = @CommentID  
      WHERE var_id = @varid and result_on = @timestamp  
     /* update the events table */  
      UPDATE dbo.events  
       SET comment_id = @CommentID  
      WHERE event_id = @EventID  
    END  
   IF @HasComment is not null  
    BEGIN  
     SELECT @newcomment = comment   
      FROM dbo.comments with(nolock)  
     WHERE comment_id = @HasComment   
     IF @newcomment  not like '%' + @comment + '%'  
      BEGIN  
       IF (@AppVersion) > 400000.000  
        BEGIN  
         INSERT INTO dbo.comments(modified_on,user_id,cs_id,comment,comment_text,TopOfChain_id)  
         SELECT @TimeStamp,@UserID,@CommentSource,@Comment,@Comment,@HasComment  
        END  
       ELSE  
         SELECT @newcomment = @newcomment  + ' '+ @comment  
         UPDATE dbo.comments  
          SET comment = @newcomment,  
           comment_text =  @newcomment  
         WHERE comment_id = @HasComment  
     END  
    END   
  END  
 IF @Comment is null  
  BEGIN  
   SELECT @HasComment = comment_id FROM dbo.tests with(nolock) WHERE var_id = @varid and result_on = @timestamp  
  IF @HasComment is not null  
    BEGIN  
     IF (@AppVersion) > 400000.000  
      BEGIN  
       select @newcomment = 'Corrected on: ' +convert(varchar(25),getdate() ,120)  
       INSERT INTO dbo.comments(modified_on,entry_on,user_id,cs_id,comment,comment_text,TopOfChain_id)  
       SELECT @TimeStamp,getdate(),@UserID,@CommentSource,@newComment,@newComment,@HasComment  
      END  
     ELSE  
      IF (@AppVersion) > 400000.000  
       BEGIN  
        SELECT @newcomment = comment   
         FROM dbo.comments with(nolock)  
        WHERE comment_id = @HasComment  
        SELECT @newcomment = @newcomment  + ' Corrected on: ' +convert(varchar(25),getdate() ,120)  
        UPDATE dbo.comments  
         SET comment = @newcomment,  
          comment_text =  @newcomment  
         WHERE comment_id = @HasComment  
          and comment_text not  like '% Corrected on: %'  
       END  
    END  
  END  
  
/* update the PPRRecalculation variable */  
 /* get the var_id of the Recalculate PPR variable */  
  SELECT @PPRVarID =  var_id FROM dbo.variables with(nolock) WHERE var_desc = 'Recalculate PPR' and pu_id = @puid  
 /* fill @variableupdates with the base date */  
  INSERT INTO @variableupdates (result_on,pu_id,user_id,canceled,transaction_type,postupdate,var_id)  
   SELECT timestamp,pu_id,@userid,0,1,0,@PPRVarID FROM dbo.events with(nolock) WHERE pu_id = @puid and timestamp > @timestamp  
 /* get the result for @variableupdates */  
  UPDATE v  
    SET result =   
      CASE  
       WHEN t.result is null THEN 'Need Recalculation'  
       WHEN t.result is not null THEN left(t.result,19) + convert(varchar(6),convert(int,RAND()*1000))  
      END,  
     entry_on = t.entry_on  
   FROM @variableupdates v  
    LEFT JOIN dbo.tests t with(nolock) ON t.var_id = v.var_id and t.result_on = v.result_on  
 /* write out the message for the test table update */  
  IF (SELECT count(*) FROM @variableupdates)> 1  
   BEGIN  
    SELECT @curtime = getdate()  
    SELECT 2,var_id ,pu_id,user_id,canceled, result, result_on,transaction_type, postupdate  
     FROM @variableupdates  
     WHERE   
      abs(datediff(minute,@curtime,entry_on)) >@WaitTime or entry_on is null  
   END   
  /*  IF status is complete we need to update it to perfect  */  
    SELECT  1,  
    NULL,  
     2,  
    Event_id,  
     Event_num,  
     pu_id,  
     Timestamp,  
     Applied_Product,  
     Source_Event,  
     @newstatusid,  
     NULL,  
     @Userid,  
     0,  
     Conformance,Testing_Prct_Complete,Start_Time,0,  
     Testing_Status,Comment_Id,Event_SubType_Id,getdate()--,  
     --Approver_User_Id,Second_User_Id,Approver_Reason_Id,User_Reason_Id,  
     --User_SignOff_Id,Extended_Info  
    FROM dbo.EVENTS with(nolock)  
    WHERE Event_id = @Eventid  
      
  END  
  
Select @ErrorMsg = ProdStatus_Desc  
FROM dbo.production_status with(nolock)  
WHERE prodStatus_id = @newstatusid  
ReturnData:  
--select @errormsg as [Error]  
--select @comment as [Comment]  
--select  @Eventid as [EventID]  
--select  @Eventstatus as [EventStatus]  
--SELECT 2,var_id ,pu_id,user_id,canceled, result, result_on,transaction_type, postupdate FROM @variableupdates  
       
  
SET NOCOUNT OFF  
  
