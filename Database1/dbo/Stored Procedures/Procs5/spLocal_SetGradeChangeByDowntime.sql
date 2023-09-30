    /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_SetGradeChangeByDowntime  
Author:   Matthew Wells (MSI)  
Date Created:  07/17/02  
  
DESCription:  
=========  
CASCades the product currently running ON the source production unit to all specified sub-units.  
Based ON variables aliased to Source Var_Id.  IF the time of the product change is the same as the   
end time of the downtime then change the time of the product change to the start time of the downtime record.  
  
Called By: - 'Set Grade By Downtime' calculation  
  - spLocal_CreateProductChangeEvent  
   
Change Date  Who      Version  What  
============ ================== ========= ==================================================  
2006-11-03  Marc Charest (STI) 2.0.0   Add code for debug matter.     
2005-11-22  Eric Perron (STI)  1.0.1   Redesign of SP (Compliant with Proficy 3 and 4).  
                Added [dbo] template when referencing objects.  
                Added temp table  
08/21/02 MKW - Removed temporary table to speed up execution AND moved deletes to before new   
     product inserts b/c the delete won't work IF insert new product first.  
*/  
  
CREATE PROCEDURE dbo.spLocal_SetGradeChangeByDowntime  
@Output_Value   varchar(25) OUTPUT,  
@Parent_PU_Id    int,  
@Source_Var_Id   int,  
@Parent_Start_Time datetime,  
@Downtime_PU_Id  int,  
@Parent_Prod_Id  int = NULL, -- Added so can optionally pass Prod_Id FROM spLocal_CreateProductChangeEvent  
@bitDebug    BIT=0  
  
AS  
  
SET NOCOUNT ON  
/* Testing   
SELECT @Parent_PU_Id   = 505,  
 @Source_Var_Id  = 18719,  
 @Parent_Start_Time = '2002-08-20 12:12:55'  
*/  
  
-- Variable Declarations  
DECLARE @Last_Parent_Prod_Id  int,  
  @Last_Parent_Start_Time  datetime,  
  @Next_Parent_Start_Time  datetime,  
 @Downtime_Start_Time   datetime,  
 @Last_Start_Time    datetime,  
 @TEDet_Id      int,  
 @User_id       int,  
 @AppVersion      varchar(30),  
 ----------DEBUG VARIABLES-------------  
 @vcrDebugMessage  VARCHAR(4000),  
 @vcrDebugSPName  VARCHAR(100),  
 @vcrDebugUser   VARCHAR(100),  
 @intRecord   INTEGER,  
 @intRecordCount INTEGER  
 --------------------------------------  
  
DECLARE @GradeRS TABLE(  
 Start_Id  int,  
 PU_Id   int,  
 Prod_Id  int,  
 Start_Time datetime,  
 Post_DB  int,  
 User_Id  int Null,  
 Second_User_Id int Null,  
 Trans_Type int Null  
)  
  
DECLARE @GradeRSDebug TABLE(  
 Identity_Id int identity,  
 Start_Id  int,  
 PU_Id   int,  
 Prod_Id  int,  
 Start_Time datetime,  
 Post_DB  int,  
 User_Id  int Null,  
 Second_User_Id int Null,  
 Trans_Type int Null  
)  
  
IF @bitDebug = 1 BEGIN  
 SET @vcrDebugUser = 'GradeChangeDowntime'  
 SET @vcrDebugSPName = 'spLocal_SetGradeChangeByDowntime'   
 SET @vcrDebugMessage = '@Parent_PU_Id = ' + ISNULL(CONVERT(VARCHAR(255), @Parent_PU_Id, 20), 'NULL') + ' | ' + '@Source_Var_Id = ' + ISNULL(CONVERT(VARCHAR(255), @Source_Var_Id, 20), 'NULL') + ' | ' + '@Parent_Start_Time = ' + ISNULL(CONVERT(VARCHAR(255), @Parent_Start_Time, 20), 'NULL') + ' | ' + '@Downtime_PU_Id = ' + ISNULL(CONVERT(VARCHAR(255), @Downtime_PU_Id, 20), 'NULL')  
 SET @vcrDebugMessage = @vcrDebugMessage + ' | ' + '@Parent_Prod_Id = ' + ISNULL(CONVERT(VARCHAR(255), @Parent_Prod_Id, 20), 'NULL')  
 INSERT dbo.Local_Debug_Messages ([Stored_Procedure_Name], [Timestamp], [Message], [User]) VALUES (@vcrDebugSPName, GETDATE(), @vcrDebugMessage, @vcrDebugUser)  
END  
   
-- Get the Proficy database version  
SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'  
  
-- user id for the resulset  
SELECT @User_id = User_id   
FROM [dbo].Users  
WHERE username = 'GradeChangeDowntime'  
  
  
SELECT @Parent_Start_Time = dateadd(s, 1, @Parent_Start_Time)  
  
-- Get Product ID for Parent Production Unit  
IF @Parent_Prod_Id IS NULL  
     BEGIN  
     SELECT @Parent_Prod_Id = Prod_Id  
     FROM [dbo].Production_Starts  
     WHERE PU_Id = @Parent_PU_Id  
  AND Start_Time = @Parent_Start_Time  
     END  
  
IF @Parent_Prod_Id IS NOT NULL AND @Parent_Prod_Id > 1  
     BEGIN  
     -- Get Previous Product Change for Parent Production Unit  
     SELECT TOP 1  @Last_Parent_Start_Time  = Start_Time,   
   @Last_Parent_Prod_Id  = Prod_Id  
     FROM [dbo].Production_Starts  
     WHERE PU_Id = @Parent_PU_Id  
  AND Start_Time < @Parent_Start_Time  
     ORDER BY Start_Time DESC  
  
     -- Get Next Product Change ON the Parent Production Unit (IF available)  
     SELECT TOP 1 @Next_Parent_Start_Time = Start_Time  
     FROM [dbo].Production_Starts  
     WHERE PU_Id = @Parent_PU_Id  
  AND Start_Time > @Parent_Start_Time  
     ORDER BY Start_Time ASC  
  
     --Get the start time of the downtime (IF any)  
     SELECT  @Downtime_Start_Time = Start_Time  
     FROM [dbo].Timed_Event_Details  
     WHERE PU_Id = @Downtime_PU_Id  
  AND Start_Time < @Parent_Start_Time  
  AND (End_Time >= @Parent_Start_Time OR END_Time IS NULL)   
  
     WHILE @Downtime_Start_Time IS NOT NULL  
          BEGIN  
          SELECT  @Parent_Start_Time  = @Downtime_Start_Time,  
   @Last_Start_Time = NULL  
  
          SELECT @Last_Start_Time = Start_Time  
          FROM [dbo].Timed_Event_Details  
          WHERE PU_Id = @Downtime_PU_Id  
  AND END_Time = @Downtime_Start_Time  
  
          SELECT @Downtime_Start_Time = @Last_Start_Time  
          END  
  
IF @bitDebug = 1 BEGIN  
 SET @vcrDebugMessage = 'Delete invalid Product changes made ON Child Production Units during the time frame...' INSERT dbo.Local_Debug_Messages ([Stored_Procedure_Name], [Timestamp], [Message], [User]) VALUES (@vcrDebugSPName, GETDATE(), @vcrDebugMessage
, @vcrDebugUser)  
END  
     -- Delete invalid Product changes made ON Child Production Units during the time frame.  
 INSERT INTO @GradeRS (Start_Id,PU_Id,Prod_Id,Start_Time,Post_DB,User_Id)  
     SELECT ps.Start_Id,    -- @Start_Id  
   ps.PU_Id,    -- @PU_Id  
  @Last_Parent_Prod_Id,   -- @Prod_Id  
  ps.Start_Time,    -- @Start_Time  
  0 ,@User_id    -- @Post_Update  
     FROM [dbo].Production_Starts ps  
          INNER JOIN [dbo].Prod_Units pu ON ps.PU_Id = pu.PU_Id  
          INNER JOIN [dbo].Variables v ON v.PU_Id = pu.PU_Id  
          INNER JOIN [dbo].Variable_Alias va ON v.Var_Id = va.Dst_Var_Id AND va.Src_Var_Id = @Source_Var_Id  
     WHERE Start_Time > @Last_Parent_Start_Time  
  AND Start_Time <> @Parent_Start_Time  
  AND (Start_Time < @Next_Parent_Start_Time OR @Next_Parent_Start_Time IS NULL)   
  
IF @bitDebug = 1 BEGIN  
 SET @vcrDebugMessage = 'Get PU_Id for all Child Production...Add a product change for Child...' INSERT dbo.Local_Debug_Messages ([Stored_Procedure_Name], [Timestamp], [Message], [User]) VALUES (@vcrDebugSPName, GETDATE(), @vcrDebugMessage, @vcrDebugUser)
  
END  
     -- Get PU_Id for all Child Production Units Using Aliased Variables  
     -- Add a product change for Child PU's AND set Prod_Id AND Start_Time the same as Parent PU.  
 INSERT INTO @GradeRS (Start_Id,PU_Id,Prod_Id,Start_Time,Post_DB,User_Id)  
     SELECT NULL,     -- @Start_Id  
   pu.PU_Id,    -- @PU_Id  
  @Parent_Prod_Id,   -- @Prod_Id  
  @Parent_Start_Time,   -- @Start_Time  
  0,@User_id     -- @Post_Update  
     FROM [dbo].Prod_Units pu  
          INNER JOIN [dbo].Variables v ON v.PU_Id = pu.PU_Id  
          INNER JOIN [dbo].Variable_Alias va ON v.Var_Id = va.Dst_Var_Id AND va.Src_Var_Id = @Source_Var_Id  
          INNER JOIN [dbo].PU_Products pup ON pu.PU_Id = pup.PU_Id AND pup.Prod_id = @Parent_Prod_Id  
          LEFT JOIN [dbo].Production_Starts ps ON pu.PU_Id = ps.PU_Id AND Start_Time < @Parent_Start_Time AND (End_Time > @Parent_Start_Time OR END_Time IS NULL)  
     WHERE ps.Prod_Id IS NULL  
  OR ps.Prod_Id <> @Parent_Prod_Id  
  
     END  
  
IF (SELECT COUNT(*) FROM @GradeRS) > 0  
 BEGIN  
  
IF @bitDebug = 1 BEGIN  
 SET @vcrDebugMessage = 'Executing RS#3' INSERT dbo.Local_Debug_Messages ([Stored_Procedure_Name], [Timestamp], [Message], [User]) VALUES (@vcrDebugSPName, GETDATE(), @vcrDebugMessage, @vcrDebugUser)  
  
 INSERT @GradeRSDebug (Start_Id,PU_Id,Prod_Id,Start_Time,Post_DB,User_Id,Second_User_Id,Trans_Type)  
 SELECT Start_Id,PU_Id,Prod_Id,Start_Time,Post_DB,User_Id,Second_User_Id,Trans_Type FROM @GradeRS  
  
 SET @intRecordCount = (SELECT COUNT(Identity_Id) FROM @GradeRSDebug WHERE Identity_Id IS NOT NULL)  
  
 SET @intRecord = 1   
 WHILE @intRecord <= @intRecordCount BEGIN  
  SET @vcrDebugMessage =  (SELECT  
           'RS#3 DETAIL :: Start_Id = ' + ISNULL(CONVERT(VARCHAR(255), Start_Id, 20), 'NULL') + ' | ' +   
           'PU_Id = ' + ISNULL(CONVERT(VARCHAR(255), PU_Id, 20), 'NULL') + ' | ' +   
           'Prod_Id = ' + ISNULL(CONVERT(VARCHAR(255), Prod_Id, 20), 'NULL') + ' | ' +   
           'Start_Time = ' + ISNULL(CONVERT(VARCHAR(255), Start_Time, 20), 'NULL') + ' | ' +   
           'Post_DB = ' + ISNULL(CONVERT(VARCHAR(255), Post_DB, 20), 'NULL') + ' | ' +   
           'User_Id = ' + ISNULL(CONVERT(VARCHAR(255), User_Id, 20), 'NULL') + ' | ' +   
           'Second_User_Id = ' + ISNULL(CONVERT(VARCHAR(255), Second_User_Id, 20), 'NULL') + ' | ' +   
           'Trans_Type = ' + ISNULL(CONVERT(VARCHAR(255), Trans_Type, 20), 'NULL')  
           FROM   
           @GradeRSDebug  
           WHERE  
           Identity_Id = @intRecord  
          )  
  
  INSERT dbo.Local_Debug_Messages ([Stored_Procedure_Name], [Timestamp], [Message], [User]) VALUES (@vcrDebugSPName, GETDATE(), @vcrDebugMessage, @vcrDebugUser)  
  SET @intRecord = @intRecord + 1   
 END  
  
END  
  
  IF @AppVersion LIKE '4%'  
   BEGIN  
    SELECT 3,Start_Id,PU_Id,Prod_Id,Start_Time,Post_DB,User_Id,Second_User_Id,Trans_Type  
    FROM @GradeRS  
   END  
  ELSE  
   BEGIN  
    SELECT 3,Start_Id,PU_Id,Prod_Id,Start_Time,Post_DB  
    FROM @GradeRS  
   END  
 END  
  
SELECT @Output_Value = convert(varchar(25), @Parent_Prod_Id)  
  
IF @bitDebug = 1 BEGIN  
 SET @vcrDebugMessage = 'END' INSERT dbo.Local_Debug_Messages ([Stored_Procedure_Name], [Timestamp], [Message], [User]) VALUES (@vcrDebugSPName, GETDATE(), @vcrDebugMessage, @vcrDebugUser)  
END  
  
SET NOCOUNT OFF  
  
  
  
  
