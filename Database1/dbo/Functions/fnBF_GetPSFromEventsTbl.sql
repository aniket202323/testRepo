CREATE FUNCTION [dbo].[fnBF_GetPSFromEventsTbl](@PUId_Table dbo.UnitsType READONLY,@UnitId varchar(max), @StartTime datetime, @EndTime datetime,@MoveInProgressTimeStatus Int = 0) 
  	  returns  @RunTimes Table(ProdId Int, StartTime datetime, EndTime datetime,Pu_Id Int)
AS 
/* ##### fnBF_GetPSFromEventsTbl #####
Description  	  : returns all the events for a product in particular timeperiod
Creation Date  	  : if any
Created By  	  : if any
#### Update History ####
DATE  	    	    	    	  Modified By  	    	  UserStory/Defect No  	    	  Comments  	    	  
----  	    	    	    	  -----------  	    	    	  -------------------  	    	    	    	  --------
2018-02-20  	  Prasad  	    	    	    	  s
  	    	    	    	    	    	    	    	    	  
*/
BEGIN 
 	 Declare @Times Table(StartTime Datetime, EndTime datetime,Puid int,ProdId int,EventId int)
 	  Declare @Times_RemoveDups Table(StartTime Datetime, EndTime datetime,Puid int,ProdId int,EventId int)
  	  Declare @Times_Final Table(StartTime Datetime, EndTime datetime,Puid int,ProdId int,EventId int,Id int)
 	 Declare   @PeriodTimes Table (StartTime Datetime, EndTime datetime,PsId int,ProdId int, PuId int)
 	 Insert Into @Times
  	  Select ISNULL(Start_time,LAG(TimeStamp,1) OVER (Partition By E.PU_Id Order By E.TimeStamp)), TimeStamp,Pu.Pu_Id,ISNULL(Applied_Product,0),E.Event_Id from Events E
  	  JOIN @PUId_Table PU ON PU.Pu_Id = E.PU_Id
 	 Where TimeStamp >= PU.Start_Date1 and TimeStamp <= PU.End_Date1 
 	 Declare @cnt int,@total int,@localPUID int
 	 DECLARE @Units TABLE(PUId int, Srno Int Identity(1,1))
 	 Declare @TimestampOfFirstEventRecord Datetime
 	 Insert into @Units(PUId)
 	 Select Distinct pu_Id From @PUId_Table Order by pu_Id
 	 SET @total = @@rowcount 
 	 SET @cnt =1
 	 WHile @cnt <= @total
 	 BEgin
 	  	 SELECT @localPUID = PUId from @Units where Srno = @cnt
 	  	 IF EXISTS (SELECT 1 from @Times Where StartTime IS NULL AND Puid = @localPUID)
 	  	 Begin
 	  	  	 SET @TimestampOfFirstEventRecord = NULL;
 	  	  	 ;WITH S AS
 	  	  	 (
 	  	  	  	 Select EventId,EndTime from @Times Where StartTime IS NULL AND Puid = @localPUID
 	  	  	 )
 	  	  	 Select Top 1 @TimestampOfFirstEventRecord= TimeStamp  from Events E Where Pu_Id= @localPUID AND  E.TimeStamp < (Select EndTime from S ) ORder by TimeStamp desc
 	  	  	 UPDATE @Times SET StartTime = @TimestampOfFirstEventRecord Where StartTime IS NULL AND Puid= @localPUID ;
 	  	  	 UPDATE @Times SET StartTime = @StartTime WHERE StartTime < @StartTime AND Puid= @localPUID 
 	  	  	 DELETE FROM @Times WHERE StartTime = EndTime AND Puid= @localPUID 
 	  	 End
 	  	 SET @cnt = @cnt+1
 	 End
  	  
 	   
     ;With s as 
  	  (
  	    	  select 
  	    	    	  Otr.PuId, Otr.ProdId,StartTime,EndTime,sum(case when Otr.Prev_PuId = Otr.PuId AND Otr.Prev_ProdId = Otr.ProdId 
  	    	    	  and Otr.StartTime = Otr.Prev_EndTime then 0 else 1 end) over(partition by puId order by Otr.EventId ) as [SrNo]
  	    	  from 
  	    	    	  (
  	    	    	    	  select 
  	    	    	    	    	  Inr.PuId, Inr.ProdId,Inr.StartTime,Inr.EndTime,Inr.EventId,
  	    	    	    	    	  lag(Inr.PuId, 1, null) over(partition by puId order by Inr.EventId) as [Prev_PuId],
  	    	    	    	    	  lag(Inr.ProdId, 1, null) over(partition by puId order by Inr.EventId) as [Prev_ProdId],
  	    	    	    	    	  lag(Inr.EndTime, 1, null) over(partition by puId order by Inr.EventId) as [Prev_EndTime]
  	    	    	    	  from 
  	    	    	    	    	  @Times Inr
  	    	    	  ) Otr
  	  )
  	  Insert into @Times_RemoveDups (StartTime, EndTime,Puid,ProdId)
  	  Select Min(StartTime) StartTime,Max(EndTime) EndTime, PuId,ProdId  From S Group by PuId,ProdId, SrNo Order by 3,1
 	   
 	  Delete From @Times
 	  Insert into @Times(StartTime, EndTime,Puid,ProdId)
 	  Select StartTime, EndTime,Puid,ProdId from @Times_RemoveDups
 	  Insert Into @PeriodTimes
  	  Select Ps.Start_time, Ps.End_Time,Ps.Start_Id,ISNULL(E.ProdId,Ps.Prod_Id),ps.PU_Id from Production_Starts Ps 
  	  JOIN @Times E On E.PUId = Ps.pu_id  
  	  --JOIN @PUId_Table PU on Pu.Pu_Id = Ps.Pu_id
  	  where /*Ps.pu_Id =Pu.pu_id and*/ E.EndTime >= ps.Start_Time and (E.EndTime <=ps.End_Time OR ps.End_Time IS NULL)
  	   
 	  
 	 UPDATE @PeriodTimes SET EndTime = '9999-12-31' where EndTime IS NULL;
 	 
 	 ;WITH S AS (
 	  Select Distinct StartTime,puId,ProdId from @Times
 	  Union
 	  Select Distinct Endtime,puId,ProdId from @times
 	  union 
 	  Select distinct Starttime,PuId,ProdId from @PeriodTimes
 	  union
 	  Select distinct endtime,PuId,ProdId from @PeriodTimes
 	  UNION
 	  SELECT MIN(Start_Date1),pu_Id, NULL from @PUId_Table Group by Pu_id
 	  UNION
 	  SELECT MAX(End_Date1),pu_Id, NULL from @PUId_Table Group by Pu_id
 	  )
 	  INSERT INTO @Times_Final (StartTime,EndTime,Puid,ProdId)
 	  Select StartTime,LEAD(Starttime) Over (partition by puId Order By PuId,Starttime) [EndTime],PuId, NULL from S Order by Starttime
 	  Delete from   @Times_Final where EndTime IS NULL
 	  DELETE FROM @Times_Final WHERE StartTime IS NULL
 	   
 	 -- Insert into @Times_Final(StartTime, EndTime,Puid ,ProdId)
 	 -- select   Ps.Start_Time,Ps.End_Time,Ps.PU_Id ,Ps.Prod_Id
 	   -- from Production_Starts Ps
 	   -- JOIN @PUId_Table PU
 	   -- ON Ps.pu_Id =PU.Pu_Id WHERE Ps.Start_Time < PU.End_Date1 and (Ps.End_Time >= PU.Start_Date1 or Ps.End_Time is null)
 	 -- and not exists (select 1 from @PeriodTimes where PsId = Ps.Start_Id)
 	  UPDATE 
      A SET A.ProdId = B.ProdId
      From  @Times_Final A  Join @times B ON B.StartTime = A.StartTime and B.EndTime = A.EndTime and B.Puid = A.Puid
 	 UPDATE E SET E.ProdId = ISNULL(E.ProdId,Ps.Prod_Id) from Production_Starts Ps 
 	 JOIN @Times_Final E On E.Puid = Ps.pu_id AND Ps.Start_Time  < E.EndTime and (Ps.End_Time >= E.EndTime or Ps.End_Time Is Null)
 	 JOIN @PUId_Table PU ON PU.Pu_Id = E.Puid
 	 where  Ps.Start_Time < PU.End_Date1 and (Ps.End_Time >= PU.Start_Date1 or Ps.End_Time is null) and PU.Pu_Id = E.Puid
 	  
 	 and E.ProdId IS NULL
 	 UPDATE E Set E.Starttime = Case when E.Starttime < PU.Start_Date1 Then PU.Start_Date1 Else E.Starttime  ENd,E.EndTime = Case when E.EndTime > PU.End_Date1 OR E.EndTime IS NULL Then PU.End_Date1 Else E.EndTime  End From @Times_Final E 
 	 JOIN @PUId_Table PU ON PU.Pu_Id = E.Puid
 	 DELETE From @Times_Final Where StartTime = EndTime 
 	 DELETE From @Times_Final Where StartTime > EndTime
 	 
 	 ;WITH S AS (Select row_NUmber() Over (partition by puId Order by StartTime) SRno, Starttime,puId from @Times_Final)
 	 UPDATE T SET T.Id = S.SRno FROM @Times_Final T JOIN S ON S.StartTime = T.StartTime  and S.Puid =T.Puid
 	 
 	  	 
 	 ;With s as 
 	 (
 	  	 select 
 	  	  	 Otr.PuId, Otr.ProdId,StartTime,EndTime,sum(case when Otr.Prev_PuId = Otr.PuId AND Otr.Prev_ProdId = Otr.ProdId 
 	  	  	 and Otr.StartTime = Otr.Prev_EndTime then 0 else 1 end) over(partition by puId order by Otr.Id ) as [SrNo]
 	  	 from 
 	  	  	 (
 	  	  	  	 select 
 	  	  	  	  	 Inr.PuId, Inr.ProdId,Inr.StartTime,Inr.EndTime,Inr.Id,
 	  	  	  	  	 lag(Inr.PuId, 1, null) over(partition by puId order by Inr.Id) as [Prev_PuId],
 	  	  	  	  	 lag(Inr.ProdId, 1, null) over(partition by puId order by Inr.Id) as [Prev_ProdId],
 	  	  	  	  	 lag(Inr.EndTime, 1, null) over(partition by puId order by Inr.Id) as [Prev_EndTime]
 	  	  	  	 from 
 	  	  	  	  	 @Times_Final Inr
 	  	  	 ) Otr
 	 )
 	 INSERT INTO @RunTimes (StartTime , EndTime,Pu_Id,ProdId)
 	 Select Min(StartTime) StartTime,Max(EndTime) EndTime, PuId,ProdId  From S Group by PuId,ProdId, SrNo Order by 3,1
 	  
  	    	   	 
 	   
  	  RETURN
END
