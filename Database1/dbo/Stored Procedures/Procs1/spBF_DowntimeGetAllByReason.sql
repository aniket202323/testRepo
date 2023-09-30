/* 
Execute spBF_DowntimeGetAllByReason '9/1/2016','9/2/2016',1,null,2,1,1
*/
CREATE PROCEDURE dbo.spBF_DowntimeGetAllByReason
 	   @StartTime DateTime
 	 , @Endtime 	 DateTime
 	 , @MachineId 	 Int 
 	 , @InTimeZone 	 nVarChar(200) = null
 	 , @pageSize 	  	  	  	  	 Int = 4 	  	  	  	 -- # Results returned
 	 , @pageNum 	  	  	  	  	 Int = 1 	  	  	  	 -- Offest fro results
 	 , @SortBy 	  	  	  	  	 Int = 1 	  	  	  	 -- 1 Sort by Description, otherwise Sort By Duration
 	 ,@OEEParameter nvarchar(50) =NULL--Time based OEE : Availability/Performance/Quality. NULL in case of Classic OEE
 	 ,@FilterNonProductiveTime INT = 0 
 	 ,@ExcludeProductInfo Bit = 0
AS
/* ##### spBF_DowntimeGetAllByReason #####
Description 	 : Returns data for Gaant chart (Unit level) for Availability donut in case of classic OEE and for Availability, Performance & Quality donuts in case of Time based OEE
Creation Date 	 : if any
Created By 	 : if any
#### Update History ####
DATE 	  	  	  	 Modified By 	  	  	 UserStory/Defect No 	  	  	  	 Comments 	  	 
---- 	  	  	  	 ----------- 	  	  	 ------------------- 	  	  	  	 --------
2018-02-20 	  	  	 Prasad 	  	  	  	 7.0 SP3 	 F28159 	  	  	  	  	 Modified procedure to handle time based downtime calculation.
2018-05-28 	  	  	 Prasad 	  	  	  	 7.0 SP4 US255630 & US255626 	  	 Passed actual filter for NPT
2018-09-25 	  	  	 Prasad 	  	  	  	 7.0 SP4 DE28396 	  	  	  	  	 Added @ExcludeProductInfo parameter to decide whether include product info in the resultset or not
2018-09-26 	  	  	 Prasad 	  	  	  	 7.0 SP4 DE28396 	  	  	  	  	 code changed for grouping continous downtime for similar reason, category 
2018-09-30 	  	  	 Prasad 	  	  	  	 7.0 SP4 DE90117 	  	  	  	  	 To accumulate TotalMinutes across specific Reason
*/
IF rtrim(ltrim(@InTimeZone)) = '' SET @InTimeZone = Null
SET @InTimeZone = coalesce(@InTimeZone,'UTC')
If @OEEParameter IS NOT NULL
Begin
 	 If (@OEEParameter = 'Quality')
 	 Begin
 	  	 Set @OEEParameter = 'Quality losses'
 	 End
 	 Else
 	 Begin
 	  	 Set @OEEParameter = @OEEParameter + ' loss'
 	 End
End
DECLARE   @DownTime TABLE (
 	 Detail_Id Int, Start_Time DateTime, End_Time DateTime NULL, Duration Float NULL, Uptime  Float NULL
 	 , Unit nvarchar(100), Location nvarchar(100), Reason1 nvarchar(100), Reason2 nvarchar(100), Reason3 nVarChar(100)
 	 , Reason4 nvarchar(100), Action1 nvarchar(100), Action2 nvarchar(100), Action3 nvarchar(100), Action4 nVarChar(100) 	 
 	 , Fault nvarchar(100), Status nvarchar(100), First_Comment_Id  Int NULL, Last_Comment_Id Int NULL, Crew_Desc nvarchar(10) NULL
 	 , Shift_Desc nvarchar(10) NULL, IsNPT tinyint 	 NULL,ProductCode nvarchar(100),[ProcessORDER] nvarchar(100),[Path Code]  nVarChar(100)
 	 ,[NPT Category]  nvarchar(100),UnitId 	 Int,TotalSeconds BigInt 	 ,Category nvarchar(100))
DECLARE @FilteredDt TABLE (Id Int Identity (1,1), Reason1 nvarchar(100),TotalSeconds BigInt)
DECLARE @PagedDT TABLE  ( RowID int IDENTITY, Reason1 nvarchar(100))
DECLARE @startRow 	 Int
DECLARE @endRow 	  	 Int
DECLARE @sMachineId nvarchar(10)
SET @sMachineId = Convert(nvarchar(10),@MachineId)
SET @SortBy = Coalesce(@SortBy,1)
IF @SortBy != 1 SET @SortBy = 2
INSERT INTO @DownTime(Detail_Id, Start_Time, End_Time , Duration, Uptime, 
 	  	  	  	  	  	 Unit, Location, Reason1, Reason2, Reason3,
 	  	  	  	  	  	 Reason4, Action1, Action2, Action3, Action4, 
 	  	  	  	  	  	 Fault, Status, First_Comment_Id , Last_Comment_Id 	 , Crew_Desc
 	  	  	  	  	  	 , Shift_Desc, IsNPT 	 ,ProductCode,[ProcessORDER] ,[Path Code]
 	  	  	  	  	  	 ,[NPT Category] ,UnitId,Category)
EXECUTE dbo.spBF_DowntimeGetAll 	   @StartTime, @Endtime, @sMachineId, @InTimeZone 	 , ',', @FilterNonProductiveTime, 0,NULL, @OEEParameter,@ExcludeProductInfo;
--Passing filter for NPT
;WITH toupdate AS
     (SELECT Reason1,TotalSeconds,sum(datediff(Second,Start_Time,End_Time))  OVER (partition BY Reason1) AS z 
      FROM @DownTime
     ) 
UPDATE toupdate 
   SET TotalSeconds = z;
IF @SortBy = 1 
BEGIN
 	 INSERT INTO @FilteredDt(Reason1,TotalSeconds)
 	  	 SELECT Distinct Reason1,TotalSeconds
 	  	  	 FROM @DownTime
 	  	  	 ORDER by reason1
END
ELSE
BEGIN
 	 INSERT INTO  @FilteredDt(Reason1,TotalSeconds)
 	  	 SELECT Distinct Reason1,TotalSeconds
 	  	  	 FROM @DownTime
 	  	  	 ORDER BY TotalSeconds DESC
END
SET @pageNum = coalesce(@pageNum,1)
SET @pageSize = coalesce(@pageSize,20)
SET @pageNum = @pageNum -1
SET @startRow = coalesce(@pageNum * @pageSize,0) + 1
SET @endRow = @startRow + @pageSize - 1
INSERT INTO @PagedDT (Reason1)
 	 SELECT Reason1
 	  	 FROM @FilteredDt
 	  	 WHERE id Between @startRow and @endRow
IF @SortBy = 1 
BEGIN
 	 
 	 ;WITH S AS (
 	  	  	 SELECT 
 	  	  	  	 Start_Time,End_Time,
 	  	  	  	 Reason = a.Reason1,
 	  	  	  	 --TotalMinutes = TotalSeconds / 60
 	  	  	  	 TotalMinutes = Duration
 	  	  	  	 ,a.Category
 	  	  	  	 ,Row_number() over (Order by Detail_id) Id
 	  	  	 FROM 
 	  	  	  	 @Downtime a
 	  	  	  	 Join @PagedDT b on a.Reason1 = b.Reason1
 	  	  	 Where 
 	  	  	  	 (
 	  	  	  	  	 (a.Reason1 = @OEEParameter and @OEEParameter IS NOT NULL)
 	  	  	  	  	 OR
 	  	  	  	  	 (@OEEParameter IS NULL AND 1=1)
 	  	  	  	 )
 	 )
 	 ,S2 As 
 	 ( 
 	  	 select 
 	  	  	 Otr.Id, Otr.Reason, Otr.Category,Start_Time,End_Time,sum(case when Otr.Prev_Reason = Otr.Reason AND Otr.Prev_Category = Otr.Category and Otr.Start_Time = Otr.Prev_End_Time then 0 else 1 end) over(order by Otr.Id) as [SrNo],TotalMinutes
 	  	 from 
 	  	  	 (
 	  	  	  	 select 
 	  	  	  	  	 Inr.Id, Inr.Reason,Inr.Category, 
 	  	  	  	  	 lag(Inr.Reason, 1, null) over(order by Inr.Id) as [Prev_Reason],
 	  	  	  	  	 lag(Inr.Category, 1, null) over(order by Inr.Id) as [Prev_Category],Start_Time, End_Time,TotalMinutes,
 	  	  	  	  	 lag(Inr.End_Time, 1, null) over(order by Inr.Id) as [Prev_End_Time]
 	  	  	  	 from 
 	  	  	  	  	 S Inr
 	  	  	 ) Otr
 	  	  	 --This query is for accumulate continuous downtime records w.r.t. reason n category of downtimes.
 	 )
 	 ,S3 as (Select Min(Start_Time) Start_Time,Max(End_Time) End_Time, Reason, SUM(TotalMinutes) TotalMinutes, Category From S2 Group by Reason, Category, SrNo)
 	 Select Start_Time, End_Time,  Reason, Sum(TotalMinutes) Over (Partition by Reason) TotalMinutes,  Category from S3
 	 --To accumulate TotalMinutes across specific Reason
 	 ORDER by reason,Start_Time,End_Time
END
ELSE
BEGIN
 	 ;WITH S AS (
 	  	  	 SELECT 
 	  	  	  	 Start_Time,End_Time,
 	  	  	  	 Reason = a.Reason1,
 	  	  	  	 --TotalMinutes = TotalSeconds / 60
 	  	  	  	 TotalMinutes = Duration
 	  	  	  	 ,a.Category
 	  	  	  	 ,Row_number() over (Order by Detail_id) Id
 	  	  	 FROM 
 	  	  	  	 @Downtime a
 	  	  	  	 Join @PagedDT b on a.Reason1 = b.Reason1
 	  	  	 Where 
 	  	  	  	 (
 	  	  	  	  	 (a.Reason1 = @OEEParameter and @OEEParameter IS NOT NULL)
 	  	  	  	  	 OR
 	  	  	  	  	 (@OEEParameter IS NULL AND 1=1)
 	  	  	  	 )
 	 )
 	 ,S2 As 
 	 ( 
 	  	 select 
 	  	  	 Otr.Id, Otr.Reason, Otr.Category,Start_Time,End_Time,sum(case when Otr.Prev_Reason = Otr.Reason AND Otr.Prev_Category = Otr.Category and Otr.Start_Time = Otr.Prev_End_Time then 0 else 1 end) over(order by Otr.Id) as [SrNo],TotalMinutes
 	  	 from 
 	  	  	 (
 	  	  	  	 select 
 	  	  	  	  	 Inr.Id, Inr.Reason,Inr.Category, 
 	  	  	  	  	 lag(Inr.Reason, 1, null) over(order by Inr.Id) as [Prev_Reason],
 	  	  	  	  	 lag(Inr.Category, 1, null) over(order by Inr.Id) as [Prev_Category],Start_Time, End_Time,TotalMinutes,
 	  	  	  	  	 lag(Inr.End_Time, 1, null) over(order by Inr.Id) as [Prev_End_Time]
 	  	  	  	 from 
 	  	  	  	  	 S Inr
 	  	  	 ) Otr
 	 )
 	 ,S3 as (Select Min(Start_Time) Start_Time,Max(End_Time) End_Time, Reason, SUM(TotalMinutes)TotalMinutes, Category From S2 Group by Reason, Category, SrNo)
 	 Select Start_Time, End_Time,  Reason,  Sum(TotalMinutes) Over (Partition by Reason) TotalMinutes,  Category from S3
 	 ORDER by TotalMinutes DESC,Reason,Start_Time,End_Time
 	 
END
