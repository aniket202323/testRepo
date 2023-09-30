 /*  
==============================================================================================================  
Stored Procedure:   spLocal_Parts_Import_Pmkg_Data  
Author:             John Yannone  
Date Created:       10/16/2003  
Date Revised:       9/13,14/2006  
Version Compliant:  Yes. 3.X and 4.X   
Revision Number:    2.0.0  
==============================================================================================================  
Description:  
This procedure will be called by a VB application.  The procedure will gather the PMKG data required  
for PARTS based on the start date and end date for the production line indicated.  The procedure is intended  
to return one days data, therefore the start date should represent midnight for the desired day and end date  
should represent midnight for the next day.  This procedure will return a recordset summarizing production  
data grouped by brand changes.    
  
Change History:  
 JYD 3/11/2004  
 Completed modifications for SP to pull in three additional variables. They are:  
 DRY_STRENGTH_FACIAL_MASS_FLOW_DAY_SUM,  
 WET_STRENGTH_FACIAL_MASS_FLOW_DAY_SUM,  
 SOFTENER_FACIAL_MASS_FLOW_DAY_SUM.  
  
 JDY 4/11/2006  
 Removed the "equals" sign from the nested query when looking up the line status phrase.   
 (and start_datetime <= result_on   'is now just'     and start_datetime < result_on)  
 Also added the WHERE clause condition of "AND s.Update_Status <> 'DELETE'"  
  
 JDY 9/13,14/2006  
 Revised the sp to make it 3x and 4x compliant. Tuned the sp to take advantage of Table Variables.  
 Added in all the [dbo] prefixes to the tables, and also appended (with nolock) condtition.  
 Removed the FINALSUM table.  
  
 JDY Sept/Oct 2006  Rev1.40  
 Modified sp to ALTER  "Proficy Events" based on combinations of LineStatus changes in   
 conjunction with product changes. From this a Proficy Event start and end time can be defined.  
  
 Incorporated new downtime approach (as re-applied from converting sp). The code now queries  
 for the data differently. It will also break out downtime records with a duration greater than  
 120 minutes into separate events.  
  
 Appends the line status user and comment to the record. Information that will be used in PARTS.  
  
2009-02-24 Jeff Jaeger Rev1.41  
-- updated the method for pulling NoRunID so as to eliminate the use of Local_Timed_Event_Categories.  
  
 */  
  
--/*  
CREATE     PROCEDURE spLocal_Parts_Import_Pmkg_Data  
--Variables in upper case denote parameters in.  
@STARTDATE      datetime,  
@ENDDATE      datetime,  
@PRODLINE     varchar(7)  
AS  
--*/  
  
/*  
  
declare  
@STARTDATE      datetime,  
@ENDDATE      datetime,  
@PRODLINE     varchar(7)  
  
select  
@STARTDATE   = '2009-02-16 05:00:00',  
@ENDDATE     = '2009-02-17 05:00:00',  
@PRODLINE    = 'TT PC1X'  
  
*/  
  
SET NOCOUNT ON  
  
  
DECLARE  
@strSQL             varchar(1000),  
@plid               int,  
@pc_start          datetime,  
@pc_end             datetime,  
@LineStatusStart    datetime,  
@LineStatusEnd      datetime,  
@EventStatus        int,  
@ProfEventStart     DateTime,  
@ProfEventEnd       DateTime,  
@Debug              bit,  
@dt_total           float(3),  
@dt_recID           integer,  
@DownTimeValue      float,  
@RecordID           integer,  
@RecCounter1        integer,  
@Downtime           float,  
@ScheduleID         integer,  
@ERC_Desc           varchar(60),  
@TEDetId            integer,  
@NonRunId           integer,  
@FGOid int,  
  
@vardesc      varchar(50),  
@pudesc       varchar(25),  
@colname      varchar(25),  
@totfactor    varchar(4),  
@var_id       int  
  
CREATE TABLE #PaperMachInfo (  
vardate             datetime,  
total_time            float(2),  
pc_start              datetime,  
pc_end                datetime,  
down_time             float(2),  
GCAS                  varchar(8),  
Line_Status           varchar(25),  
good_tons             float(3),  
reject_tons           float(3),  
broke_tons            float(3),  
yankee_tons           float(3),  
yankee_speed          int,  
reel_speed       int,  
basis_weight          float(2),  
prod_width            float(2),  
long_fiber_tons       float(3),  
short_fiber_tons      float(3),  
CTMP_tons             float(3),  
furnish_3rd_tons      float(3),  
  
product_broke_tons    float(3),  
machine_broke_tons    float(3),  
wet_strength_tissue   float(2),  
wet_strength_towel    float(2),  
softener_towel        float(2),  
softener_tissue       float(2),  
cat_promoter          float(2),  
absorbency_aid_towel  float(2),  
dry_strength_towel    float(2),  
dry_strength_tissue   float(2),  
glue                  float(2),  
emulsion_1            float(2),  
emulsion_2            float(2),  
single_glue           float(2),  
dry_strength_facial   float(2),    
wet_strength_facial   float(2),    
softener_facial       float(2),  
status_sched_id       int)    
  
Declare @PaperMachInfo Table (  
vardate             datetime,  
total_time            float(2),  
pc_start              datetime,  
pc_end                datetime,  
down_time             float(2),  
GCAS                  varchar(8),  
Line_Status           varchar(25),  
good_tons             float(3),  
reject_tons           float(3),  
broke_tons            float(3),  
yankee_tons           float(3),  
yankee_speed          int,  
reel_speed            int,  
basis_weight          float(2),  
prod_width            float(2),  
long_fiber_tons       float(3),  
short_fiber_tons      float(3),  
CTMP_tons             float(3),  
furnish_3rd_tons      float(3),  
product_broke_tons    float(3),  
machine_broke_tons    float(3),  
wet_strength_tissue   float(2),  
wet_strength_towel    float(2),  
softener_towel        float(2),  
softener_tissue       float(2),  
cat_promoter          float(2),  
absorbency_aid_towel  float(2),  
dry_strength_towel    float(2),  
dry_strength_tissue   float(2),  
glue                  float(2),  
emulsion_1            float(2),  
emulsion_2            float(2),  
single_glue           float(2),  
dry_strength_facial   float(2),    
wet_strength_facial   float(2),    
softener_facial       float(2),  
status_sched_id       int)    
  
DECLARE @PaperMachSetLineStatus TABLE(  
LineStatus_Start      datetime,  
LineStatus_End        datetime,  
pc_start              datetime,  
pc_end                datetime,  
GCAS                  varchar(8),  
Line_Status           varchar(25),  
total_time            float(2),  
down_time             float(2),  
DT_ERC_Desc           varchar(65),  
good_tons             float(3),  
reject_tons           float(3),  
broke_tons            float(3),  
yankee_tons           float(3),  
yankee_speed          int,  
reel_speed            int,  
basis_weight          float(2),  
prod_width            float(2),  
long_fiber_tons       float(3),  
short_fiber_tons      float(3),  
CTMP_tons             float(3),  
furnish_3rd_tons      float(3),  
product_broke_tons    float(3),  
machine_broke_tons    float(3),  
wet_strength_tissue   float(2),  
wet_strength_towel    float(2),  
softener_towel        float(2),  
softener_tissue       float(2),  
cat_promoter          float(2),  
absorbency_aid_towel  float(2),  
dry_strength_towel    float(2),  
dry_strength_tissue   float(2),  
glue                  float(2),  
emulsion_1            float(2),  
emulsion_2            float(2),  
single_glue           float(2),  
dry_strength_facial   float(2),   
wet_strength_facial   float(2),   
softener_facial       float(2),  
status_sched_id       int)    
  
DECLARE @PaperMachInfoSum1 TABLE(   
record_id             int,  
ProfEventStart        datetime,  
ProfEventEnd          datetime,  
LineStatus_Start      datetime,                     --Start_DateTime  
LineStatus_End        datetime,                     --End_DateTime  
pc_start              datetime,  
pc_end                datetime,  
GCAS                  varchar(8),  
Line_Status           varchar(25),  
total_time            float(2),  
down_time             float(2),  
DT_ERC_Desc           varchar(65),  
good_tons             float(3),  
reject_tons           float(3),  
broke_tons            float(3),  
yankee_tons           float(3),  
yankee_speed          int,  
reel_speed            int,  
basis_weight          float(2),  
prod_width            float(2),  
long_fiber_tons       float(3),  
short_fiber_tons      float(3),  
CTMP_tons             float(3),  
furnish_3rd_tons      float(3),  
product_broke_tons    float(3),  
machine_broke_tons    float(3),  
wet_strength_tissue   float(2),  
wet_strength_towel    float(2),  
softener_towel        float(2),  
softener_tissue       float(2),  
cat_promoter          float(2),  
absorbency_aid_towel  float(2),  
dry_strength_towel    float(2),  
dry_strength_tissue   float(2),  
glue                  float(2),  
emulsion              float(2),  
dry_strength_facial   float(2),    
wet_strength_facial   float(2),    
softener_facial       float(2),  
status_sched_id       int,  
status_user_id        int,  
status_username       varchar(50),  
status_comment        varchar(510))    
  
DECLARE @PaperMachInfoSum2 TABLE(   
record_id             int,  
GCAS                  varchar(8),  
Line_Status           varchar(25),  
total_time            float(2),  
down_time             float(2),  
DT_ERC_Desc           varchar(65),  
good_tons             float(3),  
reject_tons           float(3),  
broke_tons            float(3),  
yankee_tons           float(3),  
yankee_speed          int,  
reel_speed            int,  
basis_weight          float(2),  
prod_width            float(2),  
long_fiber_tons       float(3),  
short_fiber_tons      float(3),  
CTMP_tons             float(3),  
furnish_3rd_tons      float(3),  
product_broke_tons    float(3),  
machine_broke_tons    float(3),  
wet_strength_tissue   float(2),  
wet_strength_towel    float(2),  
softener_towel        float(2),  
softener_tissue       float(2),  
cat_promoter          float(2),  
absorbency_aid_towel  float(2),  
dry_strength_towel    float(2),  
dry_strength_tissue   float(2),  
glue                  float(2),  
emulsion              float(2),  
dry_strength_facial   float(2),    
wet_strength_facial   float(2),    
softener_facial       float(2),  
status_username       varchar(50),  
status_comment        varchar(510))    
  
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
  
DECLARE loadvar_cur CURSOR FOR  
SELECT var_desc, pu_desc, column_name, total_factor  
FROM [dbo].Local_Parts_Pmkg_Variables with(nolock)  
  
DECLARE var_cur CURSOR FOR  
SELECT pc_start, pc_end  
FROM @PaperMachInfoSum1  
  
  
BEGIN --Begin sp.  
  
Select @Debug = 0  
    If @Debug = 1   
      begin  
        SELECT @STARTDATE = '07-aug-06'  
 SELECT @ENDDATE = '08-aug-06'  
 SELECT @PRODLINE = 'TT AY5A'  
      end  
  
SELECT @plid = pl_id  
FROM [dbo].PROD_LINES  
WHERE pl_desc = @PRODLINE  
  
--Substring @PRODLINE only once then use throughout.  
SELECT @PRODLINE = substring(@PRODLINE,4,4)  
  
OPEN loadvar_cur  
FETCH NEXT FROM loadvar_cur  
INTO @vardesc, @pudesc, @colname, @totfactor  
  
WHILE @@FETCH_STATUS = 0  
  
  begin          
         SELECT @strSQL = 'INSERT INTO #PaperMachInfo(vardate, ' + @colname + ')  
                          (Select result_on, cast(result as real)  
                           From [dbo].TESTS with(nolock)  
                           Where var_id = (select v.var_id  
                                           from [dbo].variables v with(nolock),   
                                                [dbo].prod_units p with(nolock)  
                        where v.pu_id = p.pu_id  
                                           and p.pl_id = ' + Convert(varchar,@plid) +  
                                         ' and v.var_desc = ''' + @vardesc +  
                                       ''' and p.pu_desc = ''' + @PRODLINE + ' ' + @pudesc + ''')  
                            and (result_on > ''' + Convert(varchar,@STARTDATE,100) +  
                        ''' and result_on <= ''' + Convert(varchar,@ENDDATE,100) + '''))'   
       EXEC(@strSQL)  
  
       FETCH NEXT FROM loadvar_cur  
       INTO @vardesc, @pudesc, @colname, @totfactor  
  end  
  
CLOSE loadvar_cur  
DEALLOCATE loadvar_cur  
  
--Move Table contents into table variable. Drop Original table.  
Insert Into @PaperMachInfo  
Select * From #PaperMachInfo  
Drop Table #PaperMachInfo  
  
--This gets the gcas value from the most recent Roll.  
Update @PaperMachInfo  
Set   GCAS = t.result  
From  [dbo].TESTS t with(nolock),   
      [dbo].VARIABLES v with(nolock),   
      [dbo].PROD_UNITS p with(nolock)  
Where t.var_id = v.var_id  
And   v.pu_id = p.pu_id  
And   v.var_desc = 'Roll GCAS'  
And   p.pu_desc = @PRODLINE + ' Rolls'  
And   p.pl_id = @plid  
And   t.result_on  = (select max(t2.result_on)  
                      from [dbo].tests t2 with(nolock),   
                           [dbo].variables v2 with(nolock),   
                           [dbo].prod_units p2 with(nolock)  
                      where t2.var_id = v2.var_id  
                      and v2.pu_id = p2.pu_id  
                      and v2.var_desc = 'Roll GCAS'  
                      and p2.pu_desc = @PRODLINE + ' Rolls'  
                      and p2.pl_id = @plid  
                      and t2.result_on <= vardate)  
  
--Figuring out the Start and End time of the current  
--product run. Populate two columns 'PC START and PC END'  
UPDATE @PaperMachInfo  
SET pc_start =  
    CASE  
           WHEN ps.start_time < @STARTDATE THEN @STARTDATE  
           ELSE ps.start_time  
           END,  
    pc_end =  
    CASE  
           WHEN ps.end_time IS NULL THEN @ENDDATE  
           WHEN ps.end_time > @ENDDATE THEN @ENDDATE  
           ELSE ps.end_time  
           END  
FROM [dbo].production_starts ps with(nolock),   
     [dbo].prod_units pu with(nolock)  
WHERE ps.pu_id = pu.pu_id  
AND  (ps.start_time <= vardate  
AND  (ps.end_time > vardate  
OR    ps.end_time is null))  
AND   pu.pu_desc = @PRODLINE + ' Production'  
AND   pu.pl_id = @plid  
  
  
select @fgoid = pu_id from dbo.prod_units with(nolock)where pu_desc = @PRODLINE + ' Production'  
--Set the Line Status for each result on.  
Insert @PaperMachSetLineStatus  
Select   
       case  
           when sta.Start_DateTime < @STARTDATE then @STARTDATE  
           else sta.Start_DateTime  
           end,  
       case  
           when sta.End_DateTime  > @ENDDATE then @ENDDATE  
           else sta.End_DateTime  
        end,  
       pc_start, pc_end, GCAS, phr.Phrase_Value, null /*total_time*/, null/*downtime*/, null/*DT_ERC_DESC*/, good_tons,   
       reject_tons, broke_tons, yankee_tons, yankee_speed, reel_speed, basis_weight, prod_width, long_fiber_tons,   
       short_fiber_tons, CTMP_tons, furnish_3rd_tons, product_broke_tons, machine_broke_tons, wet_strength_tissue,  
       wet_strength_towel, softener_towel, softener_tissue, cat_promoter, absorbency_aid_towel,  
       dry_strength_towel, dry_strength_tissue, glue, emulsion_1, emulsion_2, single_glue,  
       dry_strength_facial, wet_strength_facial, softener_facial, sta.status_schedule_id   
From   [dbo].LOCAL_PG_LINE_STATUS sta with(nolock),   
       [dbo].PROD_UNITS pu with(nolock),   
       [dbo].PHRASE phr with(nolock),   
       @PaperMachInfo v  
Where  
sta.unit_id = @fgoid    
and sta.unit_id = pu.pu_id  
And    sta.line_status_id = phr.phrase_id  
And    pu.pl_id = @plid  
And    sta.update_status <> 'DELETE'  
And    start_datetime = (select max(l.start_datetime)  
                         from [dbo].LOCAL_PG_LINE_STATUS l with(nolock)  
         left join [dbo].PROD_UNITS p on l.unit_id = p.pu_id  --[dbo].prod_units pu with(nolock)       
                         where p.pu_desc = @PRODLINE + ' Production'               --where l.unit_id = pu.pu_id                  
                         and l.update_status <> 'DELETE'                           --and pu.pl_id = @plid                        
                         and start_datetime < vardate)                             --and l.update_status <> 'DELETE'             
                                                                                   --and start_datetime < vardate)  
  
  
--Column names for the nulls are to the right.  
INSERT INTO @PaperMachInfoSum1  
select  null,          --record_id  
        null,         --ProfEventStart  
        null,         --ProfEventEnd  
        LineStatus_Start,   
        LineStatus_End,   
        pc_start,   
        pc_end,   
        gcas,   
        Line_status,   
        null,                           --avg(total_time) ttime,  
        null,                           --downtime  
        null,                           --DT_ERC_DESC  
        sum(IsNull(good_tons,0)),  
        sum(IsNull(reject_tons,0)),  
        sum(IsNull(broke_tons,0)),  
        sum(IsNull(yankee_tons,0)),  
        avg(yankee_speed),  
        avg(reel_speed),  
        avg(basis_weight),  
        avg(prod_width),  
        sum(IsNull(long_fiber_tons,0)),  
        sum(IsNull(short_fiber_tons,0)),  
        sum(IsNull(ctmp_tons,0)),  
        sum(IsNull(furnish_3rd_tons,0)),  
        sum(IsNull(product_broke_tons,0)),  
        sum(IsNull(machine_broke_tons,0)),  
        sum(IsNull(wet_strength_tissue,0)),  
        sum(IsNull(wet_strength_towel,0)),  
        sum(IsNull(softener_towel,0)),  
        sum(IsNull(softener_tissue,0)),  
        sum(IsNull(cat_promoter,0)),  
        sum(IsNull(absorbency_aid_towel,0)),  
        sum(IsNull(dry_strength_towel,0)),  
        sum(IsNull(dry_strength_tissue,0)),  
        sum(IsNull(single_glue,0)) + sum(IsNull(glue,0)),        --glue  
        sum(IsNull(emulsion_1,0)) + sum(IsNull(emulsion_2,0)),   --Emulsion          
        sum(IsNull(dry_strength_facial,0)),  
        sum(IsNull(wet_strength_facial,0)),  
        sum(IsNull(softener_facial,0)),  
        status_sched_id,  
        null,        --status_user_id,  
        null,        --status_username,  
        null         --status_comment  
from @PaperMachSetLineStatus    
group by LineStatus_Start, LineStatus_End, pc_start, pc_end, gcas, Line_status, status_sched_id  
  
  
/*Calculate the Start and End times of the Individual Proficy events  
  based off the different combinations of pc_start & pc_end and LineStatus_Start & LineStatus_End.*/  
Update @PaperMachInfoSum1  
set ProfEventStart =   
   case   
            when datediff(mi,pc_start,pc_end) = 0    
              then pc_start                               
            when (LineStatus_Start = @STARTDATE) and (LineStatus_End is null or LineStatus_End = @ENDDATE)   
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
            when (LineStatus_Start = @STARTDATE) and (LineStatus_End is null or LineStatus_End = @ENDDATE)   
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
  
--Calc total time.  
Update @PaperMachInfoSum1  
Set total_time = datediff(mi,ProfEventStart,ProfEventEnd)  
  
--We count 'Rel Unknown:Qual Unknown' as an INCLUDED event.  
Update @PaperMachInfoSum1  
Set Line_Status = 'Rel Inc:Qual Unknown'  
Where Line_Status like 'Rel Unk%'  
  
--************Begin assembling Downtime info into the table variable @LTED.*******************  
-- Build @PUIDList which will be used to restrict the data.  
Insert @PUIDList(puid,pudesc)  
Select distinct  
 pu_id,  
 pu_desc  
From [dbo].PROD_UNITS with(nolock)  
Where pl_id = @plid  
And pu_desc = @PRODLINE + ' Reliability'                            
And master_unit is null  
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
And  t.start_time < @ENDDATE  
And (t.end_time > @STARTDATE or t.end_time is null)  
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
--*****End Downtime gathering into @LTED**********************************  
*/  
  
UPDATE td SET  
 NonRunId = erc.ERC_Id  
FROM @LTed td   
JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
ON TD.ERTD_ID = ercd.event_reason_tree_data_id   
JOIN dbo.event_reason_catagories erc WITH (NOLOCK)   
ON ercd.erc_id = erc.erc_id   
where erc.ERC_Desc LIKE 'PARTS Non-Run%'  
  
  
--Once downtime is assembled into the @LTED table above, we can query  
--against it here using the profeventstart and profeventend times to   
--get the downtime for a specific proficy event.  
SET  @RecCounter1 = 0  
  
Declare event_change_cur cursor for  
Select  record_id, ProfEventStart, ProfEventEnd  
From   @PaperMachInfoSum1    
  
OPEN event_change_cur  
FETCH next FROM event_change_cur  
INTO @RecordID, @ProfEventStart, @ProfEventEnd   
  
WHILE (@@FETCH_STATUS <> -1)  
  
   begin  
 Select @RecCounter1 = @RecCounter1 + 1  
           
 Update @PaperMachInfoSum1    
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
 From @LTED t,   
             [dbo].prod_units p with(nolock)   
  Where t.puid = p.pu_id    
  And   p.pu_desc = @PRODLINE + ' Reliability'       --@PU_Desc2  substring(@RESOURCE_ID,4,4) + ' Converter Reliability'          
  And   p.pl_id = @plid  
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
           INSERT INTO @PaperMachInfoSum1  
           Select @dt_recID, ProfEventStart, ProfEventEnd, LineStatus_Start, LineStatus_End, pc_start, pc_end, GCAS, Line_Status,   
                  0/*total_time*/,   
                  @Downtime, @ERC_Desc,   
                  0/*good_tons*/, 0/*reject_tons*/, 0/*broke_tons*/, 0/*yankee_tons*/, 0/*yankee_speed*/, 0/*reel_speed*/,   
                  0/*basis_weight*/, 0/*prod_width*/, 0/*long_fiber_tons*/, 0/*short_fiber_tons*/, 0/*CTMP_tons*/,   
                  0/*furnish_3rd_tons*/, 0/*product_broke_tons*/, 0/*machine_broke_tons*/, 0/*wet_strength_tissue*/,   
                  0/*wet_strength_towel*/, 0/*softener_towel*/, 0/*softener_tissue*/, 0/*cat_promoter*/, 0/*absorbency_aid_towel*/,   
                  0/*dry_strength_towel*/, 0/*dry_strength_tissue*/, 0/*glue*/, 0/*emulsion*/, 0/*dry_strength_facial*/,   
                  0/*wet_strength_facial*/, 0/*softener_facial*/,  
                  status_sched_id, null, null, null  
           from @PaperMachInfoSum1  
           Where record_id = @RecordID  
  
          --Set the DT record with a DT rec id for distinction when rolling up the data.  
           Update @DownTimeInfo  
           Set record_id = @dt_recID  
           Where TEDetId = @TEDetId  
  
           /* Since we had to create a separate event record for the non-run event then  
              we need to subtract that downtime from the actual time of the run event. */  
           Update @PaperMachInfoSum1  
           Set total_time = (total_time - @Downtime)  
           Where record_id = @RecordID             
  
      FETCH next FROM PartsDownTimeEvents_cur  
      INTO @RecordID, @TEDetId, @Downtime, @ScheduleID, @NonRunId, @ERC_Desc  
          
   end  
CLOSE PartsDownTimeEvents_cur  
deallocate PartsDownTimeEvents_cur  
  
DECLARE RunEventsDownTime_cur cursor for   
SELECT record_id   
FROM @PaperMachInfoSum1  
WHERE record_id < 1000    --This restriction ensures we do not resummarize downtime records we have already summarized.  
  
ORDER BY record_id asc  
  
OPEN RunEventsDownTime_cur  
FETCH next FROM RunEventsDownTime_cur  
INTO @RecordID  
  
 WHILE (@@FETCH_STATUS <> -1)  
   begin  
      Update @PaperMachInfoSum1  
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
Update @PaperMachInfoSum1  
Set  status_user_id = lsc.User_Id  
From [dbo].Local_PG_Line_Status_Comments lsc with(nolock), @PaperMachInfoSum1 p1  
Where p1.status_sched_id = lsc.status_schedule_id  
  
--Fetch the associated comment text and user name based of status schedule id.  
Update @PaperMachInfoSum1  
Set  status_comment = lsc.comment_text,  
     status_username = u.username  
from [dbo].Local_PG_Line_Status_Comments lsc with(nolock), @PaperMachInfoSum1 p1,  
      [dbo].Users u with(nolock)  
Where lsc.Status_Schedule_Id = p1.status_sched_id  
and   u.User_Id = p1.status_user_id  
and lsc.entered_on = (select max(entered_on)  
                      from  [dbo].Local_PG_Line_Status_Comments lsc with(nolock)  
                      where lsc.Status_Schedule_Id = p1.status_sched_id  
                      and   u.User_Id = p1.status_user_id   
                      and   lsc.start_datetime is not null)  
  
--Finally, combine together any like PARTS NON-RUN events. Do we really want to roll up non run events with like ERC Desc's  
--into a single downtime PARTS event? Or is it better to view them as separate events in PARTS? The answer is they have to be  
--rolled together here because on the PARTS side you will run into a Unique Key Violation in the CONV_EVENT table if you don't.  
--I also believe that we can include status_username and status_comment in the GROUP BY clause in this query because the   
--username and comment associated with the run record has already been established, hence the non run record will "inherit"  
--the line status components from the run record from which it came from and should always have the same user and comment.  
Insert Into @PaperMachInfoSum2  
select null, GCAS, Line_Status, sum(round(total_time,0)), sum(Down_Time), DT_ERC_Desc, sum(good_tons), sum(reject_tons),   
       sum(broke_tons), sum(yankee_tons), avg(yankee_speed), avg(reel_speed), avg(basis_weight),   
       avg(prod_width), sum(long_fiber_tons), sum(short_fiber_tons), sum(CTMP_tons), sum(furnish_3rd_tons),  
       sum(product_broke_tons), sum(machine_broke_tons), sum(wet_strength_tissue), sum(wet_strength_towel),  
       sum(softener_towel), sum(softener_tissue), sum(cat_promoter), sum(absorbency_aid_towel), sum(dry_strength_towel),  
       sum(dry_strength_tissue), sum(glue), sum(emulsion), sum(dry_strength_facial), sum(wet_strength_facial),  
       sum(softener_facial), status_username, status_comment  
from @PaperMachInfoSum1   
where record_id > 1000  
group by   GCAS, Line_Status, DT_ERC_Desc , status_username, status_comment  
  
--Reset the record_id because we could not use it in the group by statement above.  
Update p2  
set p2.record_id = p1.record_id  
from @PaperMachInfoSum1 p1, @PaperMachInfoSum2 p2  
where p1.DT_ERC_Desc = p2.DT_ERC_Desc  
  
--Insert all the run events recs collected from @PaperMachInfoSum1, the downtime events were   
--already added in the above statement.   
Insert Into @PaperMachInfoSum2  
Select null, GCAS, Line_Status, sum(round(total_time,0)), sum(Down_Time), DT_ERC_Desc, sum(good_tons), sum(reject_tons),   
       sum(broke_tons), sum(yankee_tons), avg(yankee_speed), avg(reel_speed), avg(basis_weight),   
       avg(prod_width), sum(long_fiber_tons), sum(short_fiber_tons), sum(CTMP_tons), sum(furnish_3rd_tons),  
       sum(product_broke_tons), sum(machine_broke_tons), sum(wet_strength_tissue), sum(wet_strength_towel),  
       sum(softener_towel), sum(softener_tissue), sum(cat_promoter), sum(absorbency_aid_towel), sum(dry_strength_towel),  
       sum(dry_strength_tissue), sum(glue), sum(emulsion), sum(dry_strength_facial), sum(wet_strength_facial),  
       sum(softener_facial), status_username, status_comment  
From @PaperMachInfoSum1 p1  
Where p1.record_id < 1000  
Group by GCAS, Line_Status, DT_ERC_Desc, status_username, status_comment  
  
--Return the data to the calling app   
ReturnPlantsAppsPmkgData:  
Select  record_id,   
        GCAS,   
        Line_Status,   
        Convert(Decimal(10,2),total_time) total_time,  
        Convert(Decimal(10,2),down_time) down_time,   
        DT_ERC_Desc,   
        Convert(Decimal(10,3),good_tons) good_tons,  
        Convert(Decimal(10,3),reject_tons) reject_tons,  
        Convert(Decimal(10,3),broke_tons) broke_tons,  
        Convert(Decimal(10,3),yankee_tons) yankee_tons,  
        yankee_speed,  
        reel_speed,   
        Convert(Decimal(10,2),basis_weight) basis_weight,  
        Convert(Decimal(10,2),prod_width) prod_width,  
        Convert(Decimal(10,3),long_fiber_tons) long_fiber_tons,  
        Convert(Decimal(10,3),short_fiber_tons) short_fiber_tons,  
        Convert(Decimal(10,3),ctmp_tons) ctmp_tons,  
        Convert(Decimal(10,3),furnish_3rd_tons) furnish_3rd_tons,  
        Convert(Decimal(10,3),product_broke_tons) product_broke_tons,  
        Convert(Decimal(10,3),machine_broke_tons) machine_broke_tons,  
        Convert(Decimal(10,2),wet_strength_tissue) wet_strength_tissue,  
        Convert(Decimal(10,2),wet_strength_towel) wet_strength_towel,  
        Convert(Decimal(10,2),softener_towel) softener_towel,  
        Convert(Decimal(10,2),softener_tissue) softener_tissue,  
        Convert(Decimal(10,2),cat_promoter) cat_promoter,  
        Convert(Decimal(10,2),absorbency_aid_towel) absorbency_aid_towel,  
        Convert(Decimal(10,2),dry_strength_towel) dry_strength_towel,  
        Convert(Decimal(10,2),dry_strength_tissue) dry_strength_tissue,  
        Convert(Decimal(10,2),glue) glue,  
        Convert(Decimal(10,2),emulsion) emulsion,          
        Convert(Decimal(10,2),dry_strength_facial) dry_strength_facial,  
        Convert(Decimal(10,2),wet_strength_facial) wet_strength_facial,  
        Convert(Decimal(10,2),softener_facial) softener_facial,  
        status_username,   
        status_comment  
From @PaperMachInfoSum2   
  
END   
  
