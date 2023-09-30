CREATE PROCEDURE [dbo].[spMES_GetActiveProducts] 
					 @UnitIds nvarchar(max),
                     @LineIds nvarchar(max),
                     @StartTime datetime,
                     @EndTime datetime
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @AllUnits Table (id int identity(1,1),PU_Id Int)
    DECLARE @ActiveProduct Table (UnitId int, ProdId Int,StartTime DateTime,EndTime DateTime)
    DECLARE @NoOfunit int, @unit int
    DECLARE @xml XML
              
	   IF @UnitIds IS NOT NULL
	   Begin
	
          SET @xml = cast(('<X>'+replace(@UnitIds,',','</X><X>')+'</X>') as xml)
          INSERT INTO @AllUnits(Pu_Id)
          SELECT N.value('.', 'int') FROM @xml.nodes('X') AS T(N)
	   END
	
	   IF @LineIds IS NOT NULL
	   Begin

          SET @xml = cast(('<X>'+replace(@LineIds,',','</X><X>')+'</X>') as xml)
          
          ;WITH S AS (SELECT N.value('.', 'int') Pl_Id FROM @xml.nodes('X') AS T(N) )
          INSERT INTO @AllUnits(Pu_Id)
          Select p.pu_Id from Prod_Units_Base P Join S pl on pl.Pl_Id = p.Pl_id
          WHERE not exists (Select 1 from @AllUnits Where Pu_Id = P.Pu_id)

       END

       set @NoOfunit = (SELECT COUNT(1) FROM @AllUnits)
	   Declare @Units dbo.UnitsType
	   Insert Into @Units
	   Select Pu_id,0,@startTime,@EndTime,NULL,NULL From @AllUnits

		Select 
			Start_time, Case when ENd_Time is null then @endTime else end_time end end_time,Prod_Id,PU_Id 
		into #ProdStarts from Production_Starts PS 
		where 
			((@StartTime <= Ps.End_Time AND @endTime > PS.Start_Time) OR PS.End_Time IS NULL)
			and Pu_Id in (Select Pu_Id from @AllUnits) 
		Order by 
			Pu_Id, Start_Time
		Delete from #ProdStarts where Start_Time >= @endTime

		UPDATE #ProdStarts SET end_time = Case when end_time > @endTime Then @endTime Else end_time end

		;WITH S AS 
		(
			Select 
				Start_Time,Case when ENd_Time is null then @endTime else end_time end end_time,Prod_Id,PU_Id 
			from 
				Production_Starts where ((Start_time <=@endTime and End_Time >=@StartTime ) OR End_time IS NULL)
				and Pu_Id in (Select Pu_Id from @AllUnits)
		)
		,TmpEvents as 
 		(
 	  	 select 
 	  	  	 Otr.Pu_Id, Otr.Applied_Product,Start_Time,TimeStamp,sum(case when Otr.Prev_Pu_Id = Otr.Pu_Id AND Otr.Prev_Prod_Id = Otr.Applied_Product 
 	  	  	 and Otr.Start_Time = Otr.Prev_End_Time then 0 else 1 end) over(order by Otr.Pu_Id, Otr.Applied_Product,Otr.Start_Time) as [SrNo]
 	  	 from 
 	  	  	 (
 	  	  	  	 select 
 	  	  	  	  	 Inr.Pu_Id, Inr.Applied_Product,Inr.Start_Time,Inr.TimeStamp,
 	  	  	  	  	 lag(Inr.Pu_Id, 1, null) over(order by Inr.Pu_Id, Inr.Applied_Product,Inr.Start_Time) as [Prev_Pu_Id],
 	  	  	  	  	 lag(Inr.Applied_Product, 1, null) over(order by Inr.Pu_Id, Inr.Applied_Product,Inr.Start_Time) as [Prev_Prod_Id],
 	  	  	  	  	 lag(Inr.TimeStamp, 1, null) over(order by Inr.Pu_Id, Inr.Applied_Product,Inr.Start_Time) as [Prev_End_Time]
 	  	  	  	 from 
 	  	  	  	  	 (
					 Select E.Start_Time, TimeStamp, ISNULL(Applied_Product,0)Applied_Product,E.pu_Id  from Events E					 
					 ) Inr where 
					 Timestamp between @StartTime and @endTime
					 and Pu_Id in (Select Pu_Id from @AllUnits)
 	  	  	 ) Otr
		)
		,TmpEventsGrpd as 
		( 	 
			Select Min(Start_Time) Start_Time,Max(TimeStamp) End_Time, Pu_Id,Applied_Product  From TmpEvents Group by Pu_Id,Applied_Product, SrNo
		)
		Select * into #temp from TmpEventsGrpd T 

		UPDATE T 
		set 
			Applied_Product = P.Prod_Id, 
			T.Start_Time = Case when T.Start_Time >= P.Start_Time Then T.Start_Time ELse P.Start_Time ENd,
			T.End_Time = CASE when T.End_Time <=P.end_time Then T.End_Time ELSE p.end_time END
		from 
			#temp T join #ProdStarts P on P.PU_Id = T.PU_Id 
			and T.End_Time between P.Start_Time and  P.end_time and  T.Start_Time between P.Start_Time and  P.end_time
		where T.Applied_Product = 0 
	  
		Insert into #temp 
		Select Start_Time,end_time,PU_Id,Prod_Id from #ProdStarts where PU_Id not in(Select PU_Id from #temp where Applied_Product <> 0)
	  
		UPDATE #temp set Start_Time = Case when Start_Time < @StartTime Then @StartTime Else Start_Time End 

		;with S as 
		(
			Select max(End_Time) MaxEnd_Time,pu_Id from #temp Group by pu_Id 
		)
		UPDATE T 
		SET 
			T.End_Time = Case when s.MaxEnd_Time < @endTime Then @endTime Else T.End_Time END 
		from S JOIN #temp T on T.PU_Id= S.PU_Id and T.End_Time = S.MaxEnd_Time
		
		Delete from #temp Where Applied_Product =0
		
		Select  
			Pu_Id UnitId, Applied_Product ProdId,Start_Time StartTime,End_Time EndTime  
		from #temp T
		Order by T.pu_Id,T.Start_Time
		
		Drop table #temp
		Drop table #ProdStarts 

	END


