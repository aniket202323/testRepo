   /*    
  
-- Last Changed: 2009-02-12 Jeff Jaeger Rev1.1  
  
2009-01-22 Jeff Jaeger Rev1.0  
- initial code  
  
2009-02-12 Jeff Jaeger Rev1.1  
- made efforts to optimize the sp.  
- changed all temp tables to table variables  
- removed the index from @ActiveSpecs  
- removed the PMRollWidth variabel  
- removed intermediary code  
- changed field labels of "Hour" to "HourEnd" to be more exact about what is displayed.  
- removed the use of @Products.  since @ProductionStarts includes product info, the table   
 was redundant.  
- changed the second insert to @ProductionStarts to use a left join on @ProdUnits and then check   
 for a null puid on that table rather then doing a subquery against the table.  
- restricted the population of @tests to just the report window, and moved the result is not null  
 restriction to a where clause.  
   
  
------------------------------------------------------------------------------------------------------------------  
  
  
Efficiency enhancements in the inserts to #Tests and @ActiveSpecs can be used in other reports.  
  
  
------------------------------------------------------------------------------------------------------------------  
----------------------------------------------------------------------------------------------------------  
*/  
  
  
CREATE PROCEDURE dbo.spLocal_RptLineDisplayPR  
--declare  
 @Line  varchar(100)  
  
AS  
  
  
-------------------------------------------------------------------------------  
-- Control settings  
-------------------------------------------------------------------------------  
SET ANSI_WARNINGS OFF  
SET NOCOUNT ON  
  
  
-------------------------------------------------------------------------------  
-- Declare testing parameters.  
-------------------------------------------------------------------------------  
  
/* --- testing  
  
select  
@Line = 'ALL'  
--@Line =   
-- 'FFF7' -- 'FK68' -- 'FFF1' -- 'FTL4' -- GB   
-- 'OKK1' -- 'OTT1' -- OX  
-- 'MT65' -- 'MNN3' --  'MK70' -- MP  
-- 'GT01' -- 'GK21' -- Cape  
-- 'AK01' -- 'AC1' -- 'AT05' -- AY  
-- 'AZAL' -- AZ  
  
*/  
  
  
-------------------------------------------------------------------------  
-- Report Parameters. 2005-03-16 VMK Rev8.81  
-------------------------------------------------------------------------  
DECLARE   
@SchedBlockedStarvedId  INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Blocked/Starved.  
@SchedHolidayCurtailId  INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Holiday/Curtail.  
  
  
------------------------------------------  
-- declare program variables  
------------------------------------------  
@ScheduleStr     VARCHAR(50),  -- Prefix FROM Event_Reason_Categories.ERC_Desc (portion prior to ":").  
  
@PacksInBundleSpecDesc  VARCHAR(100),  
@SheetCountSpecDesc   VARCHAR(100),  
@CartonsInCaseSpecDesc  VARCHAR(100),  
@ShipUnitSpecDesc    VARCHAR(100),  
@StatFactorSpecDesc   VARCHAR(100),  
@RollsInPackSpecDesc   VARCHAR(100),  
@SheetWidthSpecDesc   VARCHAR(100),  
@SheetLengthSpecDesc   VARCHAR(100),  
  
@PackOrLineStr     varchar(50),  
@VarGoodUnitsVN    varchar(50),  
--@VarPMRollWidthVN    varchar(50),  
@VarParentRollWidthVN   varchar(50),  
@VarActualLineSpeedVN   varchar(50),  
@VarLineSpeedVN    varchar(50),  
@VarLineSpeedMMinVN   varchar(50),   
@Line_ProdFactorDesc   varchar(50),  
  
@PUDelayTypeStr    VARCHAR(100),  
  
@VarTypeStr      VARCHAR(50),  
@ACPUnitsFlag     VARCHAR(50),  
@HPUnitsFlag     VARCHAR(50),  
@TPUnitsFlag     VARCHAR(50),  
  
@LineSpeedTargetSpecDesc  varchar(50),  
  
@StartTime      datetime,  
@EndTime       datetime,  
@ShiftStart      datetime,  
  
@HourStart      datetime,  
@HourEnd       datetime,  
  
@Plant       varchar(25)  
  
  
--------------------------------------------------------------  
-- Section 4: Assign constant values  
--------------------------------------------------------------  
--print 'assign sp variables' + ' ' + convert(varchar(25),current_timestamp,108)  
  
select  
@ScheduleStr    = 'Schedule',  
@SchedBlockedStarvedId = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Blocked/Starved'),  
@SchedHolidayCurtailId = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Holiday/Curtail'),  
  
@PackOrLineStr    = 'PackOrLine=',  
@VarGoodUnitsVN   = 'Good Units',  
--@VarPMRollWidthVN   = 'PM Roll Width',  
@VarParentRollWidthVN  = 'Parent Roll Width',  
@VarActualLineSpeedVN  = 'Line Actual Speed',  
@VarLineSpeedVN   = 'Reports Line Speed',  
@VarLineSpeedMMinVN  = 'Reports Line Speed (m/min)',    
@Line_ProdFactorDesc  = 'Production Factors',  
  
@PUDelayTypeStr    = 'DelayType=',  
    
@VarTypeStr     = 'VarType=',  
@ACPUnitsFlag    = 'ACPUnits',  
@HPUnitsFlag    = 'HPUnits',  
@TPUnitsFlag    = 'TPUnits',  
  
@StatFactorSpecDesc   = 'Stat Factor',  
@PacksInBundleSpecDesc  = 'Packs In Bundle',   
@SheetCountSpecDesc   = 'Sheet Count',  
@SheetWidthSpecDesc   = 'Sheet Width',  
@SheetLengthSpecDesc  = 'Sheet Length',  
@ShipUnitSpecDesc   = 'Ship Unit',  
@LineSpeedTargetSpecDesc  = 'Line Speed Target'  
  
  
-- get the date range for the report  
  
select @EndTime = convert(varchar,getdate(),120)  
  
/*  testing  
select @EndTime = '2008-12-25 12:20:44'  
*/  
  
select @ShiftStart =   
 (  
 select top 1   
  start_time   
 from crew_schedule   
 where start_time < @EndTime   
 and end_time >= @endtime  
 )  
  
  
if upper(@Line) = 'ALL'  
begin  
  
select @StartTime = @ShiftStart  
  
end  
else  
begin  
  
select @StartTime =   
 convert (datetime,  
    convert (varchar(25),@EndTime,101) + ' ' +   
     convert(varchar,datepart(hh,@EndTime)) + ':' +  
     convert(varchar,datepart(mi,@ShiftStart)) + ':' +  
     convert(varchar,datepart(ss,@ShiftStart))  
    )  
  
if @StartTime > @EndTime  
select @StartTime = dateadd(hh,-1,@StartTime)  
    
select @StartTime = dateadd(hh,-12,@StartTime)  
  
end  
  
  
----------------------------------------------------------------------------------  
  
--print 'create tables' + ' ' + convert(varchar(25),current_timestamp,108)  
-----------------------------------------------------------------------  
-- this table will hold Prod Units data for Converting lines  
-----------------------------------------------------------------------  
  
DECLARE @ProdUnits TABLE   
 (  
 PUId             INTEGER PRIMARY KEY,  
 PUDesc            VARCHAR(100),  
 CombinedPUDesc          VARCHAR(100),  
 PLId             INTEGER,  
 ExtendedInfo          VARCHAR(255),  
 DelayType           VARCHAR(100),  
 ScheduleUnit          INTEGER,  
 PRIDRLVarId           INTEGER,  
 RowId             INTEGER IDENTITY  
 )  
  
  
-------------------------------------------------------------------  
-- This table will hold production variable ID data for each Line  
------------------------------------------------------------------  
  
DECLARE @LineProdVars TABLE   
 (  
 PLId             INTEGER,  
 PUId             INTEGER,  
 VarId             INTEGER,  
 VarType            VARCHAR(25)  
 PRIMARY KEY (plid, varid)  
 )  
  
  
----------------------------------------------------------------------  
-- @RunSummary will summarize the data from @Runs  
-- the dimensions in this table need to be the same as in @Runs  
----------------------------------------------------------------------  
  
DECLARE @RunSummary TABLE   
 (  
 [HourEnd]           datetime,  
 PLId             INTEGER,   
 PUId             INTEGER,  
 Shift             INTEGER,  
 Team             VARCHAR(10),  
 ProdId            INTEGER,  
 TargetSpeed           float,  
 IdealSpeed           float,  
 -- add any additional dimensions that are required  
 StartTime           DATETIME,  
 EndTime            DATETIME,  
 Runtime            FLOAT   
 primary key (puid, starttime)  
 )  
  
  
-------------------------------------------------------------------------------  
--  this table will hold production summaries by shift, team, and product.  
-- this information will later be used to split the downtime events.  
-------------------------------------------------------------------------------  
  
DECLARE @ProdRecords TABLE    
 (  
 [ID]             int identity,  
 [HourEnd]           datetime,  
 PLId             INTEGER,  
 puid             integer,  
 ReliabilityPUID         int,  
 ProdId            INTEGER,  
 StartTime           DATETIME,  
 EndTime            DATETIME,  
 GoodUnits           float, --INTEGER, -- Rev11.31  
 WebWidth            FLOAT,  
 SheetWidth           FLOAT,  
 LineSpeedTarget         FLOAT,  
 RollsPerLog           float, --INTEGER, -- Rev11.31  
 RollsInPack           float, --INTEGER, -- Rev11.31  
 PacksInBundle          float, --INTEGER, -- Rev11.31  
 CartonsInCase          float, --INTEGER, -- Rev11.31  
 SheetCount           float, --INTEGER, -- Rev11.31  
 CalendarRuntime         FLOAT,  
 ProductionRuntime         FLOAT,  
 SheetLength           FLOAT,  
 StatFactor           FLOAT,  
 TargetUnits           float, --INTEGER, -- Rev11.31  
 ActualUnits           float, --INTEGER, -- Rev11.31  
 HolidayCurtailDT         FLOAT,  
 RollWidth2Stage         float,  
 RollWidth3Stage         float,  
 CnvtLineSpeedToSheetLength      FLOAT,  
 CnvtParentRollWidthToSheetWidth    FLOAT,  
 DefaultPMRollWidth        FLOAT,  
 LineSpeedUOM         varchar(10),  
 SheetLengthUOM         varchar(10),  
 SheetWidthUOM         varchar(10)--,  
 primary key (puid, starttime) --team, shift, prodid, starttime)  
 )  
  
  
---------------------------------------------------------------  
-- @ProductionStarts will hold the Production Starts information  
-- along with related product information  
---------------------------------------------------------------  
  
declare @ProductionStarts table  
 (  
 Start_Time           datetime,  
 End_Time            datetime,  
 Prod_ID            int,  
 Prod_Code           varchar(50),  
 Prod_Desc           varchar(50),  
 PU_ID             int--,  
 primary key (pu_id, prod_id, start_time)  
 )  
  
  
/*  
------------------------------------------------------------------  
-- @Products will hold product information, as derived from  
-- @ProductionStarts  
-------------------------------------------------------------------  
  
declare @Products table  
 (  
 Prod_ID            int primary key,  
 Prod_Code           varchar(50),  
 Prod_Desc           varchar(50)--,  
 )  
*/  
  
  
---------------------------------------------------------------------------  
-- this table will hold active specification information, as related to  
-- characteristics, specifications, and properties.  
----------------------------------------------------------------------------  
  
declare @ActiveSpecs table  
 (  
 effective_date          DATETIME,  
 expiration_date         datetime,  
 prod_id            int,   
 char_id            int,  
 char_desc           varchar(50),  
 spec_id            int,  
 spec_desc           varchar(50),  
 prop_id            int,  
 prop_desc           varchar(50),  
 target            varchar(50),  
 eng_units           varchar(10)  
-- primary key (prod_id, effective_date, expiration_date, char_id, spec_id, prop_id)  
 )  
  
  
------------------------------------------------------------------  
-- This table will hold the category information based on the   
-- values specific specific to each location.  
------------------------------------------------------------------  
  
-- Rev11.31  
declare @VariableList table   
 (  
 Var_Id           int primary key,  
 var_desc     varchar(50),  
 pl_id      int,  
 pu_id      int,  
 eng_units    varchar(50),  
 extended_info   varchar(200)   
 )  
  
  
----------------------------------------------------------------------------------  
-- @runs will be the final production runs, as split by the dimensions  
----------------------------------------------------------------------------------  
  
--Rev11.55  
declare @runs table  
(  
 [HourEnd]            datetime,  
 PLID             integer,  
 PUID             integer,  
 Shift             varchar(10),   
 Team             varchar(10),   
 ShiftStart           datetime,  
 ProdId            integer,  
 TargetSpeed           float,  
 IdealSpeed           float,  
 -- add any additional dimensions that are required  
 StartTime           datetime,  
 EndTime            datetime  
 primary key (puid, starttime)   
)  
  
  
-- Rev11.33  
--create table #ProdLines  
declare @ProdLines table  
 (  
 PLId             int primary key,  
 PLDesc            VARCHAR(50),  
 deptid            int,  
 ProdPUID            integer,  
 ReliabilityPUID         integer,  
 RatelossPUID          integer,  
 RollsPUID           int,  
-- CvtrBlockedStarvedPUID       int,  
 PackOrLine           varchar(5),  
 VarGoodUnitsId          INTEGER,  
-- VarPMRollWidthId         INTEGER,  
-- PMRollWidthUOM          varchar(10),  
 VarParentRollWidthId        INTEGER,  
 ParentRollWidthUOM        varchar(10),  
 VarActualLineSpeedId        INTEGER,  
 VarLineSpeedId          INTEGER,  
 Extended_Info          varchar(225),  
 BusinessTypeID          int,  
 Cvtg_ProdFactorID         int,  
 Line_ProdFactorID         INTEGER,  
 CartonsInCaseSpecDesc       varchar(100),  
 RollsInPackSpecDesc        varchar(100),  
 PPTT             varchar(20)  
 )  
  
declare @OrgHierarchy table   
 (  
 DeptID      int,  
 DeptDesc      varchar(100),  
 Category      varchar(100),  
 BusinessTypeID    int,  
 PLID       int primary key,  
 ExtendedInfo    varchar(225)  
 )  
  
/*  
declare @Stages table  
 (  
 puid       int,  
 starttime     datetime,  
 stage2     float,  
 stage3     float  
 primary key (puid, starttime)  
 )  
*/  
  
  
--CREATE TABLE dbo.#LineDisplayResults   
declare @LineDisplayResults table   
 (   
 [Line]            VARCHAR(50),  
 [HourEnd]            datetime,  
 [ActualUnits]          float,  
 [TargetUnits]          float--,  
 primary key (Line, [HourEnd])  
 )  
  
  
declare @LineDisplaySummary table   
 (   
 [Line]            VARCHAR(50) primary key,  
 [ShiftCurrent]          float,  
 [Hour1]            float,  
 [Hour2]            float,  
 [Hour3]            float,  
 [Hour4]            float,  
 [Hour5]            float,  
 [Hour6]            float,  
 [Hour7]            float,  
 [Hour8]            float,  
 [Hour9]            float,  
 [Hour10]            float,  
 [Hour11]            float,  
 [Hour12]            float  
 )  
  
  
--Rev11.55  
--create table dbo.#Dimensions   
declare @Dimensions table  
 (  
 Dimension     varchar(50),  
 Value       varchar(50),  
 StartTime     datetime,  
 EndTime      datetime,  
 PLID       int,  
 PUID       int  
-- primary key (dimension, puid, starttime)  
 )  
  
  
------------------------------------------------------------------------  
-- This table will hold test related information for cvtg and rate loss  
-----------------------------------------------------------------------  
  
--CREATE TABLE dbo.#Tests   
declare @Tests table   
 (  
 VarId             INTEGER,  
 PLId             INTEGER,  
 PUId             INTEGER,  
 ProdId            INTEGER,  
 ProdCode            VARCHAR(25),  
 Value             varchar(50),  
 SheetValue           varchar(100),  
 SampleTime           DATETIME,  
 UOM             varchar(50)--,  
 primary key (puid, sampletime, varid)  
 )  
  
  
-----------------------------------------------------------  
  
------------------------------------------------  
------------------------------------------------  
--print 'OrgHierarchy' + ' ' + convert(varchar(25),current_timestamp,108)  
  
    INSERT INTO @OrgHierarchy  
     (  
     deptid,  
     deptdesc,  
     category,  
     plid,  
     extENDedinfo  
     )  
    SELECT    
     d.dept_id,  
     dept_desc_global,  
     dbo.fnLocal_GlblParseInfoWithSpaces(COALESCE(d.ExtENDed_Info,'Category= ;'), 'Category='),    
     pl.pl_id,  
     d.extENDed_info  
    FROM dbo.departments d WITH(NOLOCK)  
    JOIN dbo.prod_lines pl WITH(NOLOCK) ON d.dept_id = pl.dept_id  
    WHERE dept_desc_global like 'Cvtg%'  
  
  
--print 'update OrgHierarchy' + ' ' + convert(varchar(25),current_timestamp,108)  
  
update @OrgHierarchy set  
 BusinessTypeID =  
  case  
  when  deptdesc = 'Cvtg Napkins'  
  then 2  
  when  deptdesc = 'Cvtg Facial'  
  then 3  
  when  deptdesc = 'Cvtg Hanky'  
  then 4  
--  default  deptdesc = 'Converting Tissue'  
--  or   deptdesc = 'Converting Towel'  
  else 1  
  end--,  
  
  
--print 'Section 10 Get info about Prod Lines: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
------------------------------------------------------------  
-- Section 10: Get information about the production lines  
------------------------------------------------------------  
  
-- pull in prod lines that have an ID in the list  
insert @ProdLines -- Rev11.33   
 (  
 PLID,   
 PLDesc,  
 DeptID,  
 BusinessTypeID,  
 Extended_Info)  
select   
 PL_ID,   
 PL_Desc,  
 Dept_ID,  
 BusinessTypeID,  
 Extended_Info  
from dbo.prod_lines pl with (nolock)  
join @OrgHierarchy d   
on d.plid = pl.pl_id  
where upper(@Line) = 'ALL'  
or @Line =  
-- (  
 case  
 when pl.pl_desc like 'TT %'  
 or pl.pl_desc like 'PP %'  
 then right(pl.pl_desc, len(pl.pl_desc) -3)  
 else pl.pl_desc  
 end  
-- )  
option (keep plan)  
  
  
--print 'trim PLDesc' + ' ' + convert(varchar(25),current_timestamp,108)  
update pl set  
 pldesc = right(pldesc, len(pldesc) -3)  
from @prodlines pl  
where pl.pldesc like 'TT %'  
or pl.pldesc like 'PP %'  
  
  
--print 'Line Specs' + ' ' + convert(varchar(25),current_timestamp,108)  
  
update @ProdLines set  
 PackOrLine = 'PMKG',  
 CartonsInCaseSpecDesc =  
  CASE   
  WHEN BusinessTypeID = 4   
  THEN 'Bundles In Case'   
  ELSE 'Cartons In Bundle'   
  END,  
  
 RollsInPackSpecDesc =    
  CASE BusinessTypeID  
  WHEN 1   
  THEN 'Rolls In Pack'  
  WHEN 2   
  THEN 'Packs In Pack'  
  WHEN 3   
  THEN 'Rolls In Pack'  
  ELSE 'Rolls In Pack'   
  END,  
  
 PPTT =   
  case   
  when BusinessTypeID = 3  
  then 'PP '  
  else 'TT '  
  end  
  
  
--print 'Line Factor ID' + ' ' + convert(varchar(25),current_timestamp,108)  
  
update pl set  
--factor  
 Cvtg_ProdFactorID =  
  case   
  when pl.PLDesc like 'AC1%'  
  then (select prop_id from dbo.product_properties with (nolock) where prop_desc = 'Finished Goods Production Factors')  
  else (select prop_id from dbo.product_properties with (nolock) where prop_desc = deptdesc + ' Prod Factors')  
  end  
from @ProdLines pl   
join @OrgHierarchy d   
on d.deptid = pl.deptid  
  
  
--print 'misc Line updates' + ' ' + convert(varchar(25),current_timestamp,108)  
  
-- PackOrLine is used for grouping in the result sets and to restrict data in some where clauses  
update pl set  
 PackOrLine = GBDB.dbo.fnLocal_GlblParseInfo(pl.Extended_Info, @PackOrLineStr)  
from @ProdLines pl   
  
  
-- get the ID of the Converter Production unit associated with each line.  
update pl set  
 ProdPUID = pu_id  
from @ProdLines pl   
join dbo.Prod_Units pu with (nolock)  
on pl.plid = pu.pl_id  
where pu_desc like '%Converter Production%'  
  
  
-- get the ID of the Converter Reliability unit associated with each line.  
update pl set  
 ReliabilityPUID = pu_id  
from @ProdLines pl   
join dbo.Prod_Units pu with (nolock)  
on pl.plid = pu.pl_id  
where pu_desc like '%Converter Reliability%'  
  
  
-- get the ID of the Rate Loss unit associated with each line.  
update pl set  
 RatelossPUID = pu_id  
from @ProdLines pl   
join dbo.Prod_Units pu with (nolock)  
on pl.plid = pu.pl_id  
where pu_desc like '%Rate Loss%'  
  
  
--update pl set  
-- CvtrBlockedStarvedPUId = pu.PU_Id  
--from @ProdLines pl  
--join dbo.Prod_Units pu with (nolock)  
--on pl.plid = pu.pl_id  
--AND pu.PU_Desc LIKE '% Converter Blocked/Starved%'  
  
  
-- get the Line Prod Factor  
--factor  
update @ProdLines set   
 Line_ProdFactorID = Prop_Id  
FROM dbo.Product_Properties with (nolock)  
WHERE Prop_Desc = ltrim(rtrim(replace(PLDesc,PPTT,''))) + ' ' + @Line_ProdFactorDesc  
  
  
-- get the following variable IDs associated with the line  
update pl set  
 VarGoodUnitsId    = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarGoodUnitsVN),  
-- VarPMRollWidthId    = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarPMRollWidthVN),  
 VarParentRollWidthId  = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarParentRollWidthVN),  
 VarActualLineSpeedId  = GBDB.dbo.fnLocal_GlblGetVarId(RateLossPUId,  @VarActualLineSpeedVN),  
 VarLineSpeedId    =   
         coalesce(  
            GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,@VarLinespeedMMinVN),  
            GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,@VarLinespeedVN)  
            )  
from @ProdLines pl   
where PackOrLine = 'Line'  
  
  
-- get the Line Prod Factor  
--update @ProdLines set   
-- Line_ProdFactorID = Prop_Id  
--FROM dbo.Product_Properties with (nolock)  
--WHERE Prop_Desc = ltrim(rtrim(replace(PLDesc,PPTT,''))) + ' ' + @Line_ProdFactorDesc  
  
   
--print 'Section 12 @ProdUnits: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- Section 12: Get information for ProdUnitList  
-------------------------------------------------------------------------------  
  
-- note that some values are parsed from the extended_info field  
INSERT @ProdUnits   
 (   
 PUId,  
 PUDesc,  
 PLId,  
 ExtendedInfo,  
 DelayType--,  
 )  
SELECT pu.PU_Id,  
 pu.PU_Desc,  
 pu.PL_Id,  
 pu.Extended_Info,  
 GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PUDelayTypeStr)--,  
FROM dbo.Prod_Units pu with (nolock)  
JOIN @ProdLines tpl   
ON pu.PL_Id = tpl.PLId  
and pu.Master_Unit is null  
JOIN dbo.Event_Configuration ec with (nolock)  
ON pu.PU_Id = ec.PU_Id  
AND ec.ET_Id = 2  
where charindex(@PUDelayTypeStr,pu.extended_info) > 0  
and (pu_desc not like '%block%starv%' or pu_desc like '%Converter Blocked/Starved')  
option (keep plan)  
  
delete @ProdUnits  
where DelayType like 'NotUsed'  
  
  
--print 'Section 21 @LineProdVars: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- Section 21: Get Line Production Variables     
-------------------------------------------------------------------------------  
  
--IF @BusinessType IN (3, 4) -- Facial/Hanky  
if (select max(BusinessTypeID) from @ProdLines) > 2  
  
 -- Facial/Hanky bases its production off a dedicated pack line so we're going to find  
 -- the pack line associated with this production line and gather all the necessary info FROM it  
 -- We're also going to filter by the argument pack pu list for consistency  
  
--/*  
 INSERT INTO @LineProdVars  
  (   
  PLId,  
  PUId,  
  VarId,  
  VarType  
  )  
 SELECT    
  pl.PL_Id,  
  v.PU_Id,  
  v.Var_Id,  
  dbo.fnLocal_GlblParseInfo(v.Extended_Info, @VarTypeStr)  
 from dbo.variables v with (nolock)  
 join dbo.prod_units pu with (nolock)  
 on v.pu_id = pu.pu_id  
 join dbo.prod_lines plPack with (nolock)  
 on pu.pl_id = plPack.pl_id  
 join dbo.prod_lines pl with (nolock)  
 ON LTRIM(RTRIM(REPLACE(plPack.Pl_Desc, ' ', ''))) = LTRIM(RTRIM(REPLACE(pl.PL_Desc, ' ', ''))) + 'PACK'  
 join @prodlines plRestrict  
 on plRestrict.plid = pl.pl_id  
 where v.extended_info like '%VarType=%'  
 option (keep plan)  
  
--*/  
  
-- Rev11.31  
-------------------------------------------------------------------------------------  
-- Section 11: Populate @VariableList  
-------------------------------------------------------------------------------------  
--print 'variablelist' + ' ' + convert(varchar(25),current_timestamp,108)  
  
Insert Into @variablelist (Var_Id, PL_ID)   
Select distinct VarGoodUnitsId, PLID  
From @ProdLines   
where VarGoodUnitsId is not null  
  
--Insert Into @variablelist (Var_Id, PL_ID)   
--Select distinct VarPMRollWidthId, PLID  
--From @ProdLines   
--where VarPMRollWidthId is not null  
  
Insert Into @variablelist (Var_Id, PL_ID)   
Select distinct VarParentRollWidthId, PLID  
From @ProdLines   
where VarParentRollWidthId is not null  
  
Insert Into @variablelist (Var_Id, PL_ID)   
Select distinct VarActualLineSpeedId, PLID  
From @ProdLines   
where VarActualLineSpeedId is not null  
  
Insert Into @variablelist (Var_Id, PL_ID)   
Select distinct VarLineSpeedId, PLID  
From @ProdLines   
where VarLineSpeedId is not null  
  
Insert Into @variablelist (Var_Id, PL_ID)   
Select distinct VarId, PLID  
From @LineProdVars  
where VarID is not null  
  
  
-- Rev11.31  
update vl set  
 var_desc   = v.var_desc,  
 pu_id    = v.pu_id,  
 eng_units  = upper(v.eng_units),  
 extended_info = v.extended_info  
from @variablelist vl  
join dbo.variables v with (nolock)  
on vl.var_id = v.var_id  
join dbo.prod_units pu with (nolock)  
on v.pu_id = pu.pu_id    
  
update pl set  
-- PMRollWidthUOM   = (select eng_units from @variablelist where var_id = VarPMRollWidthID),  
 ParentRollWidthUOM = (select eng_units from @variablelist where var_id = VarParentRollWidthID)  
from @prodlines pl   
  
  
--print 'Section 18 @ProductionStarts: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- Section 18: Get Production Starts  
-------------------------------------------------------------------------------  
  
insert @ProductionStarts   
 (  
 Start_Time,  
 End_Time,  
 Prod_ID,  
 Prod_Code,  
 Prod_Desc,  
 PU_ID  
 )  
select ps.start_time,  
 ps.end_time,  
 ps.prod_id,  
 p.prod_code,  
 p.prod_desc,  
 ps.pu_id  
from dbo.production_starts ps with (nolock)  
join dbo.products p with (nolock)  
on ps.prod_id = p.prod_id  
join @produnits pu  
on pu.puid = ps.pu_id   
where ps.start_time < @endtime  
and (ps.end_time > @starttime or ps.end_time is null)  
--AND p.Prod_Desc <> 'No Grade'   
option (keep plan)  
  
  
--/*  
-- 2006-07-19   
insert @ProductionStarts   
 (  
 Start_Time,  
 End_Time,  
 Prod_ID,  
 Prod_Code,  
 Prod_Desc,  
 PU_ID  
 )  
select   
 ps.start_time,  
 ps.end_time,  
 ps.prod_id,  
 p.prod_code,  
 p.prod_desc,  
 ps.pu_id  
from dbo.production_starts ps with (nolock)  
join dbo.products p with (nolock)  
on ps.prod_id = p.prod_id  
join dbo.prod_units pu with (nolock)  
on pu.pu_id = ps.pu_id  
join @prodlines plPack  
on pu.pl_id = plPack.plid  
join @prodlines pl  
ON pl.PackOrLine = 'Line' -- Rev11.33  
AND LTRIM(RTRIM(REPLACE(plPack.PlDesc, ' ', ''))) = LTRIM(RTRIM(REPLACE(pl.PLDesc, ' ', ''))) + 'PACK'  
left join @produnits tpu  
on pu.pu_id = tpu.puid  
where ps.start_time < @endtime  
and (ps.end_time > @starttime or ps.end_time is null)  
--and pu.pu_id not in (select puid from @produnits)  
and tpu.puid is null  
option (keep plan)  
--*/  
  
  
--print 'Get Tests: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-- testing  
  
 INSERT @Tests   
  (  
  VarId,  
  PLId,  
  PUID,  
  Value,  
  SampleTime--,  
  )  
 SELECT  
  distinct   
  t.Var_Id,  
  v1.PL_Id,  
  v1.pu_id,  
  t.Result,     
  t.Result_On  
 from dbo.tests t with (nolock)  
 join @variablelist v1  
 on t.var_id = v1.var_id   
 AND t.result_on >= @StartTime  
 and t.result_on <= @EndTime  
-- testing  
-- AND t.result_on >= dateadd(d, -1, @StartTime)  
 where t.result is not null  
-- join @ProdLines pl   
-- on pl.plid = v1.pl_id  
  
--option (maxdop 1)  
  
 delete @tests  
 where VarId in (select VarLineSpeedId from @prodlines) and convert(float,value) = 0.0  
  
  
-- testing  
  
 update t set  
  puid   = ps.pu_id,  
  prodid  = ps.Prod_Id,  
  prodcode = ps.Prod_Code  
 from @productionstarts ps --with (nolock)  
 JOIN @tests t --with (nolock)  
 ON ps.pu_id = t.puid   
-- JOIN @Products p --with (nolock)  
-- JOIN @ProductionStarts p --with (nolock)  
-- on ps.prod_id = p.prod_id  
 where ps.Start_Time <= t.SampleTime  
 AND (ps.End_Time > t.SampleTime or ps.end_time is null)  
 option (maxdop 1)  
  
  
/*  
--print 'Section 19 @Products: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-----------------------------------------------------------------------------  
-- Section 19: Get Products  
-----------------------------------------------------------------------------  
  
insert @products  
 (  
 prod_id,  
 prod_code,  
 prod_desc  
 )  
select distinct  
 prod_id,  
 prod_code,  
 prod_desc  
from @productionstarts   
order by prod_id  
option (keep plan)  
*/  
  
  
--print 'Section 20 @ActiveSpecs: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
------------------------------------------------------------------  
-- Section 20: Get Active Specs  
------------------------------------------------------------------  
  
insert @activespecs  
 (  
 effective_date,  
 expiration_date,  
 prod_id,  
 spec_id,  
 spec_desc,  
 char_id,  
 char_desc,  
 prop_id,  
 prop_desc,  
 target,  
 eng_units  
 )  
select distinct  
 asp.effective_date,  
 coalesce(asp.expiration_date,@endtime),  
 p.prod_id,  
 s.spec_id,  
 s.spec_desc,  
 c.char_id,  
 c.char_desc,  
 pp.prop_id,  
 pp.prop_desc,  
 asp.target,  
 upper(s.eng_units)  
from dbo.active_specs asp with (nolock)  
join dbo.specifications s with (nolock)  
on s.spec_id = asp.spec_id  
join dbo.characteristics c with (nolock)  
on c.char_id = asp.char_id   
join dbo.product_properties pp with (nolock)  
on s.prop_id = pp.prop_id  
--join @products p   
join @ProductionStarts p   
on c.char_desc = prod_code  
join @prodlines pl   
on (pp.prop_id = pl.cvtg_prodfactorid or pp.prop_id = pl.Line_ProdFactorId)  
where asp.effective_date < @EndTime  
and (asp.expiration_date > @StartTime or asp.expiration_date is null)  
AND ISNUMERIC(asp.target)=1   --When a spec is deleted, Proficy puts '<Deleted>' in front of the value.    
  
option (maxdop 1)  
  
  
------------------------------------------------------------------------------------------------------------  
--print 'Section 22 Dimensions: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
--------------------------------------------------------------------  
-- Section 22: Get the dimensions to be used  
--------------------------------------------------------------------  
  
/*--------------------------------------------------------------------------------------  
  
Overview:  
  
Think of the time on a production unit as a constant timeline that is broken up by changes of   
various types (called dimensions).  Examples would be a change in Product being made, the Team   
working, the Shift working, the Target Speed of the line, the Line Status, etc.  Whenever   
the value of ANY dimension changes, there is a break in the timeline.    
  
NOTE that "dimension" is a term taken from data warehousing, and is used in a similar way.  
  
  
@Dimensions:  
  
The @Dimensions table tracks the different dimensions by which we want to split    
the timeline.  The table tracks each type of Dimension (in this case, ProdID, Team,   
Shift, TargetSpeed, and LineStatus, although more can be easily added, as needed),   
along with the different possible values associated with those dimensions (meaning only those   
values that actually occur within the report window), as well as the start and end time that   
each dimensional value comes into affect.    
  
If a new dimension is added to the table, it may need to be added to the indices of some result sets.  
Also, new dimensions may need to be added to @ProdRecords, and #SplitUptime.   
  
@Runs:  
  
If the starttimes of ALL the dimensional values for a given prod unit are laid out,   
in chronilogical order,  what we have are different segments of the timeline on that   
prod unit, each having a value for the different dimensions being tracked.  The @runs   
table will hold the start and end time of each segment, along with information about   
the dimensional values for each segment.    
  
----------------------------------------------------------------------------------*/  
  
------------------------------------------------------------  
-- add the Hour dimension  
------------------------------------------------------------  
--print 'Hour dim' + ' ' + convert(varchar(25),current_timestamp,108)  
  
select @HourStart = @StartTime  
select @HourEnd = dateadd(hh,1,@StartTime)  
  
while @HourStart < @EndTime  
begin  
  
insert @Dimensions   
 (  
 Dimension,  
 Value,  
 Starttime,  
 EndTime,  
 PLID,  
 PUID  
 )  
SELECT distinct   
 'HourEnd',  
 convert(varchar,@HourEnd,120),  
 @HourStart,  
 @HourEnd,  
 pu.PLID,  
 pu.PUId  
FROM @ProdUnits pu   
ORDER BY pu.PUId  
option (keep plan)  
  
select @HourStart = @HourEnd  
select @HourEnd = dateadd(hh,1,@HourEnd)  
  
if @HourEnd > @EndTime  
select @HourEnd = @EndTime  
  
end -- while  
  
  
--print 'ProdID dim' + ' ' + convert(varchar(25),current_timestamp,108)  
  
insert @Dimensions   
 (  
 Dimension,  
 Value,  
 Starttime,  
 EndTime,  
 PLID,  
 PUID  
 )  
SELECT distinct   
 'ProdID',  
 ps.Prod_Id,  
 ps.Start_Time,  
 ps.End_Time,  
 pu.PLID,  
 ps.PU_Id  
FROM @ProductionStarts ps  
JOIN @ProdUnits pu ON ps.PU_Id = pu.PUId  
ORDER BY ps.start_time, ps.PU_Id  
option (keep plan)  
  
  
--print 'tgt speed dim' + ' ' + convert(varchar(25),current_timestamp,108)  
  
-- add target speed  
insert @Dimensions  
 (  
 Dimension,  
 Value,  
 Starttime,  
 EndTime,  
 PLID,  
 PUID  
 )  
select  distinct  
 'TargetSpeed',  
 asp.target,   
 asp.effective_date,  
 asp.expiration_date,  
 pl.plid,  
 ps.pu_id  
from @activespecs asp  
join @productionstarts ps  
on ps.prod_id = asp.prod_id  
join @produnits pu   
on ps.pu_id = pu.puid   
join @prodlines pl   
on pu.plid = pl.plid  
and asp.prop_id = pl.Line_ProdFactorId  
where asp.spec_desc = @LineSpeedTargetSpecDesc   
and pu.pudesc like  '%Converter Reliability%'  
and asp.prop_desc = ltrim(rtrim(replace(PLDesc,PPTT,''))) + ' ' + @Line_ProdFactorDesc  
option (keep plan)  
  
  
-------------------------------------------------------------------------------------------  
-- limit the starttime and endtime of @Dimensions to the report window start and end time  
-------------------------------------------------------------------------------------------  
--print 'update dim times' + ' ' + convert(varchar(25),current_timestamp,108)  
  
update @Dimensions set  
 starttime = @StartTime  
where starttime < @StartTime  
  
update @Dimensions set  
 endtime = @EndTime  
where endtime > @EndTime   
or endtime is null  
  
  
--print 'Section 23 run times, values for dimensions: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------  
-- Section 23: Get the run times and values for each dimension  
-------------------------------------------------------------  
  
-------------------------------------------------------------  
-- create the intial time periods of the production runs.  
-- the runtime needs to be laid out as a series of changes...  
-- initially, we don't care WHY the change takes place (meaning   
-- which dimension is undergoing the change).  We just need   
-- to lay the times of these changes out into a straight line.  
-- for this purpose, we only care about the start times.  
-------------------------------------------------------------  
  
-- 2007-04-11 VMK Rev11.37, Insert PEIId with PLId and PUId.  
insert @runs  
 (  
 PLID,  
 PUID,  
 StartTime )  
select  distinct  
 PLID,  
 puid,  
 starttime  
from @Dimensions   
group by plid, puid, starttime  
order by puid, StartTime      
option (keep plan)  
  
--------------------------------------------------------------------  
-- once we know what time each new time split started, we can   
-- determine the endtime by simply looking at the NEXT start time  
-- in the line.  
--------------------------------------------------------------------  
  
update r1 set  
 endtime =   
  (  
  select top 1 starttime  
  from @runs r2  
  where r1.puid = r2.puid  
  and r1.starttime < r2.starttime  
  )  
from @runs r1  
  
update @runs set  
 endtime = @endtime  
where endtime is null  
    
  
-------------------------------------------------------  
-- now that we know where the time splits are, we need  
-- to determine what the dimensional values are in   
-- each time segment. this requires an update for each   
-- dimension.  
------------------------------------------------------  
--print 'misc run updates' + ' ' + convert(varchar(25),current_timestamp,108)  
  
-- get the Hour  
  
update r set  
 [HourEnd] =   
  (  
  select value  
  from @Dimensions d   
  where d.puid = r.puid  
  and d.starttime < r.endtime  
  and (d.endtime > r.starttime or d.endtime is null)  
  and Dimension = 'HourEnd'  
  )  
from @runs r  
  
  
-- get the ProdID   
  
update r set  
 ProdID =   
  (  
  select value  
  from @Dimensions d --with (nolock)  
  where d.puid = r.puid  
  and d.starttime < r.endtime  
  and (d.endtime > r.starttime or d.endtime is null)  
  and Dimension = 'ProdID'  
  )  
from @runs r  
  
  
-- get the target speed  
  
update r set  
 targetspeed =  
 (  
 select top 1   
 target  
 from @activespecs asp  
 WHERE asp.prod_id = r.prodid  
 AND asp.Prop_Id = pl.Line_ProdFactorId  
 and asp.Spec_Desc = @LineSpeedTargetSpecDesc  
 and Effective_Date <= r.starttime  
 order by effective_date desc  
 )  
from @runs r  
join @prodlines pl   
on r.plid = pl.plid  
  
  
--print 'Section 24 @RunSummary: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-----------------------------------------------------------------------------------  
-- Section 24: Populate @RunSummary  
-----------------------------------------------------------------------------------  
  
-- @RunSummary simply summarizes data from @Runs.  
-- For Hanky lines, the production is captured FROM the pack units.  Added IF  
-- statement to SELECT ONLY Converter Reliability unit(s) for Tissue/Towel.  
  
  INSERT INTO @RunSummary   
   (   
   [HourEnd],  
   PLId,  
   PUId,  
   ProdId,  
   StartTime,  
   EndTime,  
   TargetSpeed,  
   Runtime  
   )  
   
  SELECT distinct   
   rls.[HourEnd],  
   pl.PLId,  
   pu.PUId,  
   rls.ProdId,  
   rls.StartTime,  
   rls.EndTime,  
   rls.TargetSpeed,  
   SUM(DATEDIFF(ss, rls.StartTime, rls.EndTime) / 60.0)  
  FROM @runs rls  
  join @prodlines pl  
  on pl.plid = rls.plid  
  JOIN @ProdUnits pu   
  ON rls.PUId = pu.PUId  
  WHERE pl.BusinessTypeID = 3   
  or (pl.BusinessTypeID <> 3 and pu.PUDesc LIKE '%Converter Reliability%')   
  GROUP BY rls.[HourEnd], pl.PLId, pu.PuId, rls.ProdId, rls.StartTime, rls.EndTime, rls.TargetSpeed  
  option (keep plan)  
  
  
--print 'sheetvalue ' + CONVERT(VARCHAR(20), GetDate(), 120)  
----------------------------------------------------------  
-- Section 35: Populate @ProdRecords  
----------------------------------------------------------  
  
  UPDATE t set   
   t.SheetValue =   
    case lpv.vartype  
    when @ACPUnitsFlag  
    then  convert(float,t.Value)  
      * CONVERT(FLOAT, asp1.Target)  
      * CONVERT(FLOAT, asp2.Target)  
      * CONVERT(FLOAT, asp4.Target)  
    when @HPUnitsFlag  
    then convert(float,t.Value)  
      * CONVERT(FLOAT, asp1.Target)  
      * CONVERT(FLOAT, asp2.Target)  
      * CONVERT(FLOAT, asp3.Target)  
      * CONVERT(FLOAT, asp4.Target)  
    when @TPUnitsFlag  
    then convert(float,t.Value)  
      * CONVERT(FLOAT, asp1.Target)  
      * CONVERT(FLOAT, asp2.Target)  
    else null  
    end  
  FROM @Tests t --with (nolock)   
  JOIN @LineProdVars lpv   
  ON t.VarId = lpv.VarId  
  join @ProdLines pl   
  on lpv.plid = pl.plid  
  and BusinessTypeID = 4  
  LEFT JOIN @ActiveSpecs asp1  
--factor   
  on asp1.Prop_Id = Cvtg_ProdFactorId --@PropCvtgProdFactorId  
  AND asp1.Char_Desc = t.ProdCode  
  AND asp1.Spec_Desc =  @PacksInBundleSpecDesc  
  AND asp1.Effective_Date < t.SampleTime  
  AND (asp1.Expiration_Date >= t.SampleTime   
   or asp1.expiration_date is null)  
  LEFT JOIN @ActiveSpecs asp2  
  on asp2.Effective_Date < t.SampleTime  
  AND (asp2.Expiration_Date >= t.SampleTime   
   or asp2.Expiration_Date is null)  
  and asp2.Char_Id = asp1.Char_Id  
--factor  
  and asp2.Prop_Id = Cvtg_ProdFactorId  --   
  AND asp2.Spec_Desc =  @SheetCountSpecDesc  
  LEFT JOIN @ActiveSpecs asp3  
  on asp3.Effective_Date < t.SampleTime  
  AND (asp3.Expiration_Date >= t.SampleTime   
   or asp3.Expiration_Date is null)  
  and asp3.Char_Id = asp1.Char_Id  
--factor  
  and asp3.Prop_Id = Cvtg_ProdFactorId --  
  AND asp3.Spec_Desc =  @ShipUnitSpecDesc  
  LEFT JOIN @ActiveSpecs asp4   
  on asp4.Effective_Date < t.SampleTime  
  AND (asp4.Expiration_Date >= t.SampleTime  
   or asp4.Expiration_Date is null)  
  and asp4.Char_Id = asp1.Char_Id  
--factor  
  and asp4.Prop_Id = Cvtg_ProdFactorId --  
  AND asp4.Spec_Desc = CartonsInCaseSpecDesc  
  
  
--print 'Insert Prod Records ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-- this table compiles production values so that they can be grouped   
-- as needed in the result sets later.  
  
INSERT @ProdRecords   
 (  
 [HourEnd],  
 PLId,   
 puid,  
 ReliabilityPUID,  
 ProdId,  
 StartTime,   
 EndTime,   
 LineSpeedTarget,  
 CalendarRuntime,  
 HolidayCurtailDT,  
 StatFactor,  
 RollsInPack,  
 PacksInBundle,  
 SheetCount,  
 SheetWidth,  
 SheetLength,  
 LineSpeedUOM,   
 SheetWidthUOM,  
 SheetLengthUOM--,  
 )  
SELECT distinct  
 rs.[HourEnd],  
 pl.PLId,  
 puid,  
 ReliabilityPUID,  
 ProdId,  
 rs.StartTime,  
 rs.EndTime,  
 TargetSpeed,  
   
 CONVERT(FLOAT,DATEDIFF(ss,rs.StartTime, rs.EndTime)) / 60.0,  
 0.0,  
  
 --StatFactor =  
 (  
 SELECT TOP 1 CONVERT(FLOAT, Target)  
 FROM @ActiveSpecs asp1  
 where asp1.prod_id = rs.prodid  
 AND Effective_Date <= rs.startTime  
--factor  
 AND asp1.Prop_Id = Cvtg_ProdFactorId  
 AND Spec_Desc = @StatFactorSpecDesc  
 ORDER BY Effective_Date DESC  
 ),  
  
 --RollsInPack =  
 (  
 SELECT TOP 1 CONVERT(FLOAT, Target)  
 FROM @ActiveSpecs asp2  
 where asp2.prod_id = rs.prodid  
 AND Effective_Date <= rs.StartTime  
--factor  
 and Prop_Id = Cvtg_ProdFactorId  
 AND Spec_Desc = RollsInPackSpecDesc  
 ORDER BY Effective_Date DESC  
 ),  
  
 --PacksInBundle =  
 (  
 SELECT TOP 1 CONVERT(FLOAT,Target)  
 FROM @ActiveSpecs asp3  
 where asp3.prod_id = rs.prodid  
 AND Effective_Date <= rs.StartTime  
--factor  
 and Prop_Id = Cvtg_ProdFactorId  
 AND Spec_Desc = @PacksInBundleSpecDesc  
 ORDER BY Effective_Date DESC  
 ),  
  
 --SheetCount =  
 (   
 SELECT TOP 1 CONVERT(FLOAT, Target)  
 FROM @ActiveSpecs asp4  
 where asp4.prod_id = rs.prodid  
 AND Effective_Date <= rs.StartTime  
--factor  
 and Prop_Id = Cvtg_ProdFactorId  
 AND Spec_Desc = @SheetCountSpecDesc  
 ORDER BY Effective_Date DESC  
 ),  
  
 --SheetWidth =  
 (  
 SELECT TOP 1 CONVERT(FLOAT, Target)  
 FROM @ActiveSpecs asp5  
 where asp5.prod_id = rs.prodid  
 AND Effective_Date <= rs.StartTime  
--factor  
 and Prop_Id = Cvtg_ProdFactorId  
 AND Spec_Desc = @SheetWidthSpecDesc  
 ORDER BY Effective_Date DESC  
 ),  
  
 --SheetLength =  
 (  
 SELECT TOP 1 CONVERT(FLOAT, Target)  
 FROM @ActiveSpecs asp7  
 where asp7.prod_id = rs.prodid  
 AND Effective_Date <= rs.StartTime  
--factor  
 and Prop_Id = Cvtg_ProdFactorId  
 AND Spec_Desc = @SheetLengthSpecDesc  
 ORDER BY Effective_Date DESC  
 ),  
  
 --LineSpeedUOM =  
 (  
 select eng_units  
 from @variablelist vl  
 where vl.var_id = pl.VarLineSpeedID  
 ),  
  
 --SheetWidthUOM =  
 (  
 SELECT TOP 1 Eng_Units  
 FROM @ActiveSpecs asp6  
 where asp6.prod_id = rs.prodid  
 AND Effective_Date <= rs.StartTime  
--factor  
 and Prop_Id = Cvtg_ProdFactorId  
 AND Spec_Desc = @SheetWidthSpecDesc  
 ORDER BY Effective_Date DESC  
 ),  
  
 --SheetLengthUOM =  
 (  
 SELECT TOP 1 Eng_Units  
 FROM @ActiveSpecs asp8  
 where asp8.prod_id = rs.prodid  
 AND Effective_Date <= rs.StartTime  
--factor  
 and Prop_Id = Cvtg_ProdFactorId  
 AND Spec_Desc = @SheetLengthSpecDesc  
 ORDER BY Effective_Date DESC  
 )--,  
  
-- LineStatus  
  
FROM @ProdLines pl   
JOIN @RunSummary rs  
ON rs.PLId = pl.PLId  
and pl.PackOrLine <> 'Pack'  
where puid = reliabilitypuid  
option (keep plan)  
  
  
--print 'update Prod Records' + ' ' + convert(varchar(25),current_timestamp,108)  
  
select @Plant = (select value from dbo.Site_Parameters with (nolock) where Parm_ID = 12)   
  
update pr set  
  
-- Units = v.eng_units,  
  
 --ConvertFtToMM =   
 CnvtLineSpeedToSheetLength =   
  case  
  when (LineSpeedUOM = 'FPM' or LineSpeedUOM = 'FT/MIN')  
  and SheetLengthUOM = 'IN'  
  then 12   
  when (LineSpeedUOM = 'FPM' or LineSpeedUOM = 'FT/MIN')  
  and SheetLengthUOM = 'MM'  
  then 304.8 -- original definition  
  when (LineSpeedUOM = 'FPM' or LineSpeedUOM = 'FT/MIN')  
  and SheetLengthUOM = 'CM'  
  then 30.48  
  when (LineSpeedUOM = 'M/MIN' or LineSpeedUOM = 'MPM')    
  and SheetLengthUOM = 'CM'  
  then 100 -- original definition  
  when (LineSpeedUOM = 'M/MIN' or LineSpeedUOM = 'MPM')    
  and SheetLengthUOM = 'MM'  
  then 1000 -- original definition  
  when (LineSpeedUOM = 'CUTS/MIN' or LineSpeedUOM = 'SHEETS/MIN' or LineSpeedUOM = 'PAG/MIN')  
  then 1  
  else null  
  end,  
  
 --ConvertInchesToMM =  
 CnvtParentRollWidthToSheetWidth =  
  case  
  when ParentRollWidthUOM = 'IN'  
  and SheetWidthUOM = 'MM'  
  then 25.4 -- original definition  
  when ParentRollWidthUOM = 'IN'  
  and SheetWidthUOM = 'IN'  
  then 1  
  when ParentRollWidthUOM = 'CM'  
  and SheetWidthUOM = 'CM'  
  then 1  
  when ParentRollWidthUOM = 'CM'  
  and SheetWidthUOM = 'MM'  
  then 10  
  when @Plant = 'Apizaco'  
  then 1  
  else null  
  end,  
  
 DefaultPMRollWidth =   
  case  
  when ParentRollWidthUOM = 'IN'  
  then case  
    when d.dept_desc = 'Cvtg Napkins'  
    then 25.5     
    else 101.3  
    end  
  when ParentRollWidthUOM = 'CM'  
  then 257.30  
  when @Plant = 'Apizaco'  
  then 268  
  else null  
  end  
  
from @ProdRecords pr  
join @ProdLines pl   
on pr.plid = pl.plid  
join departments d  
on pl.deptid = d.dept_id  
join @variablelist v  
on pl.VarActualLineSpeedId = v.var_id  
  
  
-- determine the Holiday/Curtail Downtime, if any  
--print 'Holiday/Curtail DT' + ' ' + convert(varchar(25),current_timestamp,108)  
  
update prs set  
  
 HolidayCurtailDT =  
  
 coalesce(  
  (  
  select --pr.[id],  
   sum(  
    CONVERT(FLOAT,DATEDIFF(ss,   
     (  
     CASE   
     WHEN ted.Start_Time <= pr.StartTime   
     THEN pr.StartTime   
     ELSE ted.Start_Time   
     END  
     ),   
     (  
     CASE   
     WHEN ted.End_Time >= pr.EndTime   
     THEN pr.EndTime   
     ELSE ted.End_Time   
     END  
     )) / 60.0  
    )  
   )  
  FROM @prodrecords pr  
  join Timed_Event_Details TED WITH (NOLOCK)  
  on ted.pu_id = pr.ReliabilityPUID    
  JOIN @ProdLines PL   
  ON Pr.PLId = PL.PLId   
  JOIN event_reason_category_data ercd WITH (NOLOCK)   
  ON TED.event_reason_tree_data_id = ercd.event_reason_tree_data_id   
  JOIN event_reason_catagories erc WITH (NOLOCK)   
  ON ercd.erc_id = erc.erc_id   
  WHERE TED.START_TIME < pr.endtime   
  AND (TED.END_TIME > pr.starttime or TED.End_Time is null)   
  AND (erc.erc_desc = 'Schedule:Holiday/Curtail')   
  and pr.[id] = prs.[id]  
  ),0.0)  
   
FROM @ProdRecords prs  
option (maxdop 1)  
  
  
update prs set  
  
 GoodUnits =   
  
  CASE    
  
  WHEN pl.BusinessTypeID in (1,2)  
  THEN  (  
   SELECT sum(convert(float,t10a.value))   
   FROM @Tests t10a --with (nolock)  
   JOIN @ProdLines pl10a   
   ON t10a.VarId = pl10a.VarGoodUnitsId  
   AND t10a.SampleTime > prs.StartTime   
   AND t10a.SampleTime <= prs.EndTime  
   and t10a.PLId = pl10a.PLId  
   and t10a.plid = prs.plid  
   )  
  
      WHEN pl.BusinessTypeID = 3   
  THEN  (  
   SELECT sum(convert(float,t10b.value))   
   FROM @Tests t10b --with (nolock)  
   JOIN @LineProdVars lpv10b   
   ON t10b.VarId = lpv10b.VarID  
   AND t10b.SampleTime > prs.StartTime   
   AND t10b.SampleTime <= prs.EndTime  
   and t10b.PLId = lpv10b.PLId  
   and t10b.plid = prs.plid  
   )  
  
  WHEN pl.BusinessTypeID = 4  
  THEN  (  
   SELECT   
    Sum(coalesce(convert(float,SheetValue), 0.0))  
   FROM @Tests t10c --with (nolock)  
   JOIN @LineProdVars lpv10c   
   ON t10c.VarId = lpv10c.VarId  
   where t10c.SampleTime > prs.StartTime   
   AND t10c.SampleTime <= prs.EndTime  
   and t10c.PLId = lpv10c.PLId  
   and t10c.plid = prs.plid  
   )  
  
  ELSE NULL  
  
  END  
  
FROM @ProdRecords prs  
join @ProdLines pl  
on pl.plid = prs.plid  
  
  
/*  
--print 'stages' + ' ' + convert(varchar(25),current_timestamp,108)  
  
insert @Stages  
SELECT  
 pr.puid,  
 pr.starttime,    
 avg(convert(float,  
  case  
  when t.VarId = pl.VarPMRollWidthId   
  then t.value  
  else null  
  end  
 )) stage2,  
 avg(convert(float,  
  case  
  when t.VarId = pl.VarParentRollWidthId   
  then t.value  
  else null  
  end  
 )) stage3  
FROM @Tests t --with (nolock)   
join @ProdLines pl   
on  t.plid = pl.plid  
join @ProdRecords pr   
on t.SampleTime > pr.StartTime   
AND  t.SampleTime <= pr.EndTime  
and  t.puid = pr.puid  
where convert(float,t.Value,0) < (pr.DefaultPMRollWidth*1.1)  
group by pr.puid, pr.starttime  
  
--print 'roll width' + ' ' + convert(varchar(25),current_timestamp,108)  
  
update prs set  
 RollWidth2Stage = s.stage2,  
 RollWidth3Stage = s.stage3  
FROM @ProdRecords prs  
join @Stages s  
on prs.puid = s.puid  
and prs.starttime = s.starttime  
*/  
  
--print 'misc prodrecord updates' + ' ' + convert(varchar(25),current_timestamp,108)  
  
update prs set  
  
 ProductionRuntime = CalendarRuntime - HolidayCurtailDT,  
  
 WebWidth =  prs.DefaultPMRollWidth  
--  CASE    
--  WHEN  (   
--   COALESCE(RollWidth2Stage,0) +   
--   COALESCE(RollWidth3Stage,0) +   
--   prs.DefaultPMRollWidth  
--   ) = prs.DefaultPMRollWidth   
--  THEN prs.DefaultPMRollWidth   
--  ELSE COALESCE(RollWidth2Stage,RollWidth3Stage)  
--  END  
    
from @ProdRecords prs  
  
  
update prs set  
 RollsPerLog = FLOOR((WebWidth * CnvtParentRollWidthToSheetWidth) / SheetWidth)  
from @ProdRecords prs  
  
  
--print 'target and actual units' + ' ' + convert(varchar(25),current_timestamp,108)  
  
update prs set  
  
 TargetUnits =   
  CASE pl.BusinessTypeID  
      WHEN 3   
  THEN --Facial, Line Speed Target is Cartons/Min.  
   LineSpeedTarget * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
   ProductionRuntime * StatFactor  
  WHEN 4   
  THEN --Hanky lines in Neuss  
   (LineSpeedTarget / StatFactor) * ProductionRuntime   
   --@StatFactor is really StatUnit in Neuss!!!  
       ELSE        --Tissue/Towel/Napkins  
       LineSpeedTarget * CnvtLineSpeedToSheetLength * (1/convert(float,SheetCount)) *  
       (1/convert(float,SheetLength)) * RollsPerLog *   
       ProductionRuntime * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
       StatFactor   
       END,  
  
 ActualUnits =   
  CASE pl.BusinessTypeID  
  WHEN 1    
  THEN --Tissue/Towel  
   (GoodUnits * RollsPerLog * (1/convert(float,RollsInPack)) *  
   (1/convert(float,PacksInBundle)) * StatFactor)  
  WHEN 2   
  THEN --Napkins  GoodUnits = Stacks, no conversion needed.  
   GoodUnits * (1/convert(float,RollsInPack)) *  
   (1/convert(float,PacksInBundle)) * StatFactor  
  WHEN 3   
  THEN --Facial (Convert Good Units on ACP to Stat)  
   GoodUnits * StatFactor  
  WHEN 4    
  THEN  --Hanky Lines in Neuss.  Good Units = Sheets.  
    case   
    when StatFactor > 0.0  
    then GoodUnits/StatFactor  
    else null  
    end  
       --@StatFactor is really StatUnit [sheets per stat] in Neuss!!!  
  ELSE     --Else default to the Tissue/Towel Calc.  
   GoodUnits * RollsPerLog * (1/convert(float,RollsInPack)) *  
   (1/convert(float,PacksInBundle)) * StatFactor  
  END  
  
from @ProdRecords prs  
join @ProdLines pl  
on pl.plid = prs.plid  
  
  
  --print 'LDR ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  -------------------------------------------------------------------------------------------  
  -- Section 48: Results Set #8 - Return the production result set by Line / Team / Product.  
  -------------------------------------------------------------------------------------------  
  
  INSERT @LineDisplayResults  
   (  
   [Line],  
   [HourEnd],  
   [ActualUnits],  
   [TargetUnits]--,  
   )  
  SELECT   
   pl.PLDesc [Line],  
   prs.[HourEnd],  
   sum(prs.ActualUnits) ActualUnits,  
   sum(prs.TargetUnits) TargetUnits--,  
  from @ProdRecords prs  
  join @ProdLines pl --with (nolock) -- Rev11.33   
  ON prs.PLId = pl.PLId  
  WHERE pl.PackOrLine <> 'Pack'  
  GROUP BY pl.plid, pl.PLDesc, prs.[HourEnd] --prs.EndTime  
  ORDER BY pl.plid, pl.PLDesc, prs.[HourEnd] --prs.EndTime  
  option (keep plan)  
  
  
--print 'LDS1' + ' ' + convert(varchar(25),current_timestamp,108)  
  
insert @LineDisplaySummary  
 (  
 [Line],  
 [ShiftCurrent]  
 )  
select  
 [Line],  
  
--/*  
 CASE   
 WHEN  sum(CONVERT(FLOAT,ldr.TargetUnits)) > 0   
 THEN CASE    
   WHEN sum(ldr.TargetUnits) IS NOT NULL     
   THEN sum(CONVERT(FLOAT,ldr.ActualUnits))   
   ELSE 0  
   END              
    / sum(CONVERT(FLOAT,ldr.TargetUnits))  
 ELSE NULL   
 END [PR]  
--*/  
from @LineDisplayResults ldr  
where [HourEnd] > @ShiftStart   
and [HourEnd] <= @EndTime  
group by [Line]  
  
  
--print 'LDS2' + ' ' + convert(varchar(25),current_timestamp,108)  
  
if upper(@Line) <> 'ALL'  
begin  
  
update lds set  
  
 Hour12 =  
  (  
  select --[PR]  
   CASE   
   WHEN CONVERT(FLOAT,ldr1.TargetUnits) > 0   
     THEN  CASE    
     WHEN ldr1.TargetUnits IS NOT NULL     
     THEN CONVERT(FLOAT,ldr1.ActualUnits)   
     ELSE 0            
     END              
    / CONVERT(FLOAT,ldr1.TargetUnits)  
     ELSE NULL END [PR]  
  from @LineDisplayResults ldr1  
  where ldr1.[Line] = lds.[Line]  
  and ldr1.[HourEnd] = dateadd(hh,1,@StartTime)  
  ),  
  
 Hour11 =  
  (  
  select --[PR]  
   CASE   
   WHEN CONVERT(FLOAT,ldr2.TargetUnits) > 0   
     THEN  CASE    
     WHEN ldr2.TargetUnits IS NOT NULL     
     THEN CONVERT(FLOAT,ldr2.ActualUnits)   
     ELSE 0            
     END              
    / CONVERT(FLOAT,ldr2.TargetUnits)  
     ELSE NULL END [PR]  
  from @LineDisplayResults ldr2  
  where ldr2.[Line] = lds.[Line]  
  and ldr2.[HourEnd] = dateadd(hh,2,@StartTime)  
  ),  
  
 Hour10 =  
  (  
  select --[PR]  
   CASE   
   WHEN CONVERT(FLOAT,ldr3.TargetUnits) > 0   
     THEN  CASE    
     WHEN ldr3.TargetUnits IS NOT NULL     
     THEN CONVERT(FLOAT,ldr3.ActualUnits)   
     ELSE 0            
     END              
    / CONVERT(FLOAT,ldr3.TargetUnits)  
     ELSE NULL END [PR]  
  from @LineDisplayResults ldr3  
  where ldr3.[Line] = lds.[Line]  
  and ldr3.[HourEnd] = dateadd(hh,3,@StartTime)  
  ),  
  
 Hour9 =  
  (  
  select --[PR]  
   CASE   
   WHEN CONVERT(FLOAT,ldr4.TargetUnits) > 0   
     THEN  CASE    
     WHEN ldr4.TargetUnits IS NOT NULL     
     THEN CONVERT(FLOAT,ldr4.ActualUnits)   
     ELSE 0            
     END              
    / CONVERT(FLOAT,ldr4.TargetUnits)  
     ELSE NULL END [PR]  
  from @LineDisplayResults ldr4  
  where ldr4.[Line] = lds.[Line]  
  and ldr4.[HourEnd] = dateadd(hh,4,@StartTime)  
  ),  
  
 Hour8 =  
  (  
  select --[PR]  
   CASE   
   WHEN CONVERT(FLOAT,ldr5.TargetUnits) > 0   
     THEN  CASE    
     WHEN ldr5.TargetUnits IS NOT NULL     
     THEN CONVERT(FLOAT,ldr5.ActualUnits)   
     ELSE 0            
     END              
    / CONVERT(FLOAT,ldr5.TargetUnits)  
     ELSE NULL END [PR]  
  from @LineDisplayResults ldr5  
  where ldr5.[Line] = lds.[Line]  
  and ldr5.[HourEnd] = dateadd(hh,5,@StartTime)  
  ),  
  
 Hour7 =  
  (  
  select --[PR]  
   CASE   
   WHEN CONVERT(FLOAT,ldr6.TargetUnits) > 0   
     THEN  CASE    
     WHEN ldr6.TargetUnits IS NOT NULL     
     THEN CONVERT(FLOAT,ldr6.ActualUnits)   
     ELSE 0            
     END              
    / CONVERT(FLOAT,ldr6.TargetUnits)  
     ELSE NULL END [PR]  
  from @LineDisplayResults ldr6  
  where ldr6.[Line] = lds.[Line]  
  and ldr6.[HourEnd] = dateadd(hh,6,@StartTime)  
  ),  
  
 Hour6 =  
  (  
  select --[PR]  
   CASE   
   WHEN CONVERT(FLOAT,ldr7.TargetUnits) > 0   
     THEN  CASE    
     WHEN ldr7.TargetUnits IS NOT NULL     
     THEN CONVERT(FLOAT,ldr7.ActualUnits)   
     ELSE 0            
     END              
    / CONVERT(FLOAT,ldr7.TargetUnits)  
     ELSE NULL END [PR]  
  from @LineDisplayResults ldr7  
  where ldr7.[Line] = lds.[Line]  
  and ldr7.[HourEnd] = dateadd(hh,7,@StartTime)  
  ),  
  
 Hour5 =  
  (  
  select --[PR]  
   CASE   
   WHEN CONVERT(FLOAT,ldr8.TargetUnits) > 0   
     THEN  CASE    
     WHEN ldr8.TargetUnits IS NOT NULL     
     THEN CONVERT(FLOAT,ldr8.ActualUnits)   
     ELSE 0            
     END              
    / CONVERT(FLOAT,ldr8.TargetUnits)  
     ELSE NULL END [PR]  
  from @LineDisplayResults ldr8  
  where ldr8.[Line] = lds.[Line]  
  and ldr8.[HourEnd] = dateadd(hh,8,@StartTime)  
  ),  
  
 Hour4 =  
  (  
  select --[PR]  
   CASE   
   WHEN CONVERT(FLOAT,ldr9.TargetUnits) > 0   
     THEN  CASE    
     WHEN ldr9.TargetUnits IS NOT NULL     
     THEN CONVERT(FLOAT,ldr9.ActualUnits)   
     ELSE 0            
     END              
    / CONVERT(FLOAT,ldr9.TargetUnits)  
     ELSE NULL END [PR]  
  from @LineDisplayResults ldr9  
  where ldr9.[Line] = lds.[Line]  
  and ldr9.[HourEnd] = dateadd(hh,9,@StartTime)  
  ),  
  
 Hour3 =  
  (  
  select --[PR]  
   CASE   
   WHEN CONVERT(FLOAT,ldr10.TargetUnits) > 0   
     THEN  CASE    
     WHEN ldr10.TargetUnits IS NOT NULL     
     THEN CONVERT(FLOAT,ldr10.ActualUnits)   
     ELSE 0            
     END              
    / CONVERT(FLOAT,ldr10.TargetUnits)  
     ELSE NULL END [PR]  
  from @LineDisplayResults ldr10  
  where ldr10.[Line] = lds.[Line]  
  and ldr10.[HourEnd] = dateadd(hh,10,@StartTime)  
  ),  
  
 Hour2 =  
  (  
  select --[PR]  
   CASE   
   WHEN CONVERT(FLOAT,ldr11.TargetUnits) > 0   
     THEN  CASE    
     WHEN ldr11.TargetUnits IS NOT NULL     
     THEN CONVERT(FLOAT,ldr11.ActualUnits)   
     ELSE 0            
     END              
    / CONVERT(FLOAT,ldr11.TargetUnits)  
     ELSE NULL END [PR]  
  from @LineDisplayResults ldr11  
  where ldr11.[Line] = lds.[Line]  
  and ldr11.[HourEnd] = dateadd(hh,11,@StartTime)  
  ),  
  
 Hour1 =  
  (  
  select --[PR]  
   CASE   
   WHEN CONVERT(FLOAT,ldr12.TargetUnits) > 0   
     THEN  CASE    
     WHEN ldr12.TargetUnits IS NOT NULL     
     THEN CONVERT(FLOAT,ldr12.ActualUnits)   
     ELSE 0            
     END              
    / CONVERT(FLOAT,ldr12.TargetUnits)  
     ELSE NULL END [PR]  
  from @LineDisplayResults ldr12  
  where ldr12.[Line] = lds.[Line]  
  and ldr12.[HourEnd] = dateadd(hh,12,@StartTime)  
  )  
  
from @LineDisplaySummary lds  
  
  
end  
  
  
--print 'ResturnResultSets: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-----------------------------------------------------------  
ReturnResultSets:  
  
-----------------------------------------------------------  
  
--- testing ---  
  
/*  
select 'ldr',   
 [Line], [HourEnd], ActualUnits, TargetUnits,   
 CASE   
 WHEN CONVERT(FLOAT,ldr.TargetUnits) > 0   
   THEN CASE  WHEN ldr.TargetUnits IS NOT NULL     
      THEN CONVERT(FLOAT,ldr.ActualUnits)   
      ELSE 0            
      END              
  / CONVERT(FLOAT,ldr.TargetUnits)  
   ELSE NULL END [PR]  
from @LineDisplayResults ldr  
order by [Line], [HourEnd]  
*/  
  
--select @StartTime StartTime, @EndTime EndTime, @ShiftStart ShiftStart  
  
--select 'pr', * from @ProdRecords prs  
--order by plid, [hourend], starttime  
  
--select 'pl', * from @ProdLines  
  
--select 'dim', * from @dimensions  
--where dimension = 'Hour'  
--order by puid, starttime  
  
--select * from @runs  
--order by puid, starttime   
  
--select 'lpv', * from @LineProdVars  
--select 'pu', * from @produnits  
  
--select 'ldr', * from @LineDisplayResults  
--select 'lds', * from @LineDisplaySummary  
  
--select count(*) from #tests  
  
  
 -----------------------------------------------------------------------------  
 -- Section 42: Results Set #2 -  return the report parameter values.  
 ----------------------------------------------------------------------------  
  
 if upper(@Line) = 'ALL'  
 begin  
  
  select   
   [Line],   
   [ShiftCurrent]  
  from @LineDisplaySummary   
  order by [Line], [ShiftCurrent]  
  
 end  
 else  
 begin  
  
  select   
   [Line],   
   [ShiftCurrent],  
   [Hour1],  
   [Hour2],  
   [Hour3],  
   [Hour4],  
   [Hour5],  
   [Hour6],  
   [Hour7],  
   [Hour8],  
   [Hour9],  
   [Hour10],  
   [Hour11],  
   [Hour12]  
  from @LineDisplaySummary   
  order by [Line], [ShiftCurrent]  
  
 end  
  
  
-------------------------------------------------------------------------  
-- Drop temp tables  
-------------------------------------------------------------------------  
  
Finished:  
  
--drop table dbo.#tests  
  
  
--print 'End of Result Sets: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
RETURN  
  
  
