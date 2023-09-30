Create Procedure dbo.[spXLA_WasteDetail_NPT_Bak_177]
@STime datetime,
@ETime datetime,
@PU_Id int,
@SelectSource int,
@SelectR1 int,
@SelectR2 int,
@SelectR3 int,
@SelectR4 int,
@ProdId int, 
@GroupId int, 
@PropId int, 
@CharId int,
@TOrder tinyint = NULL,
@Username Varchar(50) = Null,
@Langid Int = 0 
 	 , @InTimeZone 	 varchar(200) = null
AS
SELECT @STime = dbo.fnServer_CmnConvertToDBTime(@STime,@InTimeZone)
SELECT @ETime = dbo.fnServer_CmnConvertToDBTime(@ETime,@InTimeZone)
declare @QueryType tinyint
declare @MasterUnit int
DECLARE @Unspecified varchar(50)
Select @MasterUnit = @PU_Id
--
--DECLARE @UserId 	 Int
--SELECT @UserId = User_Id
--FROM users
--WHERE Username = @Username
--
--EXEC dbo.spXLA_RegisterConnection @UserId,@Langid
--
--SELECT @Unspecified = dbo.fnDBTranslate(@Langid, 38333, 'Unspecified')
create table #prod_starts (pu_id int, prod_id int, start_time datetime, end_time datetime NULL)
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
 	  	   or (start_time <= @STime and (end_time > @ETime or end_time is null))
 	  	   	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
                )
  end
else if @QueryType = 1
  begin
        insert into #prod_starts
          select ps.pu_id, ps.prod_id, ps.start_time, ps.end_time
           from production_starts ps
          where pu_id = @MasterUnit 
 	     and prod_id = @prodid 
 	     and (    (start_time between @STime and @ETime) 
 	  	   or (end_time between @STime and @ETime) 
 	  	   or (start_time <= @STime and (end_time > @ETime or end_time is null))
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
 	     and (    (start_time between @STime and @ETime) 
 	  	   or (end_time between @STime and @ETime) 
 	  	   or (start_time <= @STime and (end_time > @ETime or end_time is null))
 	   	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
                ) 
    drop table #products
  end
-- Get All WED Records In Field I Care About
create table #TopNDR (
  Detail_Id int,
  Start_Time DateTime,
  TimeStamp datetime,
  Amount real NULL,
  Reason_Name varchar(100) NULL,
  SourcePU int NULL,
  R1_Id int NULL,
  R2_Id int NULL,
  R3_Id int NULL,
  R4_Id int NULL,
  Type_Id int NULL,
  Meas_Id int NULL, 
  Prod_Id int NULL,
  First_Comment_Id int NULL,
  Last_Comment_Id int NULL,
  EventBased tinyint NULL,
  EventNumber varchar(50) NULL,
  NPT tinyint 	 NULL  	      
)
-- Get All The Event Based Waste
insert into #TopNDR (Detail_Id, Start_Time,TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, Type_Id, Meas_Id, Prod_Id, EventBased, EventNumber)
  select D.WED_Id, EV.Start_Time, EV.TimeStamp, D.Amount, D.Source_PU_Id, D.Reason_Level1, D.Reason_Level2,D.Reason_Level3,D.Reason_Level4,D.WET_Id,D.WEMT_Id,PS.Prod_Id, 1, EV.Event_Num 
  From Events EV 
  JOIN Waste_Event_Details D on D.Event_Id = EV.Event_Id
  	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
  JOIN #Prod_Starts PS on PS.Start_Time <= EV.TimeStamp AND (PS.End_Time > EV.TimeStamp OR PS.End_Time Is NULL) 
  where EV.PU_Id = @PU_Id and 
        EV.TimeStamp > @STime and 
        EV.TimeStamp <= @ETime   
-- Get All The Time Based Waste
insert into #TopNDR (Detail_Id, TimeStamp, Amount,SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, Type_Id, Meas_Id, Prod_Id, EventBased)
  select D.WED_Id, D.TimeStamp, D.Amount, D.Source_PU_Id, D.Reason_Level1, D.Reason_Level2,D.Reason_Level3,D.Reason_Level4,D.WET_Id,D.WEMT_Id,PS.Prod_Id, 0  
  From Waste_Event_Details D 
  	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
  JOIN #Prod_Starts PS ON PS.Start_Time <= D.TimeStamp AND (PS.End_Time > D.TimeStamp OR PS.End_Time Is NULL) 
  where D.PU_Id = @PU_Id and 
        D.TimeStamp > @STime and 
        D.TimeStamp <= @ETime and 
        D.Event_Id Is Null  
Drop Table #Prod_Starts
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
--Get First And Last Comment
create table #Comments (Detail_Id Int, FirstComment int NULL, LastComment int NULL)
--Get First And Last Comment
Insert Into #Comments
select D.Detail_Id,  min(C.WTC_ID), max(C.WTC_ID)
  From #TopNDR D, Waste_n_Timed_Comments C
  Where C.WTC_Source_Id = D.Detail_Id and C.WTC_Type = 3
  Group By D.Detail_Id   
Update #TopNDR 
  Set First_Comment_Id = FirstComment, Last_Comment_Id = (Case When FirstComment <> LastComment Then LastComment Else Null End) 
  From #TopNDR D, #Comments C 
  Where D.Detail_Id = C.Detail_Id 
-------------------------------------------------------------------
-----------------------------------------------------------------------------------
/*
 	  	 Non Productive Time
 	  	 
*/
------------------------------------------------------------------------------------
DECLARE @Periods_NPT TABLE ( PeriodId int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,StartTime Datetime, EndTime Datetime,NPDuration int)
      INSERT INTO @Periods_NPT ( Starttime,Endtime)
      SELECT      
                  StartTime               = CASE      WHEN np.Start_Time < @STime THEN @STime
                                                ELSE np.Start_Time
                                                END,
                  EndTime           = CASE      WHEN np.End_Time > @ETime THEN @ETime
                                                ELSE np.End_Time
                                                END
      FROM dbo.NonProductive_Detail np WITH (NOLOCK)
            JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON      ercd.Event_Reason_Tree_Data_Id = np.Event_Reason_Tree_Data_Id
                                                                                                      AND ercd.ERC_Id = (SELECT Non_Productive_Category FROM prod_units where PU_id =@PU_Id)
      WHERE PU_Id = @PU_id
                  AND np.Start_Time < @ETime
                  AND np.End_Time > @STime
-------NPT OF Downtime-------
-- Case 1 :  Downtime    St---------------------End
-- 	  	  	  NPT   St--------------End
UPDATE #TopNDR SET Start_Time = n.Endtime,
 	  	  	  	  	 NPT = 1
FROM #TopNDR  JOIN @Periods_NPT n ON (Start_Time > n.StartTime AND TimeStamp > n.EndTime AND Start_Time < n.EndTime)
-- Case 2 :  Downtime    St---------------------End
-- 	  	  	  NPT 	  	  	  	  	 St--------------End
UPDATE #TopNDR SET TimeStamp = n.Starttime,
 	  	  	  	    NPT = 1
FROM 	 #TopNDR 	  	    
JOIN @Periods_NPT n ON (Start_Time < n.StartTime AND TimeStamp < n.Endtime AND TimeStamp > n.StartTime)
 	  	 
-- Case 3 :  Downtime   St-----------------------End
-- 	  	  	  NPT   St-------------------------------End
UPDATE #TopNDR SET Start_Time = TimeStamp,
 	  	  	  	  	 NPT = 1
FROM 	 #TopNDR  	  	    
JOIN @Periods_NPT n ON( (Start_Time BETWEEN n.StartTime AND n.EndTime) AND (TimeStamp BETWEEN n.StartTime AND n.EndTime))
--Update #TopNDR Set Duration =DateDiff(ss,Start_Time,TimeStamp)/60.0
-- Case 4 :  Downtime   St-----------------------End
-- 	  	  	  NPT 	  	    St-----------------End
UPDATE #TopNDR  SET NPT = 1
FROM #TopNDR  JOIN @Periods_NPT n ON( (n.StartTime BETWEEN Start_Time AND TimeStamp) AND (n.Endtime BETWEEN Start_Time AND TimeStamp))
-- --------------------------------------------------
Drop Table #Comments
--Return Data And Join Results
If @TOrder = 1 
  Select [TimeStamp] = dbo.fnServer_CmnConvertFromDbTime(TimeStamp,@InTimeZone), Amount,
  Measurement = Case When #TopNDR.Meas_Id Is Null Then @Unspecified  Else M.WEMT_Name End,
  Type = Case When #TopNDR.Type_Id Is Null Then @Unspecified  Else T.WET_Name End,
  Event_Number = Case 
                   When #TopNDR.EventBased = 0 Then dbo.fnDBTranslate(N'0', 31333, 'Not Applicable')
                   When #TopNDR.EventBased = 1 and #TopNDR.EventNumber Is Null Then @Unspecified   
                   Else #TopNDR.EventNumber 
                 End,
  Location = Case When #TopNDR.SourcePU Is Null Then @Unspecified  Else PU.PU_Desc End,
  Reason1 =  Case When #TopNDR.R1_Id Is Null Then @Unspecified  Else R1.Event_Reason_Name End,  
  Reason2 =  Case When #TopNDR.R2_Id Is Null Then @Unspecified  Else R2.Event_Reason_Name End,  
  Reason3 =  Case When #TopNDR.R3_Id Is Null Then @Unspecified  Else R3.Event_Reason_Name End,  
  Reason4 =  Case When #TopNDR.R4_Id Is Null Then @Unspecified  Else R4.Event_Reason_Name End,
  Products.Prod_Code, First_Comment_Id, Last_Comment_Id  
    From #TopNDR
    JOIN Products on Products.Prod_Id = #TopNDR.Prod_Id
    LEFT OUTER JOIN Prod_Units PU on (#TopNDR.SourcePU = PU.PU_Id)
    LEFT OUTER JOIN Event_Reasons R1 on (#TopNDR.R1_Id = R1.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons R2 on (#TopNDR.R2_Id = R2.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons R3 on (#TopNDR.R3_Id = R3.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons R4 on (#TopNDR.R4_Id = R4.Event_Reason_Id)
    LEFT OUTER JOIN Waste_Event_Type T on (#TopNDR.Type_Id = T.WET_Id)
    LEFT OUTER JOIN Waste_Event_Meas M on (#TopNDR.Meas_Id = M.WEMT_Id)
    WHERE NPT IS NULL
    Order By TimeStamp ASC
Else
  Select [TimeStamp] = dbo.fnServer_CmnConvertFromDbTime(TimeStamp,@InTimeZone), Amount,
  Measurement = Case When #TopNDR.Meas_Id Is Null Then @Unspecified  Else M.WEMT_Name End,
  Type = Case When #TopNDR.Type_Id Is Null Then @Unspecified  Else T.WET_Name End,
  Location = Case When #TopNDR.SourcePU Is Null Then @Unspecified  Else PU.PU_Desc End,
  Reason1 =  Case When #TopNDR.R1_Id Is Null Then @Unspecified  Else R1.Event_Reason_Name End,  
  Reason2 =  Case When #TopNDR.R2_Id Is Null Then @Unspecified  Else R2.Event_Reason_Name End,  
  Reason3 =  Case When #TopNDR.R3_Id Is Null Then @Unspecified  Else R3.Event_Reason_Name End,  
  Reason4 =  Case When #TopNDR.R4_Id Is Null Then @Unspecified  Else R4.Event_Reason_Name End,
  Products.Prod_Code, First_Comment_Id, Last_Comment_Id  
    From #TopNDR
    JOIN Products on Products.Prod_Id = #TopNDR.Prod_Id
    LEFT OUTER JOIN Prod_Units PU on (#TopNDR.SourcePU = PU.PU_Id)
    LEFT OUTER JOIN Event_Reasons R1 on (#TopNDR.R1_Id = R1.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons R2 on (#TopNDR.R2_Id = R2.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons R3 on (#TopNDR.R3_Id = R3.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons R4 on (#TopNDR.R4_Id = R4.Event_Reason_Id)
    LEFT OUTER JOIN Waste_Event_Type T on (#TopNDR.Type_Id = T.WET_Id)
    LEFT OUTER JOIN Waste_Event_Meas M on (#TopNDR.Meas_Id = M.WEMT_Id)
    WHERE NPT IS NULL 	  	  	 
    Order By TimeStamp DESC
drop table #TopNDR
--
--DELETE FROM User_Connections Where SPID = @@SPID and User_Id = @UserId and Language_Id = @LangId
