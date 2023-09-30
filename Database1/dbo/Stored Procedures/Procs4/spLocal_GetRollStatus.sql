  /*  
Stored Procedure: spLocal_GetRollStatus  
Author:   Matthew Wells (MSI)  
Date Created:  10/19/01  
  
Description:  
=========  
Returns the string value of the Event Status.  If the status is 'FIRE-?' then it sets the value of the previous and next event to fire as well.  
  
Change Date Who What  
=========== ==== =====  
10/19/01  MKW Created procedure.  
02/19/02  MKW Fixed bad table names, added Drop, reinitializations, select for output  
02/20/02  MKW Fixed wrong Transaction_Type  
03/11/02  MKW Fixed problem with setting ALL rolls to FIRE - Added check for user other than CalcMgr setting status.  
31/03/03  DWFH Replaced reference to Timed_Event_Summarys table with Timed_Event_Details.  
31/03/03  DWFH Logic for setting status of Next Turnover modified to reference correct event_id.  
  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.7  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
08-SEP-2008 FLD Rev 1.0.8  
      Removed setting of User_ID to Reliability Manager and allowed it to default to   
      CalculationMgr so that logic to restrict resetting of status to Fire was  
      indeed limited to the rolls indicated by the values for @Fire_Previous_Count   
      and @Fire_Next_Count  
*/  
  
CREATE PROCEDURE dbo.spLocal_GetRollStatus   
@Output_Value   varchar(25) OUTPUT,  
@Roll_Event_Id   int,  
@Roll_Status_Id   int,  
@Reliability_PU_Id  int,  
@FIRE_Status_Desc  varchar(25),  
@Safety_Limit   int,  
@Fire_Next_Count  int,  
@Fire_Previous_Count  int  
AS  
SET NOCOUNT ON  
  
DECLARE @Turnover_Event_Id  int,  
 @Turnover_PU_Id   int,  
 @Turnover_TimeStamp  datetime,  
 @Status_Desc   varchar(25),  
 @PU_Id    int,  
 @Roll_TimeStamp   datetime,  
 @Last_TimeStamp   datetime,  
 @Last_Event_Id   int,  
 @Next_TimeStamp   datetime,  
 @Next_Event_Id   int,  
 @Count    int,  
 @Event_Num   varchar(25),  
 @Event_Status   int,  
 @Applied_Product  int,  
 @Source_Event   int,  
 @User_Id   int,  
 @Range_Start_Time  datetime,  
 @Test_Id   int,  
 @FIRE_Status_Id   int,  
 @Default_Window   int,  
 @ComXClient_Id   int,  
 @Reserved_Id   int,  
 @Safety_Limit_Time  datetime,  
 @Fire_Roll_Event_Id  int,  
 @Fire_Turnover_Event_Id  int,  
 @Fire_TimeStamp   datetime,  
 @AppVersion   varchar(30)  
  
  
DECLARE   
@Event_Number varchar(50),  
@Event_Timestamp datetime  
SELECT @Event_Number = event_num, @Event_Timestamp = timestamp FROM dbo.events where event_id = @Roll_Event_Id  
  
-- Get the Proficy database version  
SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'  
  
-- Initialization  
SELECT  @ComXClient_Id  = 1,  
 @Reserved_Id  = 50  
  
SELECT @Status_Desc = convert(varchar(25), ProdStatus_Desc)  
FROM [dbo].Production_Status  
WHERE ProdStatus_Id = @Roll_Status_Id  
  
SELECT @User_Id = User_Id  
FROM [dbo].Events  
WHERE Event_Id = @Roll_Event_Id  
  
-- Check for FIRE status  
IF @Status_Desc = @FIRE_Status_Desc AND (@User_Id = @ComXClient_Id OR @User_Id > @Reserved_Id)  
     BEGIN  
  
     DECLARE @Events TABLE (  
   Result_Set_Type  int DEFAULT 1,  
   Id       int IDENTITY,  
   Transaction_Type   int DEFAULT 1,   
   Event_Id     int NULL,   
   Event_Num     varchar(25) NULL,   
   PU_Id      int NULL,   
   TimeStamp     datetime NULL,  
   Applied_Product   int NULL,   
   Source_Event    int NULL,   
   Event_Status    int NULL,   
   Confirmed     int DEFAULT 1,  
   User_Id     int DEFAULT 26,  --User_ID 26 is CalculationMgr  
   Post_Update    int DEFAULT 0,  
   Conformance    int NULL,  
   TestPctComplete  int NULL,  
   StartTime    datetime NULL,  
   TransNum     int DEFAULT 0,  
   TestingStatus   int NULL,  
   CommentId    int NULL,  
   EventSubTypeId   int NULL,  
   EntryOn     varchar(25) NULL,  
   Approved_User_Id  int NULL,  
   Second_User_Id   int NULL,  
   Approved_Reason_Id int NULL,  
   User_Reason_Id   int NULL,  
   User_SignOff_Id  int NULL,  
   Extended_Info   int NULL  
  )  
  
     -- Initialize  
      SELECT @Turnover_TimeStamp  = NULL,  
  @Turnover_Event_Id  = NULL,  
  @Roll_TimeStamp  = NULL,  
  @DEFAULT_Window  = 365,  
  @Turnover_PU_Id  = NULL  
  
     -- Get FIRE status id  
     SELECT @FIRE_Status_Id = ProdStatus_Id  
     FROM [dbo].Production_Status  
     WHERE ProdStatus_Desc = @FIRE_Status_Desc  
  
     -- Get Event Parameters  
     SELECT @PU_Id  = PU_Id,   
  @Roll_TimeStamp = TimeStamp  
     FROM [dbo].Events  
     WHERE Event_Id = @Roll_Event_Id  
  
     IF @FIRE_Status_Id IS NOT NULL AND @Roll_TimeStamp IS NOT NULL  
          BEGIN  
          /************************************************************************************************************************************************************************  
          *                                                                                 Get related turnover timestamp AND PU_Id                                                                            *  
          ************************************************************************************************************************************************************************/  
          SELECT @Turnover_Event_Id = Source_Event_Id  
          FROM [dbo].Event_Components  
          WHERE Event_Id = @Roll_Event_Id  
  
          SELECT  @Turnover_PU_Id  = PU_Id,  
   @Turnover_TimeStamp = TimeStamp  
          FROM [dbo].Events  
          WHERE Event_Id = @Turnover_Event_Id  
  
          /**********************************************************************************************************************  
          *                                                     Process Rolls FROM Same Turnover                                                *  
          **********************************************************************************************************************/  
          -- Find rolls through genealogy AND update status to FIRE - Omit all rolls that are or were set to FIRE  
          INSERT INTO @Events ( Transaction_Type,  
    Event_Id,  
    Event_Num,  
    PU_Id,  
    TimeStamp,  
    Event_Status)   
          SELECT 2,   
   e.Event_Id,  
   e.Event_Num,  
   e.PU_Id,  
   e.TimeStamp,  
   @FIRE_Status_Id   
          FROM [dbo].Event_Components ec  
               INNER JOIN [dbo].Events e On ec.Event_Id = e.Event_Id AND e.Event_Status <> @FIRE_Status_Id  
          WHERE ec.Source_Event_Id = @Turnover_Event_Id  
  
          /************************************************************************************************************************************************************************  
          *                                                                      Get last Turnover timestamp AND set to FIRE status                                                                         *  
          ************************************************************************************************************************************************************************/  
          -- Reinitialize   
          SELECT @Turnover_Event_Id = NULL,  
   @Count   = 0  
  
          -- Get the maximum time ago that can have a fire roll  
          SELECT @Safety_Limit_Time = dateadd(hh, -@Safety_Limit, @Turnover_TimeStamp)  
  
          -- Check for a more recent downtime (NOTE: If currently in downtime need to get the previous one)  
          SELECT TOP 1 @Safety_Limit_Time = End_Time  
          FROM [dbo].Timed_Event_Details  
          WHERE PU_Id = @Reliability_PU_Id   
      AND End_Time > @Safety_Limit_Time  
      AND End_Time < @Turnover_TimeStamp  
      AND End_Time IS NOT NULL  
          ORDER BY End_Time DESC  
  
          DECLARE Events INSENSITIVE CURSOR FOR  
          SELECT Event_Id  
          FROM [dbo].Events  
          WHERE PU_Id = @Turnover_PU_Id  
  AND TimeStamp < @Turnover_TimeStamp  
  AND TimeStamp > @Safety_Limit_Time  
          ORDER BY TimeStamp DESC  
          FOR READ ONLY  
          OPEN Events  
  
          FETCH NEXT FROM Events INTO @Turnover_Event_Id   
          WHILE @@FETCH_STATUS = 0 AND @Count < @FIRE_Previous_Count  
               BEGIN  
  
               -- Find rolls through genealogy and update status to FIRE  
               INSERT INTO @Events ( Transaction_Type,   
     Event_Id,  
     Event_Num,  
     PU_Id,  
     TimeStamp,  
     Event_Status)   
             SELECT 2,  
       e.Event_Id,  
       e.Event_Num,  
       e.PU_Id,  
       e.TimeStamp,  
       @FIRE_Status_Id   
             FROM [dbo].Event_Components ec  
                  INNER JOIN [dbo].Events e On ec.Event_Id = e.Event_Id AND e.Event_Status <> @FIRE_Status_Id  
             WHERE ec.Source_Event_Id = @Turnover_Event_Id  
  
               -- Increment  
               SELECT @Count = @Count + 1  
               FETCH NEXT FROM Events INTO @Turnover_Event_Id  
               END  
  
          CLOSE Events  
          DEALLOCATE Events  
  
  
          /***********************************************************************************************************************  
          *                                                   Process Rolls FROM Next Turnover                                                     *  
          ***********************************************************************************************************************/  
          -- Reinitialize   
          SELECT @Turnover_Event_Id = NULL,  
   @Count   = 0  
  
          -- Get the maximum time ago that can have a fire roll  
          SELECT @Safety_Limit_Time = dateadd(hh, @Safety_Limit, @Turnover_TimeStamp)  
  
          -- Check for a more recent downtime  
          SELECT TOP 1 @Safety_Limit_Time = End_Time  
          FROM [dbo].Timed_Event_Details  
          WHERE PU_Id = @Reliability_PU_Id   
      AND End_Time < @Safety_Limit_Time  
      AND End_Time > @Turnover_TimeStamp  
      AND End_Time IS NOT NULL  
          ORDER BY End_Time ASC  
  
          DECLARE Events INSENSITIVE CURSOR FOR  
          SELECT Event_Id  
          FROM [dbo].Events  
          WHERE PU_Id = @Turnover_PU_Id  
      AND TimeStamp > @Turnover_TimeStamp  
      AND TimeStamp < @Safety_Limit_Time  
          ORDER BY TimeStamp ASC  
          FOR READ ONLY  
          OPEN Events  
  
          FETCH NEXT FROM Events INTO @Turnover_Event_Id  
          WHILE @@FETCH_STATUS = 0 AND @Count < @FIRE_Next_Count  
               BEGIN  
               -- Find rolls through genealogy and update status to FIRE  
               INSERT INTO @Events ( Transaction_Type,   
     Event_Id,  
     Event_Num,  
     PU_Id,  
     TimeStamp,  
     Event_Status)   
               SELECT 2,  
   e.Event_Id,  
   e.Event_Num,  
   e.PU_Id,  
   e.TimeStamp,  
   @FIRE_Status_Id   
               FROM [dbo].Event_Components ec  
                    INNER JOIN [dbo].Events e On ec.Event_Id = e.Event_Id AND e.Event_Status <> @FIRE_Status_Id  
               WHERE ec.Source_Event_Id = @Turnover_Event_Id  
  
               -- Increment  
               SELECT @Count = @Count + 1  
               FETCH NEXT FROM Events INTO @Turnover_Event_Id  
               END  
  
          CLOSE Events  
          DEALLOCATE Events  
          END  
  
     -- Return result sets  
     IF (SELECT count(Result_Set_Type) FROM @Events) > 0  
          BEGIN  
  
    IF @AppVersion LIKE '4%'  
     BEGIN  
  
      SELECT e.Result_Set_Type,  
       e.Id ,  
       e.Transaction_Type,   
       e.Event_Id ,   
       e.Event_Num ,   
       e.PU_Id  ,   
       e.TimeStamp,  
       e.Applied_Product ,   
       e.Source_Event,   
       e.Event_Status ,   
       e.Confirmed ,  
       e.User_Id ,  
       e.Post_Update ,  
       e.Conformance ,  
       e.TestPctComplete ,  
       e.StartTime  ,  
       e.TransNum  ,  
       e.TestingStatus ,  
       e.CommentId ,  
       e.EventSubTypeId,  
       e.EntryOn,  
       e.Approved_User_Id,  
       e.Second_User_Id,  
       e.Approved_Reason_Id,  
       e.User_Reason_Id,  
       e.User_SignOff_Id,  
       e.Extended_Info  
      FROM @Events e  
       LEFT JOIN [dbo].Event_History eh On eh.Event_Id = e.Event_Id AND eh.Event_Status = @FIRE_Status_Id  
             WHERE eh.Event_Id Is NULL  
     END  
    ELSE  
     BEGIN  
  
      SELECT e.Result_Set_Type,  
       e.Id ,  
       e.Transaction_Type,   
       e.Event_Id ,   
       e.Event_Num ,   
       e.PU_Id  ,   
       e.TimeStamp,  
       e.Applied_Product ,   
       e.Source_Event,   
       e.Event_Status ,   
       e.Confirmed ,  
       e.User_Id ,  
       e.Post_Update ,  
       e.Conformance ,  
       e.TestPctComplete ,  
       e.StartTime  ,  
       e.TransNum  ,  
       e.TestingStatus ,  
       e.CommentId ,  
       e.EventSubTypeId,  
       e.EntryOn  
      FROM @Events e  
       LEFT JOIN [dbo].Event_History eh On eh.Event_Id = e.Event_Id AND eh.Event_Status = @FIRE_Status_Id  
             WHERE eh.Event_Id Is NULL  
     END  
   
          END  
  
  END  
  
SELECT @Output_Value = @Status_Desc  
  
SET NOCOUNT OFF  
  
  
