 /*  
Stored Procedure:   spLocal_Parts_Import_Conv_Data  
Author:             John Yannone  
Date Created:       July 2003    
Date Modified:      July,August, 2006  
  
Description:  
This procedure will be called by the PARTS Conv Interface program. This program sits on an "interface box" and is  
launched via the windows task scheduler.  The procedure will gather the conv data required for PARTS based on  
the 'start date' and 'end date' for the production line indicated.  The procedure is intended  
to return one days data, therefore the start date should represent midnight for the desired day and end date  
should represent midnight for the next day.  This procedure will return TWO recordsets, one of un-summarized production  
data by brand run, and the other is the Rejects associated with each production run by brand for a 24 hr period.  
  
JDY 1/25/2005  
Changed the variable name of 'PM Roll Width' to 'Parent Roll Width' because  
of changes made to the Proficy Configuration wrt geneology. See Kim Rafferty,  
or Fran Osorno for further questions regarding.  
  
JDY 1/27/2005  
Changed the variable name of 'PRID' to 'Parent PRID' and also 'Roll GCAS' to  
'Parent GCAS' for the same reason as listed above.  
  
JDY 4/11/2006. Removed the "equals" sign from the nested query when looking up  
the line status phrase. (and start_datetime <= result_on   'is now just'     and start_datetime < result_on)  
  
JDY 4/27/2006 - 5/2/2006.  
Re-wrote the entire SP, adding/changing functionality to account for the way the business now manages  
Line Status values in Proficy and the way we roll up the data to deliver to PARTS. Also performed  
some heaving tuning, e.g., converting temp tables to table variables, declaring most objects at the   
top to avoid multiple compilations, Setting NO COUNT to ON(to reduce the amount of information going   
from the server to clients and reduce the network load), removing Subqueries, renaming vars/objects  
to better suit their business counterparts, optimizing performance by streamlining program logic.   
NOTE: Performance tests were done on mp-proflab001.  
  
PHASE I BETA IMPLEMENTATION DATE: May 7, 2006 @11:49am EST.  
  
JDY May 2006  
Added functionality that will now breakout any scheduled downtime events greater than two hours  
into a separate PARTS NON-RUN record. Incorporated some join conditions FGO made on phase I sp.  
  
JDY 7/12/2006  
Integrated downtime code that originated from the old spLocal_Manage_LTED sp. Stripped out  
all unnecessary code and refined the remaining code to improve efficiancy and readability.  
  
PHASE II BETA IMPLEMENTATION DATE: Rolled out to MP on 7/12/2006 at 3pm EST.  
  
JDY 7/18/06   
Plugged in a line of code that deletes line speeds that are zero. This code can be   
removed once hubsite figures out the problem with the Reports Lines Speed var.  
  
JDY 7/21/06 9:19am EST  
Removed the a snippet of downtime code that was not necessary which was causing  
a problem due to some supporting tables not in place on some site servers.  
  
JDY 8/7/2006   
Added code to pull in the associated line status comment text and user name with  
the event record.  
  
JDY 8/23/06  
Did some tweeking to the code as an Oxnard scenerio revealed a bug wrt rolling up the  
PARTS non run records. Tested it on Oxnard and Proflab. Looks good for the moment! :-)  
  
Eric Perron - STI 2007-01-19  
Correction for MP  
Remove Char(13)+char(10) and char(44) from the comment to prevent the interface to crash.  
Char(13)+char(10) : carriage return and line field code  
char(44) : comma  
Correction for OX  
for NON-RUN i changed the way to compare the information using the Record_id instead  
  
27-JAN-2009  Langdon Davis  Rev2.50  
 -- Modified the way that the Converter Production and Converter Reliability PU's are referenced.  Previously  
  there was a SUBSTRING function being performed on the Resource_ID parameter and this concatenated with   
  'Converter Production' and 'Converter Reliability' to get values for 2 PU_Desc variables used in the   
  look-ups.  Problem was, this assumed some things about the composition of the value for Resource_ID that  
  are not true with resource naming conventions being implemented with the GenIV lines and planned for  
  Proficy Next Generation.  Replaced the use of PU_Desc in these references with PU_ID, with the initial  
  look-up of PU_ID made independent of assumptions about the form of Resource_ID.  
 -- The above change enabled elimination of what were now unecessary JOINS to the Prod_Units table in a   
  number of places.  It also enabled elimination of the @FGOId temporary fix around the line status lookup.  
 -- Added WITH(NOLOCK) in numerous places where it was still missing in SELECTs and JOINs.  
 -- Added code to the lookup of the PL_ID so that it was robust enough to handle either the naming convention  
  that prefixes the PL_Desc with a 'TT' or 'PP', or the newer one that just uses the resource ID.   
 -- Where the PM Roll Width variable data is loaded into the web_width column, modified the code for the FFF1   
  and FFF7 specific exception to use CHARINDEX instead of the SUBSTRING approach so that it too would be   
  able to handle either a 'PP' prefixed or non-prefixed naming convention.  
  
2009-02-24 Jeff Jaeger Rev2.51  
-- updated the method for pulling NoRunID so as to eliminate the use of Local_Timed_Event_Categories.  
  
  
*/  
  
CREATE   PROCEDURE [dbo].[spLocal_Parts_Import_Conv_Data]  
  
--declare  
@START_DATE      datetime,  
@END_DATE        datetime,  
@RESOURCE_ID     varchar(7)  
  
-- select  
--  @Start_date = '26-JAN-2009',  
--  @end_date = '27-JAN-2009',  
--  @resource_id =  'TT OTT2' --'TT AK09'  
  
AS  
  
DECLARE  
@plid              integer,      
@pc_start          datetime,     
@pc_end            datetime,     
@LineStatusStart   datetime,    
@LineStatusEnd     datetime,  
@EventStatus       int,   --this is the prodstatus_id for Reject  
@dt_total            float(3),  
@dt_recID            integer,  
@DownTimeValue      float,  
@record_id           integer,  
@brand_code          varchar(9),  
@line_status         varchar(25),  
  
@Speed               integer,      --Var used to hold the value of the line speed lookup.  
@PU_ID_Production    integer,  
@PU_ID_Reliability   integer,  
@ProfEventStart      DateTime,  
@ProfEventEnd        DateTime,  
@RecCounter1         integer,  
@TotalUnits_Varid    integer,  
@RejectUnits_Varid   integer,  
@PRollWidth_Varid    integer,  
@LineSpeed_Varid     integer,  
@Debug               bit,  
@RecordID            integer,  
@Downtime            float,  
@ScheduleID          integer,  
@ERC_Desc            varchar(60),  
@TEDetId             integer,  
@NonRunId            integer  
  
/*This temp tables holds detailed data from the respective Proficy variables  
for the conv event. */  
Declare @ConvLineInfo table  
(result_on     datetime,  
total_time    integer,  
pc_start      datetime,     --Used to identify the product change start time.  
pc_end        datetime,     --Used to identify the product change end time.  
brandcode     varchar(9),  
status        varchar(25),  --ie, RUN, GE...  
total_logs    integer,  
reject_logs   integer,  
line_speed    integer,  
web_width     float(3))  
  
/* This table contains the same values as the above table, the only difference  
   is we get the line status for each event.*/  
Declare @ConvLineInfoSetStatus table  
(Start_DateTime datetime,  
 End_DateTime   datetime,  
 pc_start      datetime,     --Used to identify the product change start time.  
 pc_end        datetime,     --Used to identify the product change end time.  
 brandcode     varchar(9),  
 Line_Status   varchar(60),   --ie, RUN, GE...                                   
 total_time    integer,   
 result_on     datetime,  
 total_logs    integer,  
 reject_logs   integer,  
 line_speed    integer,  
 web_width     float(3),  
 status_sched_id int)  
  
--This table var will hold the summary of the detailed data of the conv events for a given day.  
--Used to group all the data in the @ConvLineInfo table var.  
Declare @ConvLineInfoSum1 table  
(record_id        integer,               
ProfEventStart   datetime,  
ProfEventEnd     datetime,  
LineStatus_Start datetime,  
LineStatus_End   datetime,  
pc_start         datetime,  
pc_end        datetime,  
brandcode     varchar(75),  
status        varchar(25),  
total_time    integer,                  --difference between the pc_end time and pc_start time or LineStatus_Start & LineStatus_End.  
down_time     float (3),   
DT_ERC_Desc varchar(65),    
total_logs    integer,  
reject_logs   integer,  
line_speed    integer,  
web_width     float(3),  
status_sched_id int,  
status_user_id  int,  
status_username varchar(50),  
status_comment  varchar(510))  
  
  
Declare @ConvLIneInfoSum2 table  
(record_id   integer,  
brandcode    varchar(75),  
status       varchar(25),  
total_time   integer,                   
down_time    float (3),  
DT_ERC_Desc  varchar(65),      
total_logs   integer,  
reject_logs  integer,  
line_speed   integer,  
web_width    float(3),  
status_username  varchar(50),  
status_comment  varchar(510))  
  
  
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
  
--This table used to store reject info.  
Declare  @ProllRejectInfo table  
(tstamp        datetime,  
brandcode     varchar(9),  
status        varchar(25),  
prid          varchar(22),  
gcas          varchar(8),  
reject_wt     float(3),  --need to check on precision of stored value we retrieve.  
cause         varchar(25),  
width         float(3),  
  
enum          varchar(25),  
record_id     integer)  
  
SET ANSI_WARNINGS OFF  
SET NOCOUNT ON  
  
BEGIN  
  
-- Determine the production line id.  
Select @plid = pl_id  
From [dbo].PROD_LINES with(nolock)  
Where pl_desc = @RESOURCE_ID  
  
IF @PLID IS NULL AND (SUBSTRING(@RESOURCE_ID,1,3) = 'TT ' OR SUBSTRING(@RESOURCE_ID,1,3) = 'PP ')   
 --Then try a look-up based on the newer naming convention that does not use these prefixes...  
 BEGIN  
 SELECT @PLID = PL_ID  
 FROM [dbo].PROD_LINES with(nolock)  
 WHERE pl_desc = SUBSTRING(@RESOURCE_ID,4,4)  
 END  
  
-- Set @EventStatus   
Select @EventStatus = prodstatus_id   
From [dbo].production_status with(nolock)  
Where prodstatus_desc = 'Reject'  
  
Select @PU_ID_Production = pu_id from dbo.prod_units with(nolock)   
where pl_id = @plid and pu_desc like '%Converter Production'  
  
Select @PU_ID_Reliability = pu_id from dbo.prod_units with(nolock)  
where pl_id = @plid and pu_desc like '%Converter Reliability'  
  
--Load the Total Unit variable data into the total_logs column.  
Insert Into @ConvLineInfo(result_on, total_logs)  
Select result_on,  
cast(result as real)  
From [dbo].TESTS t with(nolock)  
  Left Join [dbo].variables v with(nolock) ON v.var_id = t.var_id  
Where  v.var_desc = 'Total Units'  
And v.pu_id = @PU_ID_Production  
And t.result_on > @START_DATE   
And t.result_on <= @END_DATE  
  
--Load the Reject Units variable data into the reject_logs column  
Insert Into @ConvLineInfo(result_on, reject_logs)  
Select result_on,  
cast(result as real)  
From [dbo].TESTS t with(nolock)  
  Left Join [dbo].variables v with(nolock) ON v.var_id = t.var_id  
Where  v.var_desc = 'Reject Units'  
And v.pu_id = @PU_ID_Production  
And t.result_on > @START_DATE   
And t.result_on <= @END_DATE  
  
--Load the line_speed variable data into the linespeed column  
Insert Into @ConvLineInfo(result_on,line_speed)  
Select result_on,  
cast(result as real)  
From [dbo].TESTS t with(nolock)  
  Left Join [dbo].variables v with(nolock) ON v.var_id = t.var_id  
Where  v.var_desc = 'Reports Line Speed'  
And v.pu_id = @PU_ID_Production  
And t.result_on > @START_DATE   
And t.result_on <= @END_DATE  
  
--Protection code until the deal with Report Lines Speed gets worked out.  
Delete from @ConvLineInfo   
Where line_speed = 0  
  
--Load the PM Roll Width variable data into the web_width column  
--This condition is GB specific code******************************  
IF charindex(@Resource_ID, 'FFF7|FFF1|PP FFF1|PP FFF7') > 0  
   begin  
      Insert Into @ConvLineInfo(result_on, web_width)  
      Select result_on, cast(result as real)  
      From [dbo].TESTS t with(nolock)  
        Left Join [dbo].variables v with(nolock) ON v.var_id = t.var_id  
      Where  v.var_desc = 'Finished Sheet Width'  
      And v.pu_id = @PU_ID_Production  
      And t.result_on > @START_DATE   
      And t.result_on <= @END_DATE  
    end  
ELSE  --Everybody else  
   begin  
       Insert Into @ConvLineInfo(result_on, web_width)  
       Select result_on, cast(result as real)  
       From [dbo].TESTS t with(nolock)  
         Left Join [dbo].variables v with(nolock) ON v.var_id = t.var_id  
       Where  (v.var_desc = 'Parent Roll Width' or v.var_desc = 'PM Roll Width')  
       And v.pu_id = @PU_ID_Production  
       And t.result_on > @START_DATE   
       And t.result_on <= @END_DATE  
    end  
  
Update @ConvLineInfo  
Set pc_start =  
    case  
           when ps.start_time < @START_DATE then @START_DATE  
           else ps.start_time  
           end,  
    pc_end =  
    case  
           when ps.end_time is null then @END_DATE  
           when ps.end_time > @END_DATE then @END_DATE  
           else ps.end_time  
           end,  
    brandcode = pro.prod_code  
From [dbo].PRODUCTION_STARTS ps with(nolock)  
    Left Join [dbo].PRODUCTS pro with(nolock) ON pro.prod_id = ps.prod_id  
Where ps.pu_id = @PU_ID_Production  
And  (ps.start_time <= result_on  
And  (ps.end_time > result_on  
Or    ps.end_time is null))  
  
--Sets the Line Status for each result on.  
Insert @ConvLineInfoSetStatus  
Select   
       case  
           when sta.Start_DateTime < @START_DATE then @START_DATE  
           else sta.Start_DateTime  
           end,  
       case  
           when sta.End_DateTime  > @END_DATE then @END_DATE  
           else sta.End_DateTime  
        end,  
       pc_start, pc_end, brandcode, phr.Phrase_Value, total_time,    
       result_on, total_logs, reject_logs, line_speed, web_width, sta.status_schedule_id  
From   [dbo].LOCAL_PG_LINE_STATUS sta with(nolock),   
       [dbo].PHRASE phr with(nolock),   
       @ConvLineInfo c  
Where  
sta.unit_id = @PU_ID_Production  
And   sta.line_status_id = phr.phrase_id  
And    sta.update_status <> 'DELETE'  
And    start_datetime = (select max(l.start_datetime)  
                         from [dbo].LOCAL_PG_LINE_STATUS l with(nolock)  
                   where l.unit_id = @PU_ID_Production   
                         and l.update_status <> 'DELETE'   
                         and   start_datetime < result_on)  
        
Insert @ConvLineInfoSum1  
Select null,  
       null,  
       null,  
        Start_DateTime,  
        End_DateTime,  
        pc_start,  
        pc_end,  
        brandcode,  
        Line_Status,  
        avg(total_time) ttime,            
        null,  --downtime  
        null,  --downtime ERC  
        sum(isnull(total_logs,0)) AS tlogs,  
        sum(isnull(reject_logs,0)) AS rlogs,  
        avg(line_speed) AS speed,  
        isnull(avg(web_width),0) AS width,  
        status_sched_id,  
        null,  
        null,  
        null   
From @ConvLineInfoSetStatus  
GROUP BY Start_DateTime,End_DateTime, pc_start, pc_end, brandcode, Line_Status, status_sched_id  
          
  
/*Calculate the Start and End times of the Individual Proficy events  
  based off the different combinations of pc_start & pc_end and LineStatus_Start & LineStatus_End.*/  
Update @ConvLineInfoSum1  
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
Update @ConvLineInfoSum1  
Set total_time = datediff(mi,ProfEventStart,ProfEventEnd)  
  
--We count 'Rel Unknown:Qual Unknown' as an INCLUDED event.  
Update @ConvLineInfoSum1  
Set status = 'Rel Inc:Qual Unknown'  
Where status like 'Rel Unk%'  
         
--************Begin assembling Downtime info into the table variable @LTED.*******************  
-- Build @PUIDList which will be used to restrict the data.  
Insert @PUIDList(puid,pudesc)  
Select distinct  
 pu_id,  
 pu_desc  
From dbo.prod_units with(nolock)  
Where pl_id = @plid  
And master_unit is null  
and pu_desc like '%Converter Reliability'  
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
   row FROM the Local_Timed_Event_Categories table using the TEDet_Id.   
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
From   @ConvLineInfoSum1    
  
OPEN event_change_cur  
FETCH next FROM event_change_cur  
INTO @RecordID, @ProfEventStart, @ProfEventEnd   
  
WHILE (@@FETCH_STATUS <> -1)  
  
   begin  
 Select @RecCounter1 = @RecCounter1 + 1  
           
 Update @ConvLineInfoSum1    
 Set    record_id = @RecCounter1  
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
 From @LTED t   
 Where t.puid = @PU_ID_Reliability     
    AND  ((starttime >= @ProfEventStart  
         AND   starttime < @ProfEventEnd)  
         OR   (endtime <= @ProfEventEnd and endtime > @ProfEventStart)  
         OR   (starttime < @ProfEventStart and endtime > @ProfEventStart))  
          
     FETCH next FROM event_change_cur  
 INTO @RecordID, @ProfEventStart, @ProfEventEnd  
   end   
  
Close event_change_cur  
deallocate event_change_cur  
  
  
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
           INSERT INTO @ConvLineInfoSum1  
           Select @dt_recID, ProfEventStart, ProfEventEnd, LineStatus_Start, LineStatus_End,  
                  pc_start, pc_end, brandcode, status, 0/*total_time*/, @Downtime, @ERC_Desc, 0/*total_logs*/, 0/*reject_logs*/,  
                  0/*line_speed*/, 0/*web_width*/, status_sched_id, null, null, null  
           from @ConvLineInfoSum1  
           Where record_id = @RecordID  
   
            --  print 'My Downtime value for record id ' + convert(varchar,@RecordID) + ' is: ' + convert(varchar,@Downtime)   
             
           --Set the DT record with a DT rec id for distinction when rolling up the data.  
           Update @DownTimeInfo  
           Set record_id = @dt_recID  
   WHERE record_id = @RecordID  
    AND DownTime > 120.0   
  
           /* Since we had to create a separate event record for the non-run event then  
              we need to subtract that downtime from the actual time of the run event. */  
           Update @ConvLineInfoSum1  
           Set total_time = (total_time - @Downtime)  
           Where record_id = @RecordID             
  
      FETCH next FROM PartsDownTimeEvents_cur  
      INTO @RecordID, @TEDetId, @Downtime, @ScheduleID, @NonRunId, @ERC_Desc  
          
   end  
CLOSE PartsDownTimeEvents_cur  
deallocate PartsDownTimeEvents_cur  
  
  
DECLARE RunEventsDownTime_cur cursor for   
SELECT record_id   
FROM @ConvLineInfoSum1  
WHERE record_id < 1000    --This restriction ensures we do not resummarize downtime records we have already summarized.  
  
ORDER BY record_id asc  
  
OPEN RunEventsDownTime_cur  
FETCH next FROM RunEventsDownTime_cur  
INTO @RecordID  
  
 WHILE (@@FETCH_STATUS <> -1)  
   begin  
      Update @ConvLineInfoSum1  
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
Update @ConvLineInfoSum1  
Set  status_user_id = lsc.User_Id  
From [dbo].Local_PG_Line_Status_Comments lsc with(nolock), @ConvLineInfoSum1 c1  
Where c1.status_sched_id = lsc.status_schedule_id  
  
--Fetch the associated comment text and user name based of status schedule id.  
Update @ConvLineInfoSum1  
Set  status_comment = lsc.comment_text,  
     status_username = u.username  
from [dbo].Local_PG_Line_Status_Comments lsc with(nolock), @ConvLineInfoSum1 c1,  
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
Insert Into @ConvLineInfoSum2  
select null, brandcode, status, sum(round(total_time,0)), sum(Down_Time), DT_ERC_Desc, sum(total_logs), sum(reject_logs), avg(line_speed), avg(web_width),   
status_username, status_comment  
from @ConvLineInfoSum1   
where record_id > 1000  
group by   brandcode, status, DT_ERC_Desc , status_username, status_comment  
  
--Reset the record_id because we could not use it in the group by statement above.  
Update c2  
set c2.record_id = c1.record_id  
from @ConvLineInfoSum1 c1, @ConvLineInfoSum2 c2  
where c1.DT_ERC_Desc = c2.DT_ERC_Desc  
  
--Add all the run events recs from @ConvLineInfoSum1.  
Insert Into @ConvLineInfoSum2  
Select record_id,brandcode, status, total_time, down_time, DT_ERC_Desc, total_logs, reject_logs, line_speed, web_width,   
       status_username, status_comment  
From @ConvLineInfoSum1 c1  
Where c1.record_id < 1000  
  
  
--*************GET PROLL REJECT INFO*****************************  
DECLARE proll_rejects_cur cursor for  
SELECT  ProfEventStart, ProfEventEnd, record_id, brandcode, status    
FROM   @ConvLineInfoSum1  
OPEN proll_rejects_cur  
  
FETCH NEXT FROM proll_rejects_cur  
INTO @ProfEventStart, @ProfEventEnd, @record_id, @brand_code, @line_status     
  
/*The @@FETCH_STATUS variable will contain information about the last fetch that was made from the  
  current connection. If the @@FETCH_STATUS is -1, you have reached the end of the cursor and it is  
 time to exit the loop.  pg.79 "Writing Stored Procedures for Microsoft SQL Server". JDY 7/16/2003  */  
WHILE (@@FETCH_STATUS <> -1)  
   begin  
  
 --Get all the timestamps and ULID's of the rejects.  
  INSERT INTO @ProllRejectInfo(tstamp, enum)  
 (SELECT  timestamp, event_num  
  FROM  [dbo].events e with(nolock)  
  WHERE e.pu_id = @PU_ID_Production  
  AND   event_status = @EventStatus  
  AND  (timestamp > @ProfEventStart  
  AND   timestamp <= @ProfEventEnd))  
   
 --Stamp the record id onto the reject recordset for that timeframe.  
 UPDATE @ProllRejectInfo  
 SET    record_id = @record_id,  
        brandcode = @brand_code,  
        status    = @line_status  
 WHERE tstamp > @ProfEventStart  
 AND   tstamp <= @ProfEventEnd  
   
 -- PRID...look at each timestamp and determine the associated prid.  
 UPDATE @ProllRejectInfo  
 SET    prid = result  
 FROM   [dbo].tests t with(nolock)  
 LEFT JOIN [dbo].variables v with(nolock) ON v.var_id = t.var_id  
 WHERE (v.var_desc = 'Parent PRID' or v.var_desc = 'PRID')   
        AND t.result_on = tstamp  
   
 --REJECT WT...come back to check on precision of reject wt from Proficy to PARTs.  
 UPDATE @ProllRejectInfo  
 SET    reject_wt = cast(result as real)   --/1000  --conversion to metric tons removed here because it has already been converted when we pull it in.  
 FROM   [dbo].tests t with(nolock)  
 LEFT JOIN [dbo].variables v with(nolock) ON v.var_id = t.var_id  
 WHERE v.var_desc = 'CV PRoll Reject Weight'   
        AND t.result_on = tstamp  
   
 --REJECT DESC...Getting the defect cause description.  
 UPDATE  @ProllRejectInfo  
 SET     cause = result  
 FROM    [dbo].tests t with(nolock)  
 LEFT JOIN [dbo].variables v with(nolock) ON v.var_id = t.var_id  
 WHERE   v.var_desc = 'Paper Defect Cause'   
        AND t.result_on = tstamp   
   
 --WIDTH...  
 UPDATE @ProllRejectInfo  
 SET    width = result  
 FROM   [dbo].tests t with(nolock)  
 LEFT JOIN [dbo].variables v with(nolock) ON v.var_id = t.var_id  
 WHERE (v.var_desc = 'Parent Roll Width' or v.var_desc = 'PM Roll Width')   
        AND  t.result_on = tstamp  
   
 --GCAS...  
 UPDATE @ProllRejectInfo  
 SET    gcas = result  
 FROM   [dbo].tests t with(nolock)  
 LEFT JOIN [dbo].variables v with(nolock) ON v.var_id = t.var_id  
 LEFT JOIN  [dbo].events e with(nolock) ON e.pu_id = v.pu_id and t.result_on = e.timestamp  
 LEFT JOIN @ProllRejectInfo p ON p.enum = e.event_num  
 WHERE (v.var_desc = 'Parent GCAS' or v.var_desc = 'Roll GCAS')    
        AND e.timestamp <> tstamp  
  
   
 FETCH next FROM proll_rejects_cur  
 INTO @ProfEventStart, @ProfEventEnd, @record_id, @brand_code, @line_status  
   end   
  
CLOSE proll_rejects_cur  
deallocate proll_rejects_cur  
  
ReturnPlantApps:  
  select record_id,  
   brandcode,  
   status,  
   total_time,  
   down_time,  
   DT_ERC_Desc,  
   total_logs,  
   reject_logs,  
   line_speed,  
   web_width,  
   status_username,  
   REPLACE(REPLACE(status_comment,char(13)+char(10), ' '),char(44),' ') status_comment  
 from @ConvLineInfoSum2 Order by record_id asc  
  select * from @ProllRejectInfo  
  
END  
  
