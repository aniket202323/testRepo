-- ECR #27198(mt/12-22-2003): Perfomance tuning; drop hinting from Waste_Event_Details in the join clause; add hinting to Events in the from clause
--
Create Procedure dbo.[spXLA_WasteSummary_NPT_Bak_177]
 	   @STime  	 datetime
 	 , @ETime  	 datetime
 	 , @PU_Id  	 int
 	 , @SelectSource 	 int
 	 , @SelectR1  	 int
 	 , @SelectR2  	 int
 	 , @SelectR3  	 int
 	 , @SelectR4  	 int
 	 , @ReasonLevel  	 int
 	 , @ProdId  	 int
 	 , @GroupId  	 int
 	 , @PropId  	 int
 	 , @CharId  	 int
 	 , @Username Varchar(50) = Null
 	 , @Langid Int = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
SELECT @STime = dbo.fnServer_CmnConvertToDBTime(@STime,@InTimeZone)
SELECT @ETime = dbo.fnServer_CmnConvertToDBTime(@ETime,@InTimeZone)
--set nocount on   disabled 10-27-2004:mt ECR #28901 to comply with MSI Multilinugal design
Declare @TotalWaste real
Declare @TotalOperating real
declare @QueryType tinyint
declare @MasterUnit int
DECLARE @Unspecified varchar(50)
Select @MasterUnit = @PU_Id
create table #prod_starts (pu_id int, prod_id int, start_time datetime, end_time datetime NULL)
DECLARE @UserId 	 Int
SELECT @UserId = User_Id
FROM users
WHERE Username = @Username
--EXEC dbo.spXLA_RegisterConnection @UserId,@Langid
--
--SELECT @Unspecified = dbo.fnDBTranslate(@Langid, 38333, 'Unspecified')
--Figure Out Query Type
if @prodid is not null
  select @QueryType = 1  --Single Product
else if @groupid is not null and @propid is null 
  select @QueryType = 2  --Single Group
else if @propid is not null and @groupid is null
  select @QueryType = 3  --Single Characteristic
else if @propid is not null and @groupid is not null
  select @QueryType = 4  --Group and Property  
else
  select @QueryType = 5
if @QueryType = 5 
  begin
         insert into #prod_starts
         select ps.pu_id, ps.prod_id, ps.start_time, ps.end_time
           from production_starts ps
          where pu_id = @MasterUnit 
 	     and (    (start_time between @STime and @ETime) 
 	  	   or (end_time between @STime and @ETime) 
 	  	   or (start_time <= @STime AND (end_time > @ETime OR end_time is null))
 	  	   	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
                )
  end
else if @QueryType = 1
  begin
        insert into #prod_starts
        select ps.pu_id, ps.prod_id, ps.start_time, ps.end_time
          from production_starts ps
          where pu_id = @MasterUnit 
 	     AND prod_id = @prodid 
 	     AND (   (start_time between @STime and @ETime)
                 OR (end_time between @STime and @ETime) 
 	  	  OR (start_time <= @STime AND (end_time > @ETime OR end_time is null))
 	  	   	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
                )
  end
else
  begin
    create table #products (prod_id int)
    if @QueryType = 2 
      begin
         insert into #products
           select prod_id
             from product_group_data
             where product_grp_id = @groupid
      end
    else if @QueryType = 3
      begin
         insert into #products
           Select distinct prod_id 
 	      from pu_characteristics 
             where prop_id = @propid and  
 	            char_id = @charid
      end
    else
      begin
         insert into #products
           select prod_id
             from product_group_data
             where product_grp_id = @groupid
         insert into #products
           Select distinct prod_id 
 	      from pu_characteristics 
             where prop_id = @propid and  
 	            char_id = @charid
      end
        insert into #prod_starts
        select ps.pu_id, ps.prod_id, ps.start_time, ps.end_time
          from production_starts ps
          join #products p on ps.prod_id = p.prod_id 
         where pu_id = @MasterUnit 
 	    AND (   (start_time between @STime and @ETime) 
 	  	 OR (end_time between @STime and @ETime) 
 	  	 OR (start_time <= @STime AND (end_time > @ETime OR end_time is null))
 	  	    --Start_time & End_time condition checked ; MSi/MT/3-21-2001
               ) 
    drop table #products
  end
Create Table #MyReport (
  --ReasonName varchar(30), -- Extend to 100 chars consistent with reason description elsewhere in Proficy DB
  ReasonName varchar(100),
  NumberOfOccurances int NULL,
  TotalReasonUnits real NULL,
  AvgReasonUnits real NULL,
  TotalWasteUnits real NULL,
  TotalOperatingUnits real NULL
)
-- Get All WED Records In Field I Care About
create table #TopNDR (
  TimeStamp datetime,
  Amount real NULL,
  Reason_Name varchar(100) NULL,
  SourcePU int NULL,
  R1_Id int NULL,
  R2_Id int NULL,
  R3_Id int NULL,
  R4_Id int NULL,
  Type_Id int NULL,
  Meas_Id int NULL
)
If @QueryType <> 5 
  Begin
    -- Get All The Event Based Waste
    insert into #TopNDR (TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, Type_Id, Meas_Id)
      select EV.TimeStamp, D.Amount, D.Source_PU_Id, D.Reason_Level1, D.Reason_Level2,D.Reason_Level3,D.Reason_Level4,WET_Id,WEMT_Id
      From Events EV 
      --{ ECR #27198(mt/12-22-2003)
      JOIN Waste_Event_Details D on D.Event_Id = EV.Event_Id
      --}
  	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
      JOIN #Prod_Starts PS on PS.Start_Time <= EV.TimeStamp AND (PS.End_Time > EV.TimeStamp OR PS.End_Time Is NULL) 
      where EV.PU_Id = @PU_Id and 
            EV.TimeStamp > @STime and 
            EV.TimeStamp <= @ETime   
    -- Get All The Time Based Waste
    insert into #TopNDR (TimeStamp, Amount,SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, Type_Id, Meas_Id)
      select D.TimeStamp, D.Amount, D.Source_PU_Id, D.Reason_Level1, D.Reason_Level2,D.Reason_Level3,D.Reason_Level4,WET_Id,WEMT_Id  
      From Waste_Event_Details D WITH (INDEX(WEvent_Details_IDX_PUIdTime))
  	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
      JOIN #Prod_Starts PS on PS.Start_Time <= D.TimeStamp AND (PS.End_Time > D.TimeStamp OR PS.End_Time Is NULL)
      where D.PU_Id = @PU_Id and 
            D.TimeStamp > @STime and 
            D.TimeStamp <= @ETime   
  End
Else
  Begin
    -- Get All The Event Based Waste
    insert into #TopNDR (TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, Type_Id, Meas_Id)
      select EV.TimeStamp, D.Amount, D.Source_PU_Id, D.Reason_Level1, D.Reason_Level2,D.Reason_Level3,D.Reason_Level4,WET_Id,WEMT_Id
      From Events EV 
      --{ ECR #27198(mt/12-22-2003)
      JOIN Waste_Event_Details D on D.Event_Id = EV.Event_Id
      --}
      where EV.PU_Id = @PU_Id and 
            EV.TimeStamp > @STime and 
            EV.TimeStamp <= @ETime   
    -- Get All The Time Based Waste
    insert into #TopNDR (TimeStamp, Amount,SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, Type_Id, Meas_Id)
      select D.TimeStamp, D.Amount, D.Source_PU_Id, D.Reason_Level1, D.Reason_Level2,D.Reason_Level3,D.Reason_Level4,WET_Id,WEMT_Id  
      From Waste_Event_Details D WITH (INDEX(WEvent_Details_IDX_PUIdTime))
      where D.PU_Id = @PU_Id and 
            D.TimeStamp > @STime and 
            D.TimeStamp <= @ETime   
  End
Drop Table #Prod_Starts
-- Calculate Total Downtime
Select @TotalWaste = (Select Sum(Amount) From #TopNDR) 
--Go And Get Total Production For Time Period
Select @TotalOperating = 0
--Select @TotalOperating = null
SELECT @TotalOperating = (DATEDIFF(ss, @STime, @ETime) / 60.0) - @TotalOperating
--Delete For Additional Selection Criteria
If @SelectSource Is Not Null
  Delete From #TopNDR Where SourcePU Is Null Or SourcePU <> @SelectSource
If @SelectR1 Is Not Null
  Delete From #TopNDR Where R1_Id Is Null Or R1_Id <> @SelectR1  
If @SelectR2 Is Not Null
  Delete From #TopNDR Where R2_Id Is Null Or R2_Id <> @SelectR2
If @SelectR3 Is Not Null
  Delete From #TopNDR Where R3_Id Is Null Or R3_Id <> @SelectR3
If @SelectR4 Is Not Null
  Delete From #TopNDR Where R4_Id Is Null Or R4_Id <> @SelectR4
update #TopNDR 
  set Reason_Name = 
  Case @ReasonLevel
     When 0 Then PU.PU_Desc
     When 1 Then R1.Event_Reason_Name
     When 2 Then R2.Event_Reason_Name
     When 3 Then R3.Event_Reason_Name
     When 4 Then R4.Event_Reason_Name
     When 5 Then T.WET_Name
     When 6 Then M.WEMT_Name
  End
  From #TopNDR 
  LEFT OUTER JOIN Prod_Units PU on (#TopNDR.SourcePU = PU.PU_Id)
  LEFT OUTER JOIN Event_Reasons R1 on (#TopNDR.R1_Id = R1.Event_Reason_Id)
  LEFT OUTER JOIN Event_Reasons R2 on (#TopNDR.R2_Id = R2.Event_Reason_Id)
  LEFT OUTER JOIN Event_Reasons R3 on (#TopNDR.R3_Id = R3.Event_Reason_Id)
  LEFT OUTER JOIN Event_Reasons R4 on (#TopNDR.R4_Id = R4.Event_Reason_Id)
  LEFT OUTER JOIN Waste_Event_Type T on (#TopNDR.Type_Id = T.WET_Id)
  LEFT OUTER JOIN Waste_Event_Meas M on (#TopNDR.Meas_Id = M.WEMT_Id)
update #TopNDR 
  set Reason_Name = @Unspecified  Where Reason_Name Is Null
-- Populate Temp Table With Reason Ordered By Top 20
insert into #MyReport (ReasonName,
                       NumberOfOccurances,
                       TotalReasonUnits,
                       AvgReasonUnits,
                       TotalWasteUnits,
                       TotalOperatingUnits)
    select Reason_Name, count(Amount), Total_Amount = sum(Amount),  (sum(Amount) / count(Amount)), @TotalWaste, @TotalOperating
      from #TopNDR
      group by Reason_Name
      order by Total_Amount DESC
Select * From #MyReport
drop table #TopNDR
drop table #MyReport
--DELETE FROM User_Connections Where SPID = @@SPID and User_Id = @UserId and Language_Id = @LangId
