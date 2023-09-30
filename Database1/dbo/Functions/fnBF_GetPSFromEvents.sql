CREATE FUNCTION [dbo].[fnBF_GetPSFromEvents](@UnitId int, @StartTime datetime, @EndTime datetime,@MoveInProgressTimeStatus Int = 0) 
 	 returns  @RunTimes Table(ProdId Int, StartTime datetime, EndTime datetime)
AS 
/* ##### fnBF_GetPSFromEvents #####
Description 	 : returns all the events for a product in particular timeperiod
Creation Date 	 : if any
Created By 	 : if any
#### Update History ####
DATE 	  	  	  	 Modified By 	  	 UserStory/Defect No 	  	 Comments 	  	 
---- 	  	  	  	 ----------- 	  	  	 ------------------- 	  	  	  	 --------
2021-03-20 	 Prasad 	  	  	  	  	  	  	  	  	  	  	  	  	 
*/
BEGIN
 	 DECLARE   @Prod_Starts TABLE(Pu_Id Int, prod_id Int, Start_Time DateTime, End_Time DateTime NULL)
 	 DECLARE @CurrentEndTime DateTime,@NextEnd DateTime,@CurrentStartTime DateTime,@CurrentProdId Int,@LastProdId Int
 	 DECLARE @Start Int, @PrevEnd DateTime, @End Int,@Start2 Int
  	 DECLARE @EventStatus Int,@EventId Int,@NextEvent Int
  	 IF @MoveInProgressTimeStatus Is NULL
  	  	 SET @MoveInProgressTimeStatus = 0 	  
 	  
 	 Declare @Times Table(StartTime Datetime, EndTime datetime,Puid int,ProdId int,EventId int)
 	 Declare @Times_Final Table(StartTime Datetime, EndTime datetime,Puid int,ProdId int,EventId int,SrNo Int)
 	 Declare   @PeriodTimes Table (StartTime Datetime, EndTime datetime,PsId int,ProdId int)
 	 Insert Into @Times
      Select ISNULL(Start_time,LAG(TimeStamp,1) OVER (Partition By PU_Id Order By Timestamp)), TimeStamp,@UnitId,Applied_Product,Event_Id from Events Where Pu_ID = @UnitId and TimeStamp >= @starttime and TimeStamp <= @EndTime 
 	 Declare @TimestampOfFirstEventRecord Datetime
 	 ;WITH S AS
 	 (
            Select EventId,EndTime from @Times Where StartTime IS NULL
 	 )
      Select Top 1 @TimestampOfFirstEventRecord= TimeStamp  from Events E Where Pu_Id= @UnitId AND E.TimeStamp < (Select EndTime from S ) ORder by TimeStamp desc
 	 --Can change this to timestamp instead of eventId
 	 /*
 	 Set starttime of event if it is not set
 	 1. in case event is the first one and start time is not set
 	 */
 	 Insert Into @PeriodTimes
 	 Select Ps.Start_time, Ps.End_Time,Ps.Start_Id,ISNULL(E.ProdId,Ps.Prod_Id) from Production_Starts Ps 
 	 JOIN @Times E On E.PUId = Ps.pu_id  
 	 where Ps.pu_Id =@UnitId and E.EndTime >= ps.Start_Time and (E.EndTime <=ps.End_Time OR ps.End_Time IS NULL)
 	   
 	  
 	 UPDATE @Times SET StartTime = @TimestampOfFirstEventRecord Where StartTime IS NULL;
 	 UPDATE @Times SET StartTime =@StartTime WHERE StartTime < @StartTime
 	 DELETE FROM @Times WHERE StartTime = EndTime 	  
 	 UPDATE @PeriodTimes SET EndTime = '9999-12-31' where EndTime IS NULL 	 
 	 
 	  ;WITH S AS (
 	  Select Distinct StartTime,puId,ProdId from @Times
 	  Union
 	  Select Distinct Endtime,puId,ProdId from @times
 	  union 
 	  Select distinct Starttime,@UnitId,ProdId from @PeriodTimes
 	  union
 	  Select distinct endtime,@UnitId,ProdId from @PeriodTimes
 	  Union 
 	  select @starttime,@UnitId,NULL
 	  UNION
 	  SELECT @EndTime,@UnitId,NULL
 	  )
 	  INSERT INTO @Times_Final (StartTime,EndTime,Puid,ProdId)
 	  Select StartTime,LEAD(Starttime) Over (Order By Starttime) [EndTime],PuId, NULL from S Order by Starttime
 	   Delete from   @Times_Final where EndTime IS NULL
       Delete from @Times_Final where Endtime <@StartTime OR StartTime > @EndTime
      UPDATE 
      A SET A.ProdId = B.ProdId
      From  @Times_Final A  Join @times B ON B.StartTime = A.StartTime and B.EndTime = A.EndTime
 	 UPDATE E SET E.ProdId = ISNULL(E.ProdId,Ps.Prod_Id) from Production_Starts Ps 
 	 JOIN @Times_Final E On E.PUId = Ps.Pu_Id AND Ps.Start_Time  < E.EndTime and (Ps.End_Time >= E.EndTime or Ps.End_Time Is Null)
 	 where Ps.Pu_Id =@UnitId and Ps.Start_Time <@EndTime and (Ps.End_Time >= @starttime or Ps.End_Time is null)
 	 and E.ProdId IS NULL 	     
 	  
 	 UPDATE E Set E.Starttime = Case when E.Starttime < @starttime Then @starttime Else E.Starttime  ENd,E.EndTime = Case when E.EndTime > @EndTime OR E.EndTime IS NULL Then @EndTime Else E.EndTime  End From @Times_Final E 
 	 DELETE From @Times_Final Where StartTime = EndTime 
 	 DELETE From @Times_Final Where StartTime > EndTime 
 	 
 	 ;WITH S AS (Select row_NUmber() Over (Order by StartTime) SRno, Starttime,puId from @Times_Final)
 	 UPDATE T SET T.SrNo = S.SRno FROM @Times_Final T JOIN S ON S.StartTime = T.StartTime  and S.Puid =T.Puid
 	  
 	  	 ;WIth s as(
Select SrNo Id, StartTime Start_Time,EndTime End_Time, ProdId Prod_Id,PuId from @Times_Final
)
,S2 As ( select Otr.Id, Otr.Prod_Id,Start_Time,End_Time,
    sum(case when Otr.Prev_Prod_Id = Otr.Prod_Id and Otr.Prev_End_Time= Otr.Start_Time and Otr.Prev_PUId = Otr.puID then 0 else 1 end) over(order by Otr.Id) as [SrNo]
from (
    select Inr.Id, Inr.Prod_Id, lag(Inr.Prod_Id, 1, null) over(order by Inr.ID) as [Prev_Prod_Id],Start_Time, End_Time,PUID,
 	 lag(Inr.End_Time, 1, null) over(order by Inr.ID) as [Prev_End_Time],
 	 lag(Inr.Puid, 1, null) over(order by Inr.ID) as [Prev_PUId]
    from s Inr
) Otr
)
Insert Into @RunTimes(StartTime, EndTime,ProdId)
Select   Min(Start_Time), Max(End_Time),Prod_Id from S2 Group by SrNo, Prod_id Order By SrNo
 	 RETURN
 	  
END
