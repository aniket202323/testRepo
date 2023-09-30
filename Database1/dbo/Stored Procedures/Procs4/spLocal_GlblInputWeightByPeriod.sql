   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-03  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_GlblInputWeightByPeriod  
Author:   Matthew Wells (MSI)  
Date Created:  11/21/03  
  
Description:  
=========  
Ratioes the input weight by time to match the turnover's.  
  
Change Date Who What  
=========== ==== =====  
*/  
  
CREATE PROCEDURE spLocal_GlblInputWeightByPeriod  
@Output_Value  varchar(25) OUTPUT, --1  
@Event_Id  int,   --2  
@Value_Str  varchar(25),  --3  
@Start_Time_Var_Id int,   --4  
@End_Time_Var_Id int,   --5  
@Var_Id   int,   --6  
@Day_Interval  int,   --7  
@Day_Offset  int,   --8  
@Shift_Interval  int,   --9  
@Shift_Offset  int,   --10  
@Downtime_PU_Id  int,   --12  
@Invalid_Status_Desc varchar(25),  --13  
@Unwind_Stand_Var_Id int,   --14  
@Input   int,   --15  
@Trigger_Var_Id  int  
AS  
  
/*  
SELECT @Event_Id  = 3208463,  
 @Value_Str  = '2.5',  
 @Start_Time_Var_Id = 11793,  
 @End_Time_Var_Id = 11790,  
 @Var_Id   = 45440,  
 @Day_Interval  = 1440,  
 @Day_Offset  = 0,  
 @Shift_Interval  = 720,  
 @Shift_Offset  = 450,  
 @Downtime_PU_Id  = 864,  
 @Invalid_Status_Desc = 'Invalid',  
 @Unwind_Stand_Var_Id = 11801,  
 @Input   = 1,  
 @Trigger_Var_Id  = 11790  
*/  
SET NOCOUNT ON  
DECLARE @UWS_PU_Id   int,  
 @Precision   int,  
 @Day_Start_Time   datetime,  
 @Shift_Start_Time  datetime,  
 @UWS_Start_Time   datetime,  
 @UWS_End_Time   datetime,  
 @Start_Time   datetime,  
 @End_Time   datetime,  
 @Intervals   int,  
 @Value    real,  
 @Reel_Time   real,  
 @Sample_Time   real,  
 @Sample_Value   real,  
 @Downtime   real,  
 @Invalid_Downtime_Id  int,  
 @Sample_Count   int,  
 @Event_Status   int,  
 @Previous_Start_Time  datetime,  
 @Previous_End_Time  datetime,  
 @Previous_Unwind_Stand  varchar(25),  
 @Trigger_Value   varchar(25),  
 @Previous_Trigger_Value  varchar(25),  
 @TimeStamp   datetime,  
 @PEI_Id    int,  
 @Unwind_Stand   varchar(25),  
 @Test_Id   int,  
 @Input_Order   int,  
 @User_id   int,  
 @AppVersion   varchar(30)  
  
 -- Get the Proficy database version  
 SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'   
  
-- user id for the resulset  
SELECT @User_id = User_id   
FROM [dbo].Users  
WHERE username = 'Reliability System'  
  
DECLARE @Tests TABLE (  
 Result_Set_Type  int DEFAULT 2,  
 Var_Id    int NULL,  
 PU_Id   int NULL,  
 User_Id   int NULL,  
 Canceled  int DEFAULT 0,  
 Result   varchar(25) NULL,  
 Result_On  datetime NULL,  
 Transaction_Type int DEFAULT 1,  
 Post_Update  int DEFAULT 0,  
 SecondUserId  int Null,  
 TransNum    int Null,  
 EventId    int Null,  
 ArrayId    int Null,  
 CommentId   int Null)  
  
--Initialize data  
SELECT  @Value_Str   = nullif(ltrim(rtrim(@Value_Str)), ''),  
 @Output_Value  = @Value_Str,  
 @Value    = 0.0,  
 @Downtime  = 0.0,  
 @Sample_Count  = 0  
  
SELECT @UWS_PU_Id  = PU_Id,  
 @TimeStamp = TimeStamp  
FROM [dbo].Events  
WHERE Event_Id = @Event_Id  
  
SELECT @UWS_Start_Time = CASE WHEN isdate(Result) = 1 THEN convert(datetime, Result)  
    ELSE NULL  
    END  
FROM [dbo].tests  
WHERE Var_Id = @Start_Time_Var_Id  
 AND Result_On = @TimeStamp  
  
SELECT @UWS_End_Time = CASE WHEN isdate(Result) = 1 THEN convert(datetime, Result)  
    ELSE NULL  
    END  
FROM [dbo].tests  
WHERE Var_Id = @End_Time_Var_Id  
 AND Result_On = @TimeStamp  
  
SELECT @Unwind_Stand = Result  
FROM [dbo].tests  
WHERE Var_Id = @Unwind_Stand_Var_Id  
 AND Result_On = @TimeStamp  
  
SELECT  @UWS_PU_Id = PU_Id,  
 @Precision = Var_Precision  
FROM [dbo].Variables  
WHERE Var_Id = @Var_Id  
  
SELECT @Input_Order = Input_Order  
FROM [dbo].PrdExec_Inputs  
WHERE PU_Id = @UWS_PU_Id  
 AND Input_Name = @Unwind_Stand  
  
------------------------------------------------------------------  
--                Check to see if value has changed             --  
------------------------------------------------------------------  
SELECT @Test_Id = NULL  
SELECT  @Trigger_Value = Result,  
 @Test_Id = Test_Id  
FROM [dbo].tests  
WHERE Var_Id = @Trigger_Var_Id  
 AND Result_On = @TimeStamp  
  
SELECT TOP 1 @Previous_Trigger_Value = Result  
FROM [dbo].Test_History  
WHERE Test_Id = @Test_Id  
ORDER BY Entry_On DESC  
  
SELECT @Previous_Start_Time = CASE WHEN @Trigger_Var_Id = @Start_Time_Var_Id THEN coalesce(convert(datetime, @Previous_Trigger_Value), @UWS_Start_Time)  
     ELSE @UWS_Start_Time  
     END,  
 @Previous_End_Time = CASE WHEN @Trigger_Var_Id = @End_Time_Var_Id THEN coalesce(convert(datetime, @Previous_Trigger_Value), @UWS_End_Time)  
     ELSE @UWS_End_Time  
     END,  
 @Previous_Unwind_Stand = CASE WHEN @Trigger_Var_Id = @Unwind_Stand_Var_Id THEN coalesce(@Previous_Trigger_Value, @Unwind_Stand)  
     ELSE @Unwind_Stand  
     END  
  
------------------------------------------------------------------  
--               Delete any prior values                        --  
------------------------------------------------------------------  
INSERT INTO @Tests ( Var_Id,  
   PU_Id,  
   Result,  
   Result_On,  
   Transaction_type,User_id)  
SELECT @Var_Id,  
 @UWS_PU_Id,  
 NULL,  
 Result_On,  
 2,@User_id  
FROM tests  
WHERE Var_Id = @Var_Id  
 AND Result_On > @Previous_Start_Time  
 AND Result_On < @Previous_End_Time  
  
  
------------------------------------------------------------------  
--               Build the tests entries                        --  
------------------------------------------------------------------  
IF @UWS_Start_Time IS NOT NULL  
 AND @UWS_End_Time IS NOT NULL  
 AND @Input_Order = @Input  
     BEGIN  
     IF isnumeric(@Value_Str) = 1  
          BEGIN  
          SELECT @Value = convert(real, @Value_Str)  
          END  
  
     IF @Value > 0.0  
          BEGIN  
          ------------------------------------------------------------------  
          --               Look for any time boundaries                   --  
          ------------------------------------------------------------------  
          DECLARE @TimeStamps TABLE ( TimeStamp datetime)  
  
          -- Calculate time periods  
          SELECT @Start_Time = dateadd(mi, @Day_Offset, convert(datetime, floor(convert(float, @UWS_End_Time))))  
          WHILE @Start_Time < @UWS_End_Time  
               BEGIN  
               IF @Start_Time > @UWS_Start_Time  
                    BEGIN  
                    INSERT INTO @TimeStamps  
                    VALUES (@Start_Time)  
                    SELECT @Sample_Count = @Sample_Count + 1  
                    END  
               SELECT @Start_Time = dateadd(mi, @Day_Interval, @Start_Time)  
               END  
  
          SELECT @Start_Time = dateadd(mi, @Shift_Offset, convert(datetime, floor(convert(float, @UWS_End_Time))))  
          WHILE @Start_Time < @UWS_End_Time  
               BEGIN  
               IF @Start_Time > @UWS_Start_Time  
                    BEGIN  
                    INSERT INTO @TimeStamps  
                    VALUES (@Start_Time)  
                    SELECT @Sample_Count = @Sample_Count + 1  
                    END  
               SELECT @Start_Time = dateadd(mi, @Shift_Interval, @Start_Time)  
               END  
  
          -- Determine product change time periods  
          INSERT INTO @TimeStamps  
          SELECT dateadd(s, -1, Start_Time)  
          FROM [dbo].Production_Starts  
          WHERE PU_Id = @UWS_PU_Id  
  AND Start_Time > @UWS_Start_Time  
  AND Start_Time < @UWS_End_Time  
          SELECT @Sample_Count = @Sample_Count + @@ROWCOUNT  
  
          ------------------------------------------------------------------  
          --          Build values for any time boundaries crossed        --  
          ------------------------------------------------------------------  
          IF @Sample_Count > 0  
               BEGIN  
               -- Get statuses for processing downtime AND sheetbreaks  
               SELECT @Invalid_Downtime_Id = TEStatus_Id  
               FROM [dbo].Timed_Event_Status  
               WHERE PU_Id = @Downtime_PU_Id  
   AND TEStatus_Name = @Invalid_Status_Desc  
  
               -- Get downtime total  
               SELECT @Downtime = isnull(convert(real, sum(datediff(s,   
       CASE  
       WHEN Start_Time < @UWS_Start_Time THEN @UWS_Start_Time  
              ELSE Start_Time   
       END,  
           CASE   
       WHEN End_Time > @UWS_End_Time OR End_Time IS NULL THEN @UWS_End_Time  
        ELSE End_Time   
       END)))/60.0, 0.0)  
               FROM [dbo].Timed_Event_Details  
               WHERE PU_Id = @Downtime_PU_Id  
   AND (TEStatus_Id <> @Invalid_Downtime_Id OR TEStatus_Id IS NULL)  
   AND Start_Time < @UWS_End_Time  
   AND (End_Time > @UWS_Start_Time OR End_Time IS NULL)  
  
               SELECT @Reel_Time = convert(real, datediff(s, @UWS_Start_Time, @UWS_End_Time))/60.0 - @Downtime  
  
               -- OPEN cursor for other time periods  
               DECLARE TimeStamps CURSOR FOR  
               SELECT TimeStamp  
               FROM @TimeStamps  
               ORDER BY TimeStamp ASC  
               FOR READ ONLY  
  
               SELECT @Start_Time = @UWS_Start_Time  
               OPEN TimeStamps  
               FETCH NEXT FROM TimeStamps INTO @End_Time  
               WHILE @@FETCH_STATUS = 0  
                    BEGIN  
                    -- Reinitialize  
                    SELECT @Downtime   = 0.0  
  
                    -- Get sample downtime  
                    SELECT @Downtime = isnull(convert(real, sum(datediff(s,   
       CASE   
       WHEN Start_Time < @Start_Time THEN @Start_Time  
              ELSE Start_Time   
       END,  
           CASE   
       WHEN End_Time > @End_Time OR End_Time IS NULL THEN @End_Time  
        ELSE End_Time   
       END)))/60.0, 0.0)  
                    FROM [dbo].Timed_Event_Details  
                    WHERE PU_Id = @Downtime_PU_Id  
    AND (TEStatus_Id <> @Invalid_Downtime_Id OR TEStatus_Id IS NULL)  
    AND Start_Time < @End_Time  
    AND (End_Time > @Start_Time OR End_Time IS NULL)  
  
                    SELECT @Sample_Value = @Value*(convert(real, datediff(s,@Start_Time,@End_Time))/60-@Downtime)/@Reel_Time  
  
                    -- Return results for sample  
                    INSERT INTO @Tests( Var_Id,  
         PU_Id,  
         Result,  
         Result_On,User_id)  
                    VALUES ( @Var_Id,  
         @UWS_PU_Id,  
         ltrim(str(@Sample_Value, 25, @Precision)),  
         @End_Time,@User_id)  
  
                    --Increment to next sample  
                    SELECT @Start_Time = @End_Time  
                    FETCH NEXT FROM TimeStamps INTO @End_Time  
                    END  
  
               CLOSE TimeStamps  
               DEALLOCATE TimeStamps  
                  
               ---------------------------------------------------------------------------------  
               --                         Get downtime for remaining period                   --   
               ---------------------------------------------------------------------------------  
               -- Reinitialize  
               SELECT @Downtime   = 0.0  
  
               -- Get downtime for remaining period  
               SELECT @Downtime = isnull(convert(real, sum(datediff(s,   
       CASE  
       WHEN Start_Time < @Start_Time THEN @Start_Time  
              ELSE Start_Time   
       END,  
           CASE   
       WHEN End_Time > @UWS_End_Time OR End_Time IS NULL THEN @UWS_End_Time  
        ELSE End_Time   
       END)))/60.0, 0.0)  
               FROM [dbo].Timed_Event_Details  
               WHERE PU_Id = @Downtime_PU_Id  
   AND (TEStatus_Id <> @Invalid_Downtime_Id OR TEStatus_Id IS NULL)  
   AND Start_Time < @UWS_End_Time  
   AND (End_Time > @Start_Time OR End_Time IS NULL)  
  
               SELECT @Sample_Value = @Value*(convert(real, datediff(s,@Start_Time,@UWS_End_Time))/60-@Downtime)/@Reel_Time  
               END  
          ELSE  
               BEGIN  
               SELECT @Sample_Value = @Value  
               END  
  
          INSERT INTO @Tests( Var_Id,  
    PU_Id,  
    Result,  
    Result_On,User_id)  
          VALUES ( @Var_Id,  
   @UWS_PU_Id,  
   ltrim(str(@Sample_Value, 25, @Precision)),  
   @UWS_End_Time,@User_id)  
          END  
     END  
  
IF @AppVersion LIKE '4%'  
 BEGIN  
  SELECT Result_Set_Type,  
   Var_Id,  
   PU_Id,  
   User_Id,  
   Canceled,  
   Result,  
   Result_On,  
   Transaction_Type,  
   Post_Update,  
   SecondUserId,  
   TransNum,  
   EventId,  
   ArrayId,  
   CommentId  
  FROM @Tests  
 END  
ELSE  
 BEGIN  
  SELECT Result_Set_Type,  
   Var_Id,  
   PU_Id,  
   User_Id,  
   Canceled,  
   Result,  
   Result_On,  
   Transaction_Type,  
   Post_Update  
  FROM @Tests  
 END  
  
SET NOCOUNT ON  
  
  
