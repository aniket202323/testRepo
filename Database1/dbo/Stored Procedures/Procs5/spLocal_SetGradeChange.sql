/*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-07  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Added temp table  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_SetGradeChange  
Author:     Dan Hinchey (MSI)  
Date Created:    06/04/02  
  
DESCription:  
=========  
CASCades the product currently running ON the source production unit to all specIfied sub-units.  
Based ON variables aliased to Source Var_Id.  
  
Called By: - 'Set Grade' calculation  
  - spLocal_CreateProductChangeEvent  
   
Change Date  Who      Vserion  What  
============ ================== ========= ==================================================  
2008-04-21  Christian gagnon  2.0.1   Removed the section that will delete brand change  
2006-11-03  Marc Charest (STI) 2.0.0   Add code for debug matter.     
2005-11-22  Eric Perron (STI)  1.0.1   Redesign of SP (Compliant with Proficy 3 and 4).  
                Added [dbo] template when referencing objects.  
                Added temp table.  
07/16/03 MKW - Updated for 215.508  
08/21/02 MKW - Removed temporary table to speed up execution and moved deletes to before new   
     product inserts b/c the delete won't work IF insert new product first.  
  
*/  
CREATE   PROCEDURE [dbo].[spLocal_SetGradeChange]  
@Output_Value  varchar(25) OUTPUT,  
@Parent_PU_Id  int,  
@Source_Var_Id  int,  
@Parent_Start_Time  datetime,  
@bitDebug  BIT=0,  
@Parent_Prod_Id  int = NULL -- Added so can optionally pass Prod_Id FROM spLocal_CreateProductChangeEvent  
AS  
  
SET NOCOUNT ON  
  
/* Testing   
SELECT @Parent_PU_Id   = 505,  
 @Source_Var_Id  = 4514,  
 @Parent_Start_Time = '2002-08-20 12:12:55'  
*/  
  
-- Variable Declarations  
DECLARE @Last_Parent_Prod_Id   int,  
 @Last_Parent_Start_Time  datetime,  
 @Next_Parent_Start_Time  datetime,  
 @User_id       int,  
 @AppVersion      varchar(30),  
 ----------DEBUG VARIABLES-------------  
 @vcrDebugMessage  VARCHAR(4000),  
 @vcrDebugSPName  VARCHAR(100),  
 @vcrDebugUser   VARCHAR(100),  
 @intRecord   INTEGER,  
 @intRecordCount INTEGER  
 --------------------------------------  
   
IF @bitDebug = 1 BEGIN  
 SET @vcrDebugUser = 'GradeChangeChange'  
 SET @vcrDebugSPName = 'spLocal_SetGradeChange'   
 SET @vcrDebugMessage = '@Parent_PU_Id = ' + ISNULL(CONVERT(VARCHAR(255), @Parent_PU_Id, 20), 'NULL') + ' | ' + '@Source_Var_Id = ' + ISNULL(CONVERT(VARCHAR(255), @Source_Var_Id, 20), 'NULL') + ' | ' + '@Parent_Start_Time = ' + ISNULL(CONVERT(VARCHAR(255)
, @Parent_Start_Time, 20), 'NULL') + ' | ' + '@Parent_Prod_Id = ' + ISNULL(CONVERT(VARCHAR(255), @Parent_Prod_Id, 20), 'NULL')  
 INSERT dbo.Local_Debug_Messages ([Stored_Procedure_Name], [Timestamp], [Message], [User]) VALUES (@vcrDebugSPName, GETDATE(), @vcrDebugMessage, @vcrDebugUser)  
END  
  
-- Get the Proficy database version  
SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'  
  
-- user id for the resulset  
SELECT @User_id = User_id   
FROM [dbo].Users  
WHERE username = 'GradeChangeChange'  
  
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
  
  
-- Add a second to align timestamps properly  
SELECT @Parent_Start_Time = dateadd(s, 1, @Parent_Start_Time)  
  
-- Get Product ID for Parent Production Unit  
IF @Parent_Prod_Id IS NULL  
     BEGIN  
     SELECT @Parent_Prod_Id = Prod_Id  
     FROM [dbo].Production_Starts  
     WHERE PU_Id = @Parent_PU_Id  
  AND Start_Time = @Parent_Start_Time  
     END  
  
IF @Parent_Prod_Id IS NOT NULL And @Parent_Prod_Id > 1  
     BEGIN  
     -- Get Previous Product Change for Parent Production Unit  
     SELECT TOP 1 @Last_Parent_Start_Time = Start_Time,  
   @Last_Parent_Prod_Id = Prod_Id  
     FROM [dbo].Production_Starts  
     WHERE PU_Id = @Parent_PU_Id And Start_Time < @Parent_Start_Time  
     ORDER BY Start_Time DESC  
  
     -- Get Next Product Change ON the Parent Production Unit (IF available)  
     SELECT TOP 1 @Next_Parent_Start_Time = Start_Time  
     FROM [dbo].Production_Starts  
     WHERE PU_Id = @Parent_PU_Id  
  AND Start_Time > @Parent_Start_Time  
     ORDER BY Start_Time ASC  
  
IF @bitDebug = 1 BEGIN  
 SET @vcrDebugMessage = 'Delete invalid Product changes made ON Child Production Units during the time frame...' INSERT dbo.Local_Debug_Messages ([Stored_Procedure_Name], [Timestamp], [Message], [User]) VALUES (@vcrDebugSPName, GETDATE(), @vcrDebugMessage
, @vcrDebugUser)  
END  
--     -- Delete invalid Product changes made ON Child Production Units during the time frame.  
--  INSERT INTO @GradeRS (Start_Id,PU_Id,Prod_Id,Start_Time,Post_DB,User_Id)  
--      SELECT ps.Start_Id,    -- @Start_Id  
--    ps.PU_Id,    -- @PU_Id  
--   @Last_Parent_Prod_Id,   -- @Prod_Id  
--   ps.Start_Time,    -- @Start_Time  
--   0,     -- @Post_Update  
--   @User_id  
--      FROM [dbo].Production_Starts ps  
--           INNER JOIN [dbo].Prod_Units pu ON ps.PU_Id = pu.PU_Id  
--           INNER JOIN [dbo].Variables v ON v.PU_Id = pu.PU_Id  
--           INNER JOIN [dbo].Variable_Alias va ON v.Var_Id = va.Dst_Var_Id And va.Src_Var_Id = @Source_Var_Id  
--      WHERE Start_Time > @Last_Parent_Start_Time  
--   AND Start_Time <> @Parent_Start_Time  
--   AND (Start_Time < @Next_Parent_Start_Time OR @Next_Parent_Start_Time IS NULL)   
  
IF @bitDebug = 1 BEGIN  
 SET @vcrDebugMessage = 'Get PU_Id for all Child Production...Add a product change for Child...' INSERT dbo.Local_Debug_Messages ([Stored_Procedure_Name], [Timestamp], [Message], [User]) VALUES (@vcrDebugSPName, GETDATE(), @vcrDebugMessage, @vcrDebugUser)
  
END  
     -- Get PU_Id for all Child Production Units Using Aliased Variables  
     -- Add a product change for Child PU's and set Prod_Id and Start_Time the same as Parent PU.  
  INSERT INTO @GradeRS (Start_Id,PU_Id,Prod_Id,Start_Time,Post_DB,User_Id)  
     SELECT Null,     -- @Start_Id  
    pu.PU_Id,    -- @PU_Id  
   @Parent_Prod_Id,   -- @Prod_Id  
   @Parent_Start_Time,   -- @Start_Time  
   0,     -- @Post_Update  
   @User_id  
      FROM [dbo].Prod_Units pu  
           INNER JOIN [dbo].Variables v ON v.PU_Id = pu.PU_Id  
           INNER JOIN [dbo].Variable_Alias va ON v.Var_Id = va.Dst_Var_Id AND va.Src_Var_Id = @Source_Var_Id  
           INNER JOIN [dbo].PU_Products pup ON pu.PU_Id = pup.PU_Id AND pup.Prod_id = @Parent_Prod_Id  
           LEFT JOIN [dbo].Production_Starts ps ON pu.PU_Id = ps.PU_Id AND Start_Time < @Parent_Start_Time AND (End_Time > @Parent_Start_Time Or END_Time IS NULL)  
      WHERE ps.Prod_Id IS NULL  
   OR ps.Prod_Id <> @Parent_Prod_Id  
  
     END  
  
IF (SELECT COUNT(*) FROM @GradeRS) > 0  
 BEGIN  
  
IF @bitDebug = 1 BEGIN  
   
 SET @vcrDebugMessage = 'Executing RS#3'   
 INSERT dbo.Local_Debug_Messages ([Stored_Procedure_Name], [Timestamp], [Message], [User]) VALUES (@vcrDebugSPName, GETDATE(), @vcrDebugMessage, @vcrDebugUser)  
  
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
  
  
  
  
  
  
