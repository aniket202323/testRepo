/*
These are the key Columns in Prod_Units
Downtime_External_Category
Downtime_Scheduled_Category
Performance_Downtime_Category (ECR #29510)
Declare @StartTime datetime, @EndTime datetime, @Unit int, @Category int, @FILTER_NP_TIME int
Select @Unit=2, @Category=6, @Filter_NP_Time=1
Select @StartTime = '2004-01-01 7:00:00', @EndTime = '2005-01-21 7:00:00'
Select @StartTime='2006-02-22 7:00:00', @EndTime='2006-02-22 12:00:00'
Select @StartTime='2006-02-23 7:19:00', @EndTime='2006-02-23 07:26:00'
select dbo.fnCMN_GetCategoryTimeByUnit(@StartTime, @EndTime, @Unit, @Category,@Filter_NP_Time)
Event_Reason_Catagories
ERC_Id      ERC_Desc                                           
----------- -------------------------------------------------- 
1           Outside Area
2           Unavailable Time
3           Planned Downtime
4           Unplanned Downtime
5           Breaks
6           Performance Downtime
*/
CREATE FUNCTION dbo.fnCMN_GetCategoryTimeByUnit(@StartTime DATETIME, @EndTime DATETIME, @Unit INT, @Category INT, @FILTER_NP_TIME INT) 
     RETURNS INT 
AS 
Begin
     DECLARE @TotalTime INT, @TotalNPSeconds int
     SELECT  @TotalTime = 0, @TotalNPSeconds=0
 	  If @FILTER_NP_TIME Is Null Select @FILTER_NP_TIME = 0
     SELECT 
 	  	 @TotalNPSeconds=@TotalNPSeconds + Coalesce(Sum(Non_Productive_Seconds), 0),
 	  	 @TotalTime = @TotalTime + coalesce(sum(
          CASE 
               WHEN c.ERC_ID IS NULL THEN 0 
               ELSE DATEDIFF(second, 
                    CASE WHEN d.Start_Time < @StartTime THEN @StartTime ELSE d.Start_Time END,
                    CASE WHEN d.End_Time IS NULL THEN @EndTime
                         WHEN d.End_Time > @Endtime THEN @EndTime
                         ELSE d.End_Time
                    END)
          END)
          ,0)
     FROM Timed_Event_Details_NPT d
          LEFT OUTER JOIN Event_Reason_Category_data c on c.Event_Reason_Tree_Data_id = d.Event_Reason_Tree_Data_Id
               AND c.erc_id = @Category
     WHERE d.PU_Id = @Unit
          AND d.Start_Time >= @StartTime
          AND d.Start_Time < @EndTime
     SELECT 
 	  	 @TotalNPSeconds=@TotalNPSeconds + Coalesce(Sum(Non_Productive_Seconds), 0),
 	  	 @TotalTime = @TotalTime + coalesce(sum(
          CASE
               WHEN c.erc_Id IS NULL THEN 0
               ELSE DATEDIFF(second,
                    CASE WHEN d.Start_Time < @StartTime THEN @StartTime ELSE d.Start_Time END,
                    CASE WHEN d.End_Time IS NULL THEN @EndTime
                         WHEN D.End_Time > @EndTime THEN @EndTime
                         ELSE D.End_Time
                    END)
          END)
          ,0)
     FROM Timed_Event_Details_NPT d
          LEFT OUTER JOIN Event_Reason_Category_data c on c.Event_Reason_Tree_Data_id = d.Event_Reason_Tree_Data_Id
               AND c.erc_id = @Category
     WHERE d.PU_Id = @Unit
          AND d.Start_Time = (
               SELECT MAX(Start_Time) FROM Timed_Event_Details
               WHERE PU_Id = @Unit
                    AND Start_Time < @StartTime)
          AND ((d.End_Time > @StartTime) or (d.End_Time Is Null))
 	 -- Remove Non-Productive Time
 	 If @FILTER_NP_TIME > 0 
 	  	 Begin
 	  	  	 If @TotalNPSeconds > @TotalTime 
 	  	  	  	 Select @TotalTime=0
 	  	  	 Else
 	  	  	  	 Select @TotalTime = @TotalTime - @TotalNPSeconds
 	  	 End
     RETURN @TotalTime
END
