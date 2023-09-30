 /*  
Stored Procedure:   spLocal_Parts_Import_Intr_Data  
Author:             John Yannone  
Date Created:       November 2003  
  
Description:  
This procedure will be called by the PARTS Intr Interface program. This Interface program sits on an "interface box" and is  
launched via the windows task scheduler.  The procedure will gather the intr data required for PARTS based on  
the 'start date' and 'end date' for the production line indicated.  The procedure is intended  
to return one days data, therefore the start date should represent midnight for the desired day and end date  
should represent midnight for the next day.  This procedure will return TWO recordsets, one of un-summarized production  
data by brand run, and the other is the Rejects associated with each production run by brand for a 24 hr period.  
  
CODE UPDATES FROM FGO:  
1/16/04  - modified the code to update the temp tables gcascode with the INput GCAS not   
    the running GCAS  
2/5/04  - modified the reject code not looking at the UWS unit correctly not looking at   
    variables correctly not looking at the Rolls unit  
2/9/04  - Updated the code to get the ouput_gcas and renamed gcascode to input_gcas  
2/14/04  - Corrected to handle only one summary record for each input gcas  
2/27/2004 -  Added a line of code to restrict endtime on the UWS query. See initials and date below.  
3/11/2004 -  Added the ability to get PROLL_Consumed and PROLLS_Produced  
9/28/04 - Changed the lookup in the reject weight From @Rolls_PU_Desc to @pl_desc  for weight   
   differences between combiners and rewinders and lotioners  
   added a variable for @pl_desc to handle the changes in @Resource_ID  
***END FGO  
  
JDY 4/11/2006. Removed the "equals" sign from the nested query when looking up  
the line status phrase. (and start_datetime <= result_on   'is now just'     and start_datetime < result_on)  
  
JDY 10/25/2006.  
'Added standard debug logic.  
'Placed BEGIN and END commands at the start and end of the sp.  
'Converted all tables into table variables.  
'Added [dbo]. prefix to all table names.  
'Added (with nolock) condition to all query statements.  
'Cleaned out all the garbage in preparation for the next wave   
 of changes where I will be breaking out PARTS qualifying   
 downtime events greater than 2 hours and has a PARTS non run reason.  
'Also will be bringing in line status user and comments (re-apply from  
 the pmkg and conv sp's) and send that to PARTS as well.  
  
JDY 10/25,26/2006 Rev2.00  
Added in the code to return the line status user and comments for the event record.  
Plugged in the downtime code (re-applied from conv and pmkg) which will now break out  
events as non run as defined by a PARTS non-run definition, that being an downtime   
event that is greater than two hours and has a PARTS cause code appended to it.  
  
2009-02-24 Jeff Jaeger Rev2.01  
-- updated the method for pulling NoRunID so as to eliminate the use of Local_Timed_Event_Categories.  
  
*/  
  
--/*  
CREATE       PROCEDURE spLocal_Parts_Import_Intr_Data  
--UPPER CASE denotes Parameters IN:  
@START_DATE      datetime,  
@END_DATE        datetime,  
@RESOURCE_ID     varchar(7)  
AS  
--*/  
  
SET NOCOUNT ON  
  
/*  
--This section used for manual running during debugging representing param's in.  
  
declare   
@START_DATE    datetime,  
@END_DATE      datetime,  
@RESOURCE_ID   varchar(7)  
  
select  
@START_DATE   = '2009-02-16 07:30:00',  
@END_DATE     = '2009-02-17 07:30:00',  
@RESOURCE_ID  = 'TT FFFW'  
  
*/  
  
--@strSQL       varchar(2000),  
declare  
@plid         integer,    --Production Line ID.  
@pc_start     datetime,   --Production Change start date  
@pc_end       datetime,   --Production Change end date  
  
  
@record_id        integer,  
@gcas_code      varchar(9),  
@line_status     varchar(25),  
@RecCounter1     integer,  
@Rolls_PU_Desc    varchar(50),  
@PROLLS_Consumed  integer,    
@PROLLS_Produced  integer,    
@pl_desc   varchar(50),           
@Debug            bit,  
@dt_total           float(3),  
@dt_recID      integer,  
@DownTimeValue      float,  
@RecordID           integer,  
@Downtime           float,  
@ScheduleID         integer,  
@ERC_Desc           varchar(60),  
@TEDetId            integer,  
@NonRunId           integer,  
@ProfEventStart     DateTime,  
@ProfEventEnd       DateTime,  
@fgoid int  
  
--This temp tables holds detailed data from the respective Proficy variables for the intr event.  
Declare @IntrLineInfo Table(  
result_on        datetime,  
total_time       integer,  
pc_start         datetime,       
pc_end           datetime,       
Input_gcas       varchar(9),   
output_gcas      varchar(9),   
Line_status      varchar(25),  
status_sched_id  integer,    
input_good_tons  float(3),  
output_good_tons float(3),  
line_speed       integer)  
  
/* This table contains the same values as the above table, the only difference  
   is we get the line status for each event.*/  
Declare @IntrLineInfoSetStatus table  
(Start_DateTime   datetime,     --Used to identify the Start and End times of the LineStatus.  
 End_DateTime     datetime,     --Used to identify the Start and End times of the LineStatus.  
 pc_start         datetime,     --Used to identify the product change start time.  
 pc_end           datetime,     --Used to identify the product change end time.  
 Input_gcas       varchar(9),  
 output_gcas      varchar(9),  
 Line_Status      varchar(25),   --ie, RUN, GE...                                   
 result_on        datetime,  
 total_time       integer,  
 input_good_tons  float(3),  
 output_good_tons float(3),  
 line_speed       integer,  
 status_sched_id  int)  
  
--This table will hold the summary of the detailed data of the conv events for a given day.  
--Used to group all the data in the @IntrLineInfo table.  
Declare @IntrLineInfoSum1 Table(  
record_id        integer,  
ProfEventStart   datetime,  
ProfEventEnd     datetime,  
LineStatus_Start datetime,  
LineStatus_End   datetime,               
pc_start         datetime,  
pc_end           datetime,  
Input_gcas       varchar(9),   
output_gcas      varchar(9),  
total_time       integer,               
down_time        float,  
DT_ERC_Desc   varchar(65),  
Line_status      varchar(25),  
input_good_tons  float(3),  
output_good_tons float(3),  
line_speed       integer,  
PROLLS_Produced  integer,   
PROLLS_Consumed  integer,  
status_sched_id int,  
status_user_id  int,  
status_username varchar(50),  
status_comment  varchar(510))  
  
Declare @IntrLineInfoSum2 table  
(record_id       integer,  
Input_gcas       varchar(9),  
output_gcas      varchar(9),  
total_time       integer,                   
down_time        float (3),  
DT_ERC_Desc      varchar(65),      
Line_status      varchar(25),  
input_good_tons  float(3),  
output_good_tons float(3),  
line_speed       integer,  
PROLLS_Produced  integer,   
PROLLS_Consumed  integer,  
status_username  varchar(50),  
status_comment   varchar(510))  
  
--Used to gather Downtime info.  
Declare @PUIDList table  
(puid integer primary key,  
 pudesc varchar(50))  
  
Declare @LTED table  
(TEDetID  int primary key,  
puid   int,  
StartTime  datetime,  
EndTime   datetime,  
Downtime  float(3),  
NonRunID  int,  
ScheduleID  int,  
Reason_Level1  int,  
Reason_Level2  int,  
TEFault_ID  int,  
ERTD_ID   int  
)  
  
/*  
Declare @TECategories table  
(TEDet_Id int,  
 ERC_Id  int  
primary key (TEDet_ID, ERC_ID))  
*/  
  
Declare @DownTimeInfo table(  
record_id   int,  
TEDetId     int,  
PUId        int,  
StartTime   datetime,  
EndTime         datetime,  
DownTime       float,  
NonRunId       int,  
ScheduleID     int,  
Reason_Level1  int,  
Reason_Level2  int,  
TEFaultId  integer)  
  
  
--This table is used to summarize downtime data  
Declare @DT_DETAILS Table(  
duration   float)  
  
--This table  used to store reject info.  
Declare  @REJ_ROLLINFO Table(  
tstamp        datetime,  
status        varchar(25),  
prid          varchar(22),  
gcas          varchar(8),  
reject_wt     float(3),              --need to check on precision of stored value we retrieve.  
cause         varchar(25),  
enum          varchar(25),  
record_id     integer)  
  
  
BEGIN  
  
--Debug On = 1, Debug Off = 0.  
Select @Debug = 0  
    If @Debug = 1   
      begin  
        SELECT @START_DATE = '03-sep-06'  
 SELECT @END_DATE = '04-sep-06'  
 SELECT @RESOURCE_ID = 'PP FFCW'  
      end  
  
--Get the production line id.  
SELECT @plid = pl_id  
FROM [dbo].PROD_LINES with(nolock)  
WHERE pl_desc = @RESOURCE_ID  
  
SELECT @PL_DESC = @RESOURCE_ID  
  
--Strip off once and use throughout.  
SELECT @RESOURCE_ID = substring(@RESOURCE_ID,4,4)  
select @fgoid = pu_id from dbo.prod_units with(nolock)where pu_desc = @RESOURCE_ID + ' UWS Production'  
--Insert all the product changes of the Line.   
Insert Into @IntrLineInfo(pc_start, pc_end)  
Select ps.start_time,  
       ps.end_time  
From [dbo].PRODUCTION_STARTS ps with(nolock),       --Brand change table  
     [dbo].PRODUCTS pro with(nolock),  
     [dbo].PROD_UNITS pu with(nolock)  
Where ps.prod_id = pro.prod_id  
AND   ps.pu_id = pu.pu_id  
AND   pu.pu_desc like @RESOURCE_ID + ' UWS Production'  
AND   pu.pl_id = @plid  
AND  ((@start_date <= ps.end_time OR ps.end_time is null)  
AND   ps.start_time <= @end_date)   
  
/*Update the @IntrLineInfo table and indicate the start and end times for the product  
  run for each variable.  This will set the start time equal to midnight if the  
  production start time is from a previous day.  This will set the end time to  
  midnight if the end time is null or from a later day. */  
UPDATE @IntrLineInfo  
SET pc_start =  
    CASE  
           -- When the start time of the brand change is less than the midnite of the current day,  
           -- then set the startime to midnite.  
           when pc_start < @START_DATE then @START_DATE  
           else pc_start  
           end,  
    pc_end =  
    CASE  
           --If the end time is null or end time is the next day that means we are in still in the middle  
           --of a brand run so therefore set end time to Midnite.  
           when pc_end is null then @END_DATE         --(Midnite)  
           when pc_end > @END_DATE then @END_DATE  
           else pc_end  
           end  
  
-- Update the end of the product change to match the record in tests for 215.5   
Update @IntrLineInfo  
Set pc_end = dateadd(second,-1,pc_end)  
Where pc_end <> @end_date  
  
-- Update the speed field.   
Update @IntrLineInfo  
Set line_speed = cast(result as real)  
From [dbo].TESTS t with(nolock)  
     left join [dbo].variables v with(nolock) on (v.var_id = t.var_id)  
     left join [dbo].prod_units pu with(nolock) on (pu.pu_id = v.pu_id)  
Where v.pu_id = pu.pu_id  
And pu.pl_id = @plid  
And v.var_desc = 'Line Speed Day Avg'                 --Name of the variable  
And pu.pu_desc like @RESOURCE_ID + ' TO Production'   --Name of unit  
And t.result_on = pc_end  
  
-- Update the Input Tons field   
Update @IntrLineInfo  
Set input_good_tons = cast(result as real)  
From [dbo].TESTS t with(nolock)  
     left join [dbo].variables v with(nolock) on (v.var_id = t.var_id)  
     left join [dbo].prod_units pu with(nolock) on (pu.pu_id = v.pu_id)  
Where v.pu_id = pu.pu_id  
And pu.pl_id = @plid  
And v.var_desc = 'Tons Input Day Sum'      
And pu.pu_desc like @RESOURCE_ID + ' TO Production'   
And t.result_on = pc_end  
  
-- Update the Good Tons field   
Update @IntrLineInfo  
Set output_good_tons = cast(result as real)  
From [dbo].TESTS t with(nolock)  
     left join [dbo].variables v with(nolock) on (v.var_id = t.var_id)  
     left join [dbo].prod_units pu with(nolock) on (pu.pu_id = v.pu_id)  
Where v.pu_id = pu.pu_id  
And pu.pl_id = @plid  
And v.var_desc = 'Tons Good Day Sum'      
And pu.pu_desc like @RESOURCE_ID + ' TO Production'   
And t.result_on = pc_end  
  
--Get the INPUT GCAS  
Update @IntrLineInfo  
Set input_gcas = result  
From @IntrLineInfo,  
     [dbo].TESTS t with(nolock),  
     [dbo].variables v with(nolock),  
     [dbo].prod_units pu with(nolock)  
Where pc_Start <= t.result_on  
And pc_end >= t.result_on  
And v.var_id = t.var_id  
And v.pu_id = pu.pu_id  
And pu.pl_id = @plid  
And v.var_desc = 'Input GCAS'     
And pu.pu_desc like @RESOURCE_ID + ' TO Production'  
  
--Determine the line status and Grab the status_sched_id while we are at it.  
--JY 4/11/06 - remove the = sign from the nested query lookup on this query for start_datetime.  
Insert @IntrLineInfoSetStatus  
Select   
       case  
           when sta.Start_DateTime < @START_DATE then @START_DATE  
           else sta.Start_DateTime  
           end,  
       case  
           when sta.End_DateTime  > @END_DATE then @END_DATE  
           else sta.End_DateTime  
        end,  
       pc_start, pc_end, Input_gcas, output_gcas, phr.Phrase_Value, result_on, total_time,    
       input_good_tons, output_good_tons, line_speed, sta.status_schedule_id  
From   [dbo].LOCAL_PG_LINE_STATUS sta with(nolock),   
       [dbo].PROD_UNITS pu with(nolock),   
       [dbo].PHRASE phr with(nolock),   
       @IntrLineInfo i  
Where    
sta.unit_id = @fgoid  
and sta.unit_id = pu.pu_id  
And    sta.line_status_id = phr.phrase_id  
And    pu.pl_id = @plid  
And    sta.update_status <> 'DELETE'  
And    start_datetime = (select max(l.start_datetime)  
                         from [dbo].LOCAL_PG_LINE_STATUS l with(nolock)  
          left join [dbo].PROD_UNITS p on l.unit_id = p.pu_id  
                         where p.pl_id = @plid                  --p.pu_desc = @PU_Desc1   
                         and l.update_status <> 'DELETE'   
                         and start_datetime < pc_start)  
  
--This INSERT will summarize the @IntrLineInfo table data.  
Insert Into @IntrLineInfoSum1  
Select null,  
        null,  
        null,  
        Start_DateTime,  
        End_DateTime,  
        pc_start,  
        pc_end,  
        Input_gcas,  
        null,                   --output gcas  
        avg(total_time) ttime,           --Converted total actual time from minutes to hours here instead of PARTs side.  
        null,                    --downtime  
        null,                    --DT_ERC_Desc  
        Line_status,  
        sum(input_good_tons),  
        sum(output_good_tons),  
        avg(line_speed) AS speed,  
        null,                    --PROLLS_Produced  
        null,                    --PROLLS_Consumed  
        status_sched_id,  
        null,                    
        null,  
        null  
From @IntrLineInfoSetStatus  
Group By Start_DateTime, End_DateTime, pc_start, pc_end, input_gcas, Line_status, status_sched_id  
  
/*Calculate the Start and End times of the Individual Proficy events  
  based off the different combinations of pc_start & pc_end and LineStatus_Start & LineStatus_End.*/  
Update @IntrLineInfoSum1  
set ProfEventStart =   
   case   
            when datediff(mi,pc_start,pc_end) = 0    
              then pc_start                               
            when (LineStatus_Start = @START_DATE) and (LineStatus_End is null or LineStatus_End = @END_DATE)   
              then pc_start   
            when datediff(mi,pc_start,pc_end) = 1440   
              then LineStatus_Start                                      
            when datediff(mi,pc_start,pc_end) <> 1440 and LineStatus_End between pc_start and pc_end       
              then pc_start   
            when datediff(mi,pc_start,pc_end) <> 1440 and LineStatus_End not between pc_start and pc_end and LineStatus_Start = pc_start  
              then pc_start                   
            when datediff(mi,pc_start,pc_end) <> 1440 and LineStatus_End not between pc_start and pc_end and LineStatus_Start > pc_start  
              then LineStatus_Start   
            when datediff(mi,pc_start,pc_end) <> 1440 and LineStatus_End is null and datediff(mi,LineStatus_Start,pc_end) = 1440                      
              then pc_start   
            when datediff(mi,pc_start,pc_end) <> 1440 and LineStatus_End is null and LineStatus_Start < pc_start                   
              then pc_start   
            when datediff(mi,pc_start,pc_end) <> 1440 and LineStatus_End is null                     
              then LineStatus_Start    
  end,   
 ProfEventEnd =   
   case   
            when datediff(mi,pc_start,pc_end) = 0    
              then pc_end                               
            when (LineStatus_Start = @START_DATE) and (LineStatus_End is null or LineStatus_End = @END_DATE)   
              then  pc_end   
            when datediff(mi,pc_start,pc_end) = 1440   
              then coalesce(LineStatus_End,pc_end)                                       
            when datediff(mi,pc_start,pc_end) <> 1440 and LineStatus_End between pc_start and pc_end       
              then LineStatus_End   
            when datediff(mi,pc_start,pc_end) <> 1440 and LineStatus_End not between pc_start and pc_end and LineStatus_Start = pc_start  
              then pc_end                   
            when datediff(mi,pc_start,pc_end) <> 1440 and LineStatus_End not between pc_start and pc_end and LineStatus_Start > pc_start  
              then pc_end   
            when datediff(mi,pc_start,pc_end) <> 1440 and LineStatus_End is null and datediff(mi,LineStatus_Start,pc_end) = 1440                      
              then pc_end   
            when datediff(mi,pc_start,pc_end) <> 1440 and LineStatus_End is null and LineStatus_Start < pc_start                   
              then pc_end   
            when datediff(mi,pc_start,pc_end) <> 1440 and LineStatus_End is null                     
  
              then pc_end   
  end  
  
--Set total time.  
Update @IntrLineInfoSum1  
Set total_time = datediff(mi,ProfEventStart,ProfEventEnd)  
  
--We count 'Rel Unknown:Qual Unknown' as an INCLUDED event.  
Update @IntrLineInfoSum1  
Set Line_status = 'Rel Inc:Qual Unknown'  
Where Line_status like 'Rel Unk%'  
  
--************Begin assembling Downtime info into the table variable @LTED.*******************  
-- Build @PUIDList which will be used to restrict the data.  
Insert @PUIDList(puid,pudesc)  
Select distinct  
 pu_id,  
 pu_desc  
From prod_units with(nolock)  
Where pl_id = @plid  
And master_unit is null  
and pu_desc like @RESOURCE_ID + ' Reliability'  
Order by pu_id asc  
  
Insert @LTed  
       (TEDetID,  
 puid,  
 StartTime,  
 EndTime,  
        Downtime,  
 Reason_Level1,  
 Reason_Level2,  
 TEFault_ID,  
 ERTD_ID  
 )  
Select  
 t.TEDet_ID,  
 t.pu_id,  
 t.Start_Time,  
 t.End_Time,  
        t.Duration,  
 t.Reason_Level1,  
 t.Reason_Level2,  
 t.TEFault_ID,  
 t.event_reason_tree_data_id    
From @PUIDList p  
Join [dbo].timed_event_details t with(nolock)on p.puid = t.pu_id   
And  t.start_time < @END_DATE  
And (t.end_time > @START_DATE or t.end_time is null)  
Order by t.TEDet_ID   
  
Update @LTed  
Set Downtime = datediff(ss,starttime,endtime)  
From @LTed   
Where endtime is not null  
  
/* Retrieve the Schedule and NonRun Reasons for the Timed_Event_Details  
   row FROM the Local_Timed_Event_Categories table using the TEDet_Id. */  
  
/*  
Insert Into @TECategories(TEDet_Id,  
                        ERC_Id)  
Select distinct   
 t.TEDet_Id,  
 t.ERC_Id  
From @LTed l   
Join [dbo].Local_Timed_Event_Categories t with(nolock)   
ON l.TEDetId = t.TEDet_Id  
option(keep plan)  
  
Update @LTed   
Set NonRunId = tc.ERC_Id  
From @LTed l   
Join @TECategories tc ON l.TEDetId = tc.TEDet_Id  
Join [dbo].Event_Reason_Catagories e with(nolock) ON tc.ERC_Id = e.ERC_Id  
And   e.ERC_Desc LIKE 'PARTS Non-Run%'  
*/  
  
UPDATE td SET  
 NonRunId = erc.ERC_Id  
FROM @LTed td   
JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
ON TD.ERTD_ID = ercd.event_reason_tree_data_id   
JOIN dbo.event_reason_catagories erc WITH (NOLOCK)   
ON ercd.erc_id = erc.erc_id   
where erc.ERC_Desc LIKE 'PARTS Non-Run%'  
  
  
--*****End Downtime gathering into @LTED**********************************  
  
SET  @RecCounter1 = 0  
  
Declare event_change_cur cursor for  
Select  record_id, ProfEventStart, ProfEventEnd  
From   @IntrLineInfoSum1    
  
OPEN event_change_cur  
FETCH next FROM event_change_cur  
INTO @RecordID, @ProfEventStart, @ProfEventEnd   
  
WHILE (@@FETCH_STATUS <> -1)  
  
   begin  
 Select @RecCounter1 = @RecCounter1 + 1  
           
 Update @IntrLineInfoSum1    
 Set  record_id = @RecCounter1  
 Where Current Of event_change_cur  
                 
        --Load the DT Table with the data from each Proficy Event.  
        Insert Into @DownTimeInfo  
 Select @RecCounter1, TEDetId, t.PUId, StartTime, EndTime,   
        DownTime =  
          CASE  
           when (starttime < @ProfEventStart and endtime <= @ProfEventEnd)  
             then datediff(s,@ProfEventStart,endtime)/60.0  
   
           when (starttime > @ProfEventStart and endtime <= @ProfEventEnd)  
             then datediff(s,starttime, endtime)/60.0  
  
   
           when (starttime > @ProfEventStart and (endtime > @ProfEventEnd or endtime is null))  
             then datediff(s,starttime, @ProfEventEnd)/60.0  
   
           when (starttime < @ProfEventStart and endtime > @ProfEventEnd)  
             then datediff(s,@ProfEventStart,@ProfEventEnd)/60.0  
          END,  
                NonRunId, ScheduleID, Reason_Level1, Reason_Level2, TEFault_Id  
 From @LTED t,   
             [dbo].prod_units p with(nolock)   
  Where t.puid = p.pu_id    
  And   p.pu_desc like @RESOURCE_ID + ' Reliability%'                            
  And   p.pl_id = @plid  
  AND  ((starttime >= @ProfEventStart  
         AND   starttime < @ProfEventEnd)  
         OR   (endtime <= @ProfEventEnd and endtime > @ProfEventStart)  
         OR   (starttime < @ProfEventStart and endtime > @ProfEventStart))  
          
     FETCH next FROM event_change_cur  
 INTO @RecordID, @ProfEventStart, @ProfEventEnd  
   end   
  
/* For each Proficy Event time span look to see if any of the downtime events   
   qualifys as a PARTS NON-RUN definition, that being a DT event > 2 hrs  
   AND a specific Scheduled Reason from the Event_Reason_Catagories table.   
   If the DT event meets this criteria then need to establish a separate   
   non-run event record in PARTS.*/  
  
Declare PartsDownTimeEvents_cur Cursor for   
Select record_id, TEDetId, DownTime, ScheduleID, NonRunId, ERC_Desc  
From @DownTimeInfo d, [dbo].Event_Reason_Catagories e with(nolock)  
Where DownTime > 120.0  
And NonRunId = ERC_Id  
And ERC_Desc Like 'PARTS Non-Run%'  
  
OPEN PartsDownTimeEvents_cur  
FETCH next FROM PartsDownTimeEvents_cur  
INTO @RecordID, @TEDetId, @Downtime, @ScheduleID, @NonRunId, @ERC_Desc  
  
WHILE (@@FETCH_STATUS <> -1)  
   begin  
           --Create a unique "Thousand Series" record id identifier for the DT record.   
          Select @dt_recID = (@RecordID + 1000)  
            
           /*Create the Non Run Record for PARTS. */  
           INSERT INTO @IntrLineInfoSum1  
           Select @dt_recID, ProfEventStart, ProfEventEnd, LineStatus_Start, LineStatus_End,  
                  pc_start, pc_end, input_gcas, output_gcas, 0/*total_time*/, @Downtime, @ERC_Desc, Line_status,  
                  0/*input_good_tons*/, 0/*output_good_tons*/, 0/*line_speed*/, 0/*PROLLS_Produced*/,  0/*PROLLS_Produced*/,  
                  status_sched_id, null, null, null  
           from @IntrLineInfoSum1  
           Where record_id = @RecordID  
   
           --Set the DT record with a DT rec id for distinction when rolling up the data.  
           Update @DownTimeInfo  
           Set record_id = @dt_recID  
           Where TEDetId = @TEDetId  
  
           /* Since we had to create a separate event record for the non-run event then  
              we need to subtract that downtime from the actual time of the run event. */  
           Update @IntrLineInfoSum1  
           Set total_time = (total_time - @Downtime)  
           Where record_id = @RecordID             
  
      FETCH next FROM PartsDownTimeEvents_cur  
      INTO @RecordID, @TEDetId, @Downtime, @ScheduleID, @NonRunId, @ERC_Desc  
          
   end  
CLOSE PartsDownTimeEvents_cur  
deallocate PartsDownTimeEvents_cur  
  
DECLARE RunEventsDownTime_cur cursor for   
SELECT record_id   
FROM @IntrLineInfoSum1  
WHERE record_id < 1000    --This restriction ensures we do not resummarize downtime records we have already summarized.  
ORDER BY record_id asc  
  
OPEN RunEventsDownTime_cur  
FETCH next FROM RunEventsDownTime_cur  
INTO @RecordID  
  
 WHILE (@@FETCH_STATUS <> -1)  
   begin  
      Update @IntrLineInfoSum1  
      Set down_time = (Select isnull(sum(downtime),0)  
                From @DownTimeInfo   
                       Where record_id = @RecordID)  
             Where record_id = @RecordID  
        
      Fetch next From RunEventsDownTime_cur  
      Into @RecordID   
  end  
  
CLOSE RunEventsDownTime_cur  
deallocate RunEventsDownTime_cur  
  
--Set status_user_id.                       
Update @IntrLineInfoSum1  
Set  status_user_id = lsc.User_Id  
From [dbo].Local_PG_Line_Status_Comments lsc with(nolock), @IntrLineInfoSum1  c1  
Where c1.status_sched_id = lsc.status_schedule_id  
  
  
--Fetch the associated comment text and user name based of status schedule id.  
Update @IntrLineInfoSum1  
Set  status_comment = lsc.comment_text,  
     status_username = u.username  
from [dbo].Local_PG_Line_Status_Comments lsc with(nolock), @IntrLineInfoSum1 c1,  
     [dbo].Users u with(nolock)  
Where lsc.Status_Schedule_Id = c1.status_sched_id  
and   u.User_Id = c1.status_user_id  
and lsc.entered_on = (select max(entered_on)  
                      from  [dbo].Local_PG_Line_Status_Comments lsc with(nolock)  
                      where lsc.Status_Schedule_Id = c1.status_sched_id  
                      and   u.User_Id = c1.status_user_id   
                      and   lsc.start_datetime is not null)  
  
--Finally, combine together any like PARTS NON-RUN events. Do we really want to roll up non run events with like ERC Desc's  
--into a single downtime PARTS event? Or is it better to view them as separate events in PARTS? The answer is they have to be  
--rolled together here because on the PARTS side you will run into a Unique Key Violation in the CONV_EVENT table if you don't.  
--I also believe that we can include status_username and status_comment in the GROUP BY clause in this query because the   
--username and comment associated with the run record has already been established, hence the non run record will "inherit"  
--the line status components from the run record from which it came from and should always have the same user and comment.  
Insert Into @IntrLineInfoSum2  
select null, Input_gcas, null/*output_gcas*/, sum(round(total_time,0)), sum(Down_Time), DT_ERC_Desc, Line_status,  
       sum(input_good_tons), sum(output_good_tons), avg(line_speed), null/*PROLLS_Produced*/, null/*PROLLS_Consumed*/,  
       status_username, status_comment  
from @IntrLineInfoSum1   
where record_id > 1000  
group by Input_gcas, Line_status, DT_ERC_Desc , status_username, status_comment  
  
--Reset the record_id because we could not use it in the group by statement above.  
Update c2  
set c2.record_id = c1.record_id  
from @IntrLineInfoSum1 c1, @IntrLineInfoSum2 c2  
where c1.DT_ERC_Desc = c2.DT_ERC_Desc  
  
--Add in the summation of all "Like" run records. e.g. run records with the same event unique key.  
Insert Into @IntrLineInfoSum2  
Select null,   
       Input_gcas,   
       null,   
       sum(isnull(total_time,0)) total_time,  
       sum(isnull(down_time,0)) down_time,  
       DT_ERC_Desc,   
       Line_status,   
       sum(isnull(input_good_tons,0)) input_good_tons,   
       sum(isnull(output_good_tons,0)) output_good_tons,   
       avg(line_speed) line_speed,  
       null,   
       null,  
       status_username,   
       status_comment  
From @IntrLineInfoSum1 c1  
Where c1.record_id < 1000  
group by input_gcas, dt_erc_desc, line_status, status_username, status_comment  
  
--Reset the run records record id.  
Update c2  
set c2.record_id = c1.record_id  
from @IntrLineInfoSum1 c1, @IntrLineInfoSum2 c2  
where c1.input_gcas is not null  
  
--Get the OUTPUT GCAS  
Update @IntrLineInfoSum2  
Set output_gcas = result  
From @IntrLineInfoSum1,  
     [dbo].TESTS t with(nolock),  
     [dbo].variables v with(nolock),  
     [dbo].prod_units pu with(nolock)  
Where pc_Start <= t.result_on  
And pc_end >= t.result_on  
And v.var_id = t.var_id  
And v.pu_id = pu.pu_id  
And pu.pl_id = @plid  
And v.var_desc = 'ROll GCAS'     
And pu.pu_desc like @RESOURCE_ID + ' Rolls'   
  
--*****************REJECT DATA GATHER*********************************************************************  
--Initialize counter.  
Select  @RecCounter1 = 0  
  
--Open a cursor to loop through the @IntrLineInfoSum1 table and append a record id.  
Declare prod_change_cur  Cursor For  
Select pc_start, pc_end  
From @IntrLineInfoSum1  
  
--JDY declare cursor on the fly for reject data.  
Declare prod_change_summary_cur Cursor For  
Select pc_start, pc_end, record_id, input_gcas, Line_status  
From @IntrLineInfoSum1  
  
--Begin processing rejects  
--This cursor gets product runs for the day, looping through the  
--production summarys.  
Open prod_change_summary_cur  
Fetch Next From prod_change_summary_cur  
Into @pc_start, @pc_end, @record_id, @gcas_code, @line_status  
  
WHILE @@FETCH_STATUS = 0  
  
    begin  
  
       --Get all the timestamps and ULID's of the rejects for the uws  
 INSERT INTO @REJ_ROLLINFO(tstamp, enum)  
 (SELECT  timestamp,  
          event_num  
  FROM  [dbo].events e with(nolock),   
               [dbo].prod_units p with(nolock)  
  WHERE e.pu_id = p.pu_id  
  AND   p.pl_id = @plid  
  AND   p.pu_desc like '% UWS Production'  
  AND   event_status = 23                      -- 23 is reject code. Look for reject code for UWS production.  
  AND  (timestamp > @pc_start  
  AND   timestamp <= @pc_end))  
  
 --Stamp the record id onto the reject recordset for that timeframe.  
 UPDATE @REJ_ROLLINFO  
 SET    record_id = @record_id,  
        gcas      = @gcas_code,  
        status    = @line_status  
 WHERE tstamp > @pc_start  
 AND   tstamp <= @pc_end  
  
 -- PRID...look at each timestamp and determine the associated prid.  
 UPDATE @REJ_ROLLINFO  
 SET    prid = result  
 FROM   [dbo].TESTS t with(nolock),  
               [dbo].variables v with(nolock)  
 WHERE  t.var_id = v.var_id  
 AND    v.var_desc = 'PRID'  
 AND    t.result_on = tstamp  
  
        --REJECT WT...come back to check on precision of reject wt from Proficy to PARTs.  
 UPDATE @REJ_ROLLINFO  
 SET    reject_wt = cast(result as real)   --/1000  --conversion to metric tons removed here because it has already been converted when we pull it in.  
 FROM   tests t, variables v  
 WHERE  t.var_id = v.var_id  
 AND    v.var_desc  like '% Reject Weight'  
 AND    t.result_on = tstamp  
          
 --REJECT DESC...Getting the defect cause description.  
 UPDATE  @REJ_ROLLINFO  
 SET     cause = result  
 FROM    [dbo].TESTS t with(nolock),  
         [dbo].variables v with(nolock)  
 WHERE   t.var_id = v.var_id  
 AND     v.var_desc  Like '% Cause'  
 AND     t.result_on = tstamp  
  
        --INPUT GCAS...  
 UPDATE @REJ_ROLLINFO  
 SET    gcas = result  
 FROM   [dbo].TESTS t with(nolock),  
        [dbo].variables v with(nolock),  
        [dbo].events e with(nolock)  
 WHERE  t.var_id = v.var_id  
 AND    v.var_desc = 'Input GCAS'  
 AND    t.result_on = tstamp  
  
 --Get all the timestamps and ULID's of the rejects for the the rolls unit  
 SELECT @Rolls_PU_DESC = pu_desc  
 From [dbo].prod_units with(nolock)  
 Where pl_id = @plid   
 And pu_desc like '% Rolls'  
  
        --Get all the timestamps and ULID's of the rejects for the rolls unit.   
 INSERT INTO @REJ_ROLLINFO(tstamp, enum)  
 (SELECT  timestamp,  
          event_num  
  FROM  [dbo].events e with(nolock),   
               [dbo].prod_units p with(nolock)  
  WHERE e.pu_id = p.pu_id  
  AND   p.pl_id = @plid  
  AND   p.pu_desc like '% Rolls'  
  AND   event_status = 23                     -- 23 is reject code. Look for reject code for UWS production.  
  AND  (timestamp > @pc_start  
  AND   timestamp <= @pc_end))  
  
         --Stamp the record id onto the reject recordset for that timeframe.  
 UPDATE @REJ_ROLLINFO  
 SET    record_id = @record_id,  
        gcas      = @gcas_code,  
        status    = @line_status  
 WHERE tstamp > @pc_start  
 AND   tstamp <= @pc_end  
  
         -- PRID...look at each timestamp and determine the associated prid.  
 UPDATE @REJ_ROLLINFO  
 SET    prid = result  
 FROM   [dbo].TESTS t with(nolock),  
               [dbo].variables v with(nolock)  
 WHERE  t.var_id = v.var_id  
 AND    v.var_desc = 'PRID'  
 AND    t.result_on = tstamp  
  
        --REJECT WT...come back to check on precision of reject wt from Proficy to PARTs.  
        If left(@PL_DESC,2) = 'FF'  
      begin  
  Update @REJ_ROLLINFO  
  Set    reject_wt = cast(result as real)/1000    
  From   [dbo].TESTS t with(nolock),  
                [dbo].variables v with(nolock)  
  Where  t.var_id = v.var_id  
  And    v.var_desc  = 'Tons Reject'  
  And    t.result_on = tstamp  
      end  
          If left(@PL_DESC,2) = 'TT'  
              begin  
  Update @REJ_ROLLINFO  
  Set    reject_wt = cast(result as real)   
  From   [dbo].TESTS t with(nolock),  
                [dbo].variables v with(nolock)  
  Where  t.var_id = v.var_id  
  And    v.var_desc  = 'Tons Reject'  
  And    t.result_on = tstamp  
       end  
  
        --REJECT DESC...Getting the defect cause description.  
 UPDATE  @REJ_ROLLINFO  
 SET     cause = result  
 FROM    [dbo].TESTS t with(nolock),  
         [dbo].variables v with(nolock)  
 WHERE   t.var_id = v.var_id  
 AND     v.var_desc  Like '% Cause'  
 AND     t.result_on = tstamp  
  
        --GCAS...  
 UPDATE @REJ_ROLLINFO  
 SET    gcas = result  
 FROM   [dbo].TESTS t with(nolock),  
        [dbo].variables v with(nolock)  
 WHERE  t.var_id = v.var_id  
 AND    v.var_desc = 'Roll GCAS'   
        AND    t.result_on = tstamp    
  
         /*3/11/2004 additions for rolls consumed and produced  */  
        --get PROLLS_Produced  
 Select @PROLLS_Produced = count(Event_num)  
 From [dbo].Events e with(nolock),  
             @IntrLineInfoSum1,  
             [dbo].prod_units pu with(nolock)  
 Where pu.pu_id = e.pu_id  
 And pu.pu_desc like @RESOURCE_ID + ' Rolls'  
 And timestamp >= pc_start  
        And timestamp <=pc_end  
  
 Update @IntrLineInfoSum1  
 Set PROLLS_Produced =  @PROLLS_Produced  
 Where pc_start = @pc_start  
 And   pc_end = @pc_end  
  
        --Get PROLLS_Consumed  
 Select @PROLLS_Consumed = count(Event_num)  
 From [dbo].Events e with(nolock),  
             @IntrLineInfoSum1,  
             [dbo].prod_units pu with(nolock)  
 Where pu.pu_id = e.pu_id  
 And pu.pu_desc  like @RESOURCE_ID + ' UWS Production'  
 And timestamp >= pc_start   
        And timestamp <= pc_end  
  
 Update @IntrLineInfoSum1  
 Set PROLLS_Consumed = @PROLLS_Consumed  
 Where pc_start = @pc_start  
 And pc_end = @pc_end  
  
        Update @IntrLineInfoSum2  
        Set PROLLS_Produced = i1.PROLLS_Produced,  
            PROLLS_Consumed = i1.PROLLS_Consumed  
        From @IntrLineInfoSum1 i1, @IntrLineInfoSum2 i2  
        Where i1.record_id = i2.record_id           
   
      FETCH next FROM prod_change_summary_cur  
      INTO @pc_start, @pc_end, @record_id, @gcas_code, @line_status  
  
   end  
  
--Clean the cursor out of memory  
Close prod_change_summary_cur  
Deallocate prod_change_summary_cur  
  
--Return the data to the calling app   
ReturnPlantsAppsIntrData:  
  
Select * From @IntrLineInfoSum2  
Where input_gcas is not null  
  
Select * From @REJ_ROLLINFO  
  
END  
  
