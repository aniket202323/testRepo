

CREATE PROCEDURE dbo.splocal_QA_Get_Target_for_PO_StartUp         
/*          
------------------------------------------------------------------------------------------------------------------------------------------------------------------          
Created by TCS LTD.          
On 02-June-2010       Version 1.0.0          
Purpose :   Get target value for some var for a specific PO in START UP DISPLAY          
------------------------------------------------------------------------------------------------------------------------------------------------------------------          
*/          
@OutputValue  varchar(30) OUTPUT,          
@dteTimestamp datetime,          
@strText  varchar(30),          
@intTrigVarId int         

          
AS 
         
DECLARE          
@intPUID  int,          
@intUserID  int,          
@strTypeVal  varchar(30),          
@intProdId  int,          
@intSheet_id int,
@strPO   varchar(30),           
@AppVersion  varchar(30)          
          
SET NOCOUNT ON          
          
          
--get the pu_id          
SET @intPUID = (SELECT pu_id FROM dbo.variables WITH (NOLOCK) WHERE var_id = @intTrigVarId)          
          
IF (SELECT result FROM dbo.tests WITH (NOLOCK) WHERE var_id = @intTrigVarId and result_on = @dteTimestamp) IS NULL          
BEGIN          
 SET @OutputValue = 'Check PO Number'          
 SET NOCOUNT OFF          
 RETURN          
END          
          
--get sheet_id          
SET @intSheet_id = (SELECT sheet_id FROM dbo.sheet_variables WITH (NOLOCK) WHERE var_id = @intTrigVarId)          
          
--get the user id          
SET @intUserId = (SELECT user_id FROM dbo.users WITH (NOLOCK) WHERE username = 'system utility')

SET @strPO = (SELECT result FROM dbo.tests WITH (NOLOCK) WHERE var_id = @intTrigVarId and result_on = @dteTimestamp)
          
--get the prod_id          
--SET @intProdId = (SELECT prod_id FROM dbo.production_plan WITH (NOLOCK) WHERE process_order= @strPO)     
SET @intProdID = (SELECT TOP 1 prod_id 
               FROM dbo.production_starts 
               WHERE pu_id = @intPUId AND start_time <= @dteTimestamp AND (end_time > @dteTimestamp OR end_time IS NULL))
     
          
IF @intProdId is null          
BEGIN          
 SET @OutputValue = 'Invalid prod_id'          
 SET NOCOUNT OFF          
 RETURN          
END          
          
--Create temporary table to handle every variables          
DECLARE @Write_target TABLE(          
 VarId   int,          
 PUId   int,          
 UserId   int,          
 Canceled  int,          
 Result   varchar(25),          
 ResultOn  datetime,          
 TransactionType int,          
 PostDB   int)          
          
INSERT INTO @Write_Target (VarId, PUId, UserId, Canceled, result, ResultOn, TransactionType, PostDB)          
  SELECT v.var_id,v.pu_id,@intUserId,0,vs.target,@dteTimestamp,1,0           
  FROM dbo.variables v WITH (NOLOCK)         
    join dbo.sheet_variables sv WITH (NOLOCK) on sv.var_id = v.var_id and sv.sheet_id = @intSheet_id          
    join dbo.var_specs vs WITH (NOLOCK) on v.var_id = vs.var_id and vs.prod_id = @intProdId           
   and vs.effective_date <= @dteTimestamp and (vs.expiration_date > @dteTimestamp or vs.expiration_date is null)          
  WHERE v.pu_id = @intPUID and v.extended_info like '%/' + @strText + '/%' 

-- DELETE THOSE HAVE RESULT HAS NULL
DELETE @Write_Target  WHERE result IS NULL       
          
SET @AppVersion = (SELECT App_Version FROM dbo.AppVersions WITH (NOLOCK) WHERE App_Name = 'Database')          
          
        
 SELECT          
  2,               -- Resultset Number          
  VarId,              -- Var_Id          
  PUId,              -- PU_Id          
  UserId,              -- User_Id          
  Canceled,             -- Canceled          
  result,              -- Result          
  ResultOn,             -- TimeStamp          
  TransactionType,           -- TransactionType (1=Add 2=Update 3=Delete)          
  PostDB,              -- UpdateType (0=PreUpdate 1=PostUpdate)          
  -- Added P4 --          
  Null,              -- SecondUserId          
  Null,              -- TransNum          
  Null,              -- EventId          
  Null,              -- ArrayId          
  Null              -- CommentId          
 FROM @Write_target          
  
SET @OutputValue = @strText + ' written'          
          
SET NOCOUNT OFF      

