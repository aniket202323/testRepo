    /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Stephane Turner, System Technologies for Industry  
Date   : 2005-11-16  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_TurnoverWeightByPeriod  
Author:   Matthew Wells (MSI)  
Date Created:  12/18/02  
  
Description:  
=========  
Ratioes the turnover weight by time to match TAY calculation.  
  
Change Date Who What  
=========== ==== =====  
01/03/03 MKW Added convert to real statements for datediffs  
02/12/03 MKW Added Product Change times  
07/07/03 MKW Made change to the routine to update old tests to NULL instead of delete  
02/16/04 MKW Fixed issue with duplicate timestamps by adding "DISTINCT" clause  
06/11/04 MKW Add check for divide by 0  
*/  
  
CREATE PROCEDURE dbo.spLocal_TurnoverWeightByPeriod  
@Output_Value  varchar(25) OUTPUT, --1  
@Value_Str  varchar(25),  --2  
@TimeStamp  datetime,  --3  
@Var_Id   int,   --4  
@Day_Interval  int,   --5  
@Day_Offset  int,   --6  
@Shift_Interval  int,   --7  
@Shift_Offset  int,   --8  
@Sheetbreak_PU_Id int,   --9  
@Downtime_PU_Id  int,   --10  
@Invalid_Status_Desc varchar(25)  --11  
AS  
  
SET NOCOUNT ON  
  
/*  
Select  @Value_Str  = '2.5',  
 @TimeStamp  = '2002-12-18 20:01:46',  
 @Var_Id   = 24247,  
 @Day_Interval  = 1440,  
 @Day_Offset  = 0,  
 @Shift_Interval  = 720,  
 @Shift_Offset  = 420,  
 @Sheetbreak_PU_Id = '510',  
 @Downtime_PU_Id  = '508'  
*/  
  
DECLARE @Turnover_PU_Id   int,  
 @Precision   int,  
 @Day_Start_Time   datetime,  
 @Shift_Start_Time  datetime,  
 @Last_TimeStamp   datetime,  
 @Start_Time   datetime,  
 @End_Time   datetime,  
 @Intervals   int,  
 @Value    real,  
 @Reel_Time   real,  
 @Sample_Time   real,  
 @Sample_Value   real,  
 @Downtime   real,  
 @Sheetbreak_Time  real,  
 @Invalid_Downtime_Id  int,  
 @Invalid_Sheetbreak_Id  int,  
 @Sample_Count   int,  
 @False_Turnover_Desc  varchar(25),  
 @False_Turnover_Id  int,  
 @Event_Status   int  
  
DECLARE @Tests TABLE(  
 Result_Set_Type  int DEFAULT 2,  
 Var_Id    int NULL,  
 PU_Id   int NULL,  
 User_Id   int NULL,  
 Canceled  int DEFAULT 0,  
 Result   varchar(25) NULL,  
 Result_On  datetime NULL,  
 Transaction_Type int DEFAULT 1,  
 Post_Update  int DEFAULT 0)  
  
--Initialize data  
SELECT  @Value_Str   = nullif(ltrim(rtrim(@Value_Str)), ''),  
 @Output_Value  = @Value_Str,  
 @Value    = 0.0,  
 @Downtime  = 0.0,  
 @Sheetbreak_Time = 0.0,  
 @Sample_Count  = 0,  
 @False_Turnover_Desc = 'False Turnover'  
  
SELECT  @Turnover_PU_Id = PU_Id,  
 @Precision = Var_Precision  
FROM [dbo].Variables  
WHERE Var_Id = @Var_Id  
  
SELECT TOP 1 @Last_TimeStamp = TimeStamp  
FROM [dbo].Events  
WHERE PU_Id = @Turnover_PU_Id AND TimeStamp < @TimeStamp  
ORDER BY TimeStamp DESC  
  
IF @Last_TimeStamp IS NOT NULL  
     BEGIN  
     -- Delete any data between this turnover AND the last turnover (next TO will be automatically retriggered)  
     INSERT INTO @Tests ( Var_Id,  
    PU_Id,  
    Result,  
    Result_On,  
    Transaction_type)  
     SELECT @Var_Id,  
  @Turnover_PU_Id,  
  NULL,  
  Result_On,  
  2  
     FROM [dbo].tests  
     WHERE Var_Id = @Var_Id  
  AND Result_On > @Last_TimeStamp  
  AND Result_On < @TimeStamp  
  
     -- Check for a false turnover  
     SELECT @False_Turnover_Id = ProdStatus_Id  
     FROM [dbo].Production_Status  
     WHERE ProdStatus_Desc = @False_Turnover_Desc  
  
     SELECT @Event_Status = Event_Status  
     FROM [dbo].Events  
     WHERE PU_Id = @Turnover_PU_Id  
  AND TimeStamp = @TimeStamp  
  
     -- Convert value AND if valid THEN process  
     If ISnumeric(@Value_Str) = 1  
          BEGIN  
          SELECT @Value = convert(real, @Value_Str)  
         END  
  
     IF @Value > 0.0 AND @Event_Status IS NOT NULL AND @Event_Status <> @False_Turnover_Id  
          BEGIN  
          DECLARE @TimeStamps TABLE(TimeStamp datetime)  
  
          -- Calculate time periods  
          SELECT @Start_Time = dateadd(mi, @Day_Offset, convert(datetime, floor(convert(float, @TimeStamp))))  
          WHILE @Start_Time < @TimeStamp  
               BEGIN  
               If @Start_Time > @Last_TimeStamp  
                    BEGIN  
                    INSERT INTO @TimeStamps  
                    VALUES (@Start_Time)  
                    SELECT @Sample_Count = @Sample_Count + 1  
                    END  
               SELECT @Start_Time = dateadd(mi, @Day_Interval, @Start_Time)  
               END  
  
          SELECT @Start_Time = dateadd(mi, @Shift_Offset, convert(datetime, floor(convert(float, @TimeStamp))))  
          WHILE @Start_Time < @TimeStamp  
               BEGIN  
               IF @Start_Time > @Last_TimeStamp  
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
          WHERE PU_Id = @Turnover_PU_Id  
  AND Start_Time > @Last_TimeStamp  
  AND Start_Time < @TimeStamp  
          SELECT @Sample_Count = @Sample_Count + @@ROWCOUNT  
  
          IF @Sample_Count > 0  
               BEGIN  
               -- Get statuses for processing downtime AND sheetbreaks  
               SELECT @Invalid_Downtime_Id = TEStatus_Id  
               FROM [dbo].Timed_Event_Status  
               WHERE PU_Id = @Downtime_PU_Id  
   AND TEStatus_Name = @Invalid_Status_Desc  
  
               SELECT @Invalid_Sheetbreak_Id = TEStatus_Id  
               FROM [dbo].Timed_Event_Status  
               WHERE PU_Id = @Sheetbreak_PU_Id  
   AND TEStatus_Name = @Invalid_Status_Desc  
  
               -- Get downtime total  
               SELECT @Downtime = isnull(convert(real, sum(datediff(s,   
       CASE  
       WHEN Start_Time < @Last_TimeStamp THEN @Last_TimeStamp  
              ELSE Start_Time   
       END,  
           CASE   
       WHEN END_Time > @TimeStamp OR END_Time IS NULL THEN @TimeStamp  
        ELSE END_Time   
       END)))/60.0, 0.0)  
               FROM [dbo].Timed_Event_Details  
               WHERE PU_Id = @Downtime_PU_Id  
   AND (TEStatus_Id <> @Invalid_Downtime_Id OR TEStatus_Id IS NULL)  
   AND Start_Time < @TimeStamp  
   AND (End_Time > @Last_TimeStamp OR END_Time IS NULL)  
  
               -- Get sheetbreak time total  
               SELECT @Sheetbreak_Time = isnull(convert(real, Sum(datediff(s,   
       CASE   
       WHEN Start_Time < @Last_TimeStamp THEN @Last_TimeStamp  
              ELSE Start_Time   
       END,  
           CASE   
       WHEN END_Time > @TimeStamp OR END_Time IS NULL THEN @TimeStamp  
        ELSE END_Time   
       END)))/60.0, 0.0)  
               FROM [dbo].Timed_Event_Details  
               WHERE PU_Id = @Sheetbreak_PU_Id  
   AND (TEStatus_Id <> @Invalid_Sheetbreak_Id OR TEStatus_Id IS NULL)  
   AND Start_Time < @TimeStamp  
   AND (End_Time > @Last_TimeStamp OR END_Time IS NULL)  
  
               SELECT @Reel_Time = convert(real, datediff(s, @Last_TimeStamp, @TimeStamp))/60.0 - @Downtime - @Sheetbreak_Time  
  
               -- OPEN cursor for other time periods  
               DECLARE TimeStamps CURSOR FOR  
               SELECT DISTINCT TimeStamp -- MKW 02/16/04 - Added "DISTINCT"  
               FROM @TimeStamps  
               ORDER BY TimeStamp ASC  
               FOR READ ONLY  
  
               SELECT @Start_Time = @Last_TimeStamp  
               OPEN TimeStamps  
               FETCH NEXT FROM TimeStamps INTO @End_Time  
               WHILE @@FETCH_STATUS = 0  
                    BEGIN  
                    -- Reinitialize  
                    SELECT @Downtime   = 0.0,  
    @Sheetbreak_Time = 0.0  
  
                    -- Get sample downtime  
                    SELECT @Downtime = isnull(convert(real, sum(datediff(s,   
       CASE   
       WHEN Start_Time < @Start_Time THEN @Start_Time  
              ELSE Start_Time   
       END,  
           CASE   
       WHEN END_Time > @End_Time OR END_Time IS NULL THEN @End_Time  
        ELSE END_Time   
       END)))/60.0, 0.0)  
                    FROM [dbo].Timed_Event_Details  
                    WHERE PU_Id = @Downtime_PU_Id  
    AND (TEStatus_Id <> @Invalid_Downtime_Id OR TEStatus_Id IS NULL)  
    AND Start_Time < @End_Time  
    AND (End_Time > @Start_Time OR END_Time IS NULL)  
  
                    -- Get sample sheetbreak time  
                    SELECT @Sheetbreak_Time = isnull(convert(real, Sum(datediff(s,   
       CASE   
       WHEN Start_Time < @Start_Time THEN @Start_Time  
              ELSE Start_Time   
       END,  
           CASE   
       WHEN END_Time > @End_Time OR END_Time IS NULL THEN @End_Time  
        ELSE END_Time   
       END)))/60.0, 0.0)  
                    FROM [dbo].Timed_Event_Details  
                    WHERE PU_Id = @Sheetbreak_PU_Id  
    AND (TEStatus_Id <> @Invalid_Sheetbreak_Id OR TEStatus_Id IS NULL)  
    AND Start_Time < @End_Time  
    AND (End_Time > @Start_Time OR END_Time IS NULL)  
  
                    IF @Reel_Time > 0  
                         BEGIN  
                         SELECT @Sample_Value = @Value*(convert(real, datediff(s,@Start_Time,@End_Time))/60-@Downtime-@Sheetbreak_Time)/@Reel_Time  
                         END  
                    ELSE  
                         BEGIN  
                         SELECT @Sample_Value = 0  
                         END  
  
                    -- Return results for sample  
                    INSERT INTO @Tests( Var_Id,  
     PU_Id,  
     Result,  
     Result_On)  
                    VALUES ( @Var_Id,  
    @Turnover_PU_Id,  
    ltrim(str(@Sample_Value, 25, @Precision)),  
    @End_Time)  
  
                    --Increment to next sample  
                    SELECT @Start_Time = @End_Time  
                    FETCH NEXT FROM TimeStamps INTO @End_Time  
                    END  
  
               CLOSE TimeStamps  
               DEALLOCATE TimeStamps  
  
               -- Reinitialize  
               SELECT @Downtime   = 0.0,  
   @Sheetbreak_Time = 0.0  
  
               -- Get downtime for remaining period  
               SELECT @Downtime = isnull(convert(real, sum(datediff(s,   
       CASE  
       WHEN Start_Time < @Start_Time THEN @Start_Time  
              ELSE Start_Time   
       END,  
           CASE   
       WHEN END_Time > @TimeStamp OR END_Time IS NULL THEN @TimeStamp  
        ELSE END_Time   
       END)))/60.0, 0.0)  
               FROM [dbo].Timed_Event_Details  
               WHERE PU_Id = @Downtime_PU_Id  
   AND (TEStatus_Id <> @Invalid_Downtime_Id OR TEStatus_Id IS NULL)  
   AND Start_Time < @TimeStamp  
   AND (End_Time > @Start_Time OR END_Time IS NULL)  
  
               -- Get sheetbreak time total  
               SELECT @Sheetbreak_Time = isnull(convert(real, Sum(datediff(s,  
       CASE  
       WHEN Start_Time < @Start_Time THEN @Start_Time  
              ELSE Start_Time   
       END,  
           CASE  
       WHEN END_Time > @TimeStamp OR END_Time IS NULL THEN @TimeStamp  
        ELSE END_Time   
       END)))/60.0, 0.0)  
               FROM [dbo].Timed_Event_Details  
               WHERE PU_Id = @Sheetbreak_PU_Id  
   AND (TEStatus_Id <> @Invalid_Sheetbreak_Id OR TEStatus_Id IS NULL)  
   AND Start_Time < @TimeStamp  
   AND (End_Time > @Start_Time OR END_Time IS NULL)  
  
               IF @Reel_Time > 0  
                   BEGIN  
                   SELECT @Sample_Value = @Value*(convert(real, datediff(s,@Start_Time,@TimeStamp))/60-@Downtime-@Sheetbreak_Time)/@Reel_Time  
                   END  
               ELSE  
                   BEGIN  
   SELECT @Sample_Value = 0  
                   END  
  
               SELECT @Output_Value = ltrim(str(@Sample_Value, 25, @Precision))  
               END  
          END  
     END  
  
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
  
  
  
SET NOCOUNT OFF  
  
  
