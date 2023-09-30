      CREATE PROCEDURE dbo.spLocal_ReportSplice  
--*/  
  
  
/*  
-------------------------------------------------------------------------------  
--  2004-2-13   Tim Rogers  
--  Version    4.1.0  
--    Changes to reason code field lengths to accomadate 100 chars.  
  
--------------------------------------------------------------------------------------  
Modified by MSI  
On 30-July-2002   Version 4.0.2  
Change  Eliminated use of cursors via cration of temp tables for PU_IDs,   
  shift, team & line status options.  
  New dependancy: spCMN_ReportCollectionParsing (to be included in  
  next Proficy release)  
  New dependancy: SDLS line-status upgrade (added End_DateTime column  
  to table)  
--------------------------------------------------------------------------------------  
Modified by Joe Juenger  
On 30-May-2002   Version 2.3.1  
Change  Changed the inclusive 'between' keywords to '>=' and '<'   
                exclusive conditions.   
--------------------------------------------------------------------------------------  
Modified by Joe Juenger  
On 22-Jan-2002   Version 2.3.0  
Change  Team & shift info returned based on Converter for other units (eg Splicer)  
--------------------------------------------------------------------------------------  
Modified by Joe Juenger  
On 22-Jan-2002   Version 2.2.1  
Change  Added Line Description to return values  
--------------------------------------------------------------------------------------  
Modified by Joe Juenger  
On 11-Jan-2002   Version 2.2.0  
Change  Added functionality to query by multiple line, team, shift, line status  
--------------------------------------------------------------------------------------  
Modified by Ugo Lapierre, Solutions et Technologies Industrielles Inc.  
On 14-dec-01   Version   2.1.0  
Change  Change source of prodstatus desc from production status table to custom datatype  
--------------------------------------------------------------------------------------  
Modified by Ugo Lapierre, Solutions et Technologies Industrielles Inc.  
On 17-sep-01   Version   2.0.0  
Change  Add product and line status as input to allow th sp to   
  return data for a specific product or a specific line status  
--------------------------------------------------------------------------------------  
Created by Ugo Lapierre, Solutions et Technologies Industrielles Inc.  
On date unknown   Version : 1.0.0  
--------------------------------------------------------------------------------------  
  
*/  
--DECLARE  
  @InputStart_Time  Datetime,  
  @InputEnd_Time  Datetime,  
  @InputUnitDesc varchar(2000),  
  @InputTeam   varchar(1250),  
  @InputShift   varchar(8),  
  @Prod_id  int,  
  @LineStatus  varchar(600)  
  
/*  
-----------------------------------------------  
--Test Data  
  Set @InputStart_Time  = '5/1/2002 9:00:00'  
  Set @InputEnd_Time  = '5/1/2002 10:00:00'  
  Set @InputUnitDesc = 'DIMP129 Splicers'  
  Set @InputTeam  = 'All'  
  Set @InputShift  = 'All'  
  Set @Prod_id  = 0  
  Set @LineStatus = 'All'  
----------------------------------------------  
*/  
  
AS  
DECLARE  
@Line_Desc  VARCHAR(75),  
@PL_Desc  VARCHAR(50),  
@PL_ID    INT,  
@Master_PUIDString  VARCHAR(240),  
@MasterLine_PUIDString  VARCHAR(240), --conatins above string, but also with master unit IDs  
@Master_PUIDStringTemp  VARCHAR(240),  
@Master_PUIDSingleInt  INT,  
@MasterLine_PUIDSingleInt INT,  
@Master_PUIDSingleString VARCHAR(6),  
@TimeStamp  datetime,  
@Amount   Float,  
@Units   varchar(30),  
@Type   varchar(30),  
@fault   varchar(30),  
@Location  varchar(75),  
@Reason1     varchar(50),  
@Reason2  varchar(50),  
@Reason3  varchar(50),  
@Reason4  varchar(50),  
@Team   varchar(25),  
@Shift   varchar(25),  
@Master_PUID  int,  
@Product  varchar(50),  
@Status   varchar(50),  
@StatusTime  datetime,  
@Comment  varchar(255),  
@NextStatus  int,  
@CC_id   int,  
@CC_Value  varchar(30),  
@plid   int,  
@ErrMsg   nVarChar(1000),  
@StatusScheduleId Int, --for backpopulate  
@UnitId   Int, --for backpopulate  
@PreviousStatusScheduleId Int, --for backpopulate  
@Seconds  Int, --for backpopulate  
@MaxDateTime  DateTime, --for backpopulate  
@StartDateTime  DateTime, --for backpopulate  
@lblAll   nVarChar(50),  
@PLDESCList  nVarChar(4000)  
  
  
  
-- TABLE BELOW USED TO ELIMINATE CHARINDEX FUNCTION AGAINST PROD_DESC  
  
------------------------------------------------------------------  
-- New table creation  / process below based on DPR sp  
------------------------------------------------------------------  
Create Table #Splices   
( TimeStamp   datetime,  
      SpliceStatus   float,  
      Units    varchar(30),  
      Type    Varchar(30),  
      Fault    varchar(30),  
      ConverterCycle   varchar(30),  
      Reason1       varchar(50),  
      Reason2    varchar(50),  
      Reason3    varchar(50),  
      Reason4    varchar(50),  
      Location   varchar(75),  
      Product    varchar(50),  
      Crew    varchar(25),  
      Shift    varchar(25),  
      LineStatus   varchar(50),  
      PLID    int,  
      PUID    int,   
      InRun    int,  
 Comments   varchar(255),  
      Line_Desc   varchar(75))  
--------------------------------------------------------------  
Create Table #PLIDList  
( RCDID     int,  
 PLID     int,  
 PLDESC     nVarChar(50),  
 MasterDesc   varchar(50),  
 MasterUnit    int,  
 STLSUnit   int)  
   
----------------------------------------------------------------------------  
-- String Parsing: Parse Line ID, also gets info assoicated Only to the Line  
-- e.g the Converter Unit ID, and Variables used in QA  
----------------------------------------------------------------------------  
  
If  @InputUnitDesc = '!null'  
Begin  
 Set @PLDESCList = @lblAll  
 --  
 Insert #PLIDList (PLID,PLDESC)  
  Select PL_ID, PL_DESC  
  From Prod_Lines  
End  
Else  
Begin  
 Insert #PLIDList (RCDID, MasterDesc)  
  Exec SPCMN_ReportCollectionParsing  
  @PRMCollectionString = @InputUnitDesc, @PRMFieldDelimiter = null, @PRMRecordDelimiter = ',',   
  @PRMDataType01 = 'varchar(50)'  
 --  
 Update #PLIDList Set PLID = PU.PL_ID  
  From #PLIDList  
  Join Prod_Units PU on PLDESC = PU.PU_DESC  
END  
Update #PLIDList   
 Set PLID = PL.PL_ID,  
 PLDESC = PL.PL_DESC,  
 MASTERUNIT = PU.PU_ID,  
 STLSUnit = Case WHEN (CharIndex ('STLS=', pu.Extended_Info, 1)) > 0  
   THEN Substring ( pu.Extended_Info,  
      ( CharIndex ('STLS=', pu.Extended_Info, 1) + 5),  
  Case  WHEN  (CharIndex(';', pu.Extended_Info, CharIndex('STLS=', pu.Extended_Info, 1))) > 0  
   THEN  (CharIndex(';', pu.Extended_Info, CharIndex('STLS=', pu.Extended_Info, 1)) - (CharIndex('STLS=', pu.Extended_Info, 1) + 5))   
       ELSE  Len(pu.Extended_Info)  
       END )  
     END  
 From #PLIDList tpl  
 Join Prod_Units pu on pu.pu_desc = tpl.MasterDesc  
 Join Prod_Lines PL on pu.pl_id = PL.PL_ID  
  
update #PLIDList set STLSUnit = MasterUnit where STLSUnit is null  
  
----------------------------------------------------------------------------  
-- Table below to be used temporarily in lieu of adding an 'EndDate_Time' column  
-- to the production Local_PG_Line_Status table  
----------------------------------------------------------------------------  
Create Table #Local_PG_Line_Status  
( Status_Schedule_Id  int,  
 Start_DateTime   datetime,  
 Line_Status_Id   int,  
 Unit_Id    int,  
 End_DateTime   datetime)  
  
Insert into #Local_PG_Line_Status (Status_Schedule_Id, Start_DateTime,   
 Line_Status_Id, Unit_Id)  
  
Select Status_Schedule_Id, Start_DateTime, Line_Status_Id, Unit_Id   
from Local_PG_Line_Status  
  
-- Create index on the temp table    
CREATE     INDEX IDX_LineStatus_UnitTime  
 ON #Local_PG_Line_Status(Unit_Id, Start_DateTime, End_DateTime) ON [PRIMARY]  
  
-------------------------------------------------------------------------------  
-- Initialize variables/constants  
-------------------------------------------------------------------------------  
SELECT @Seconds = 0  
-------------------------------------------------------------------------------  
-- Declare cursor for inserted/modified record  
-------------------------------------------------------------------------------  
DECLARE recSCursor INSENSITIVE CURSOR FOR  
 (SELECT Status_Schedule_Id, Unit_Id, Start_DateTime  
  FROM #Local_PG_Line_Status)  
  FOR READ ONLY  
OPEN recSCursor  
FETCH NEXT FROM recSCursor INTO @StatusScheduleId, @UnitId,   
 @StartDateTime   
-------------------------------------------------------------------------------  
-- Go through the insert cursor  
-------------------------------------------------------------------------------  
WHILE @@Fetch_Status = 0  
BEGIN  
 SELECT @MaxDateTime = Null,  
  @MaxDateTime = Max(Start_DateTime)  
  FROM #Local_PG_Line_Status  
  WHERE Unit_Id = @UnitId  
  AND Start_DateTime < @StartDateTime  
  -- 09/06/02 JJR Removed line below to prevent NULL values in EndTime column  
  --AND Start_DateTime > DateAdd(mm, -6, @StartDateTime)  
 IF @MaxDateTime Is Not Null  
 BEGIN   
  SELECT @PreviousStatusScheduleId = Null,  
   @PreviousStatusScheduleId = Status_Schedule_Id  
   FROM #Local_PG_Line_Status  
   WHERE Unit_Id= @UnitId   
   AND Start_DateTime = @MaxDateTime  
  UPDATE #Local_PG_Line_Status  
   SET End_DateTime = DateAdd (ss, -@Seconds, @StartDateTime)  
   WHERE Status_Schedule_Id = @PreviousStatusScheduleId  
 END  
 FETCH NEXT FROM recSCursor INTO @StatusScheduleId, @UnitId,   
  @StartDateTime   
END  
-------------------------------------------------------------------------------  
-- Deallocate cursor  
-------------------------------------------------------------------------------  
CLOSE  recSCursor  
DEALLOCATE recSCursor  
  
--End_DateTime  
  
----------------------------------------------------------------------------  
  
----------------------------------------------------------------------------  
-- Check Parameters: @InputStart_Time  
----------------------------------------------------------------------------  
If @InputStart_Time > @InputEnd_Time  
Begin  
 Select @ErrMsg = 'Start Date is greater than End Date'  
 GOTO ErrorCode  
End  
----------------------------------------------------------------------------  
-- Check Parameter: Period InComplete  
----------------------------------------------------------------------------  
If @InputEnd_Time > GetDate()  
Begin  
 Select @ErrMsg = 'Period is InComplete'  
End  
----------------------------------------------------------------------------  
  
----------------------------------------------------------------------------  
--Old Code to get the Converter cycle  
----------------------------------------------------------------------------  
/*  
 select @cc_id=var_id from variables  
 join prod_units on variables.pu_id = prod_units.pu_id   
 where input_tag like '%PRCycleLow.f_CV' and  
  (CHARINDEX(','+  (CAST(variables.pu_id As VARCHAR(6)  ))+',',  
            ','+@MasterLine_PUIDString+',') > 0)  
 and prod_units.pl_id = @PL_ID  
  
  
 select @CC_value=result from tests   
 where result_on = @statustime and var_id=@cc_id  
*/  
----------------------------------------------------------------------------  
  
  
  
  
  
  
----------------------------------------------------------------------------  
-- Get Data: Splice Data  
----------------------------------------------------------------------------  
Insert into #Splices (TimeStamp, SpliceStatus, Units, Type, Fault, Reason1,  
Reason2, Reason3, Reason4, Location, Product, Crew, Shift, LineStatus, PLID, PUID, Comments, Line_Desc)  
  
Select  
 wed.TimeStamp as 'TimeStamp',  
 wed.amount as 'SpliceStatus',  
 wemt.wemt_Name as 'Units',  
 wet.wet_Name as 'Type',  
 wef.weFault_Name as 'Fault',  
 r1.Event_Reason_Name as 'Reason1',  
 r2.Event_Reason_Name as 'Reason2',  
 r3.Event_Reason_Name as 'Reason3',  
 r4.Event_Reason_Name as 'Reason4',  
 Pu.pu_DESC as 'Location',  
 P.Prod_Desc as 'Product',  
 CS.Crew_DESC as 'Crew',  
 CS.Shift_DESC as 'Shift',  
 PHR.Phrase_Value as 'LineStatus',  
 PL.PLID as 'PLID',  
 WED.PU_ID as 'PUID',  
 wtc.Comment_Text AS 'Comment',  
 pl.pldesc as 'Line_Desc'  
 --  
From  
 Waste_Event_Details as wed  
 Left Join Event_Reasons as r1 on (r1.Event_Reason_id = wed.Reason_level1)  
 Left Join Event_Reasons as r2 on (r2.Event_Reason_id = wed.Reason_level2)  
 Left Join Event_Reasons as r3 on (r3.Event_Reason_id = wed.Reason_level3)  
 Left Join Event_Reasons as r4 on (r4.Event_Reason_id = wed.Reason_level4)  
 Left Join waste_Event_Fault as wef on (wef.weFault_id = wed.weFault_id)  
 Left Join waste_Event_Type as wet on wet.wet_id=wed.wet_id  
 Left Join waste_Event_meas as wemt on wemt.wemt_id=wed.wemt_id  
 Left Join waste_n_timed_comments as wtc on wtc.wtc_source_id = wed.wed_id  
 Left Join Prod_Units as pu on (pu.pu_id = wed.source_PU_Id)  
 Inner join #PLIDList as pl on (wed.pu_id = pl.MasterUnit)  
 Inner Join Production_Starts PS on (pl.MasterUnit = PS.PU_ID and   
       PS.Start_TIME <= WED.TimeStamp and  
       (PS.End_TIME > WED.TimeStamp or PS.End_TIME IS null))  
 Inner Join Products P on PS.Prod_ID = P.Prod_ID   
 Left Join Crew_SCHEDULE CS on (pl.STLSUnit = CS.PU_ID and   
       CS.Start_TIME <= WED.TimeStamp and  
       (CS.End_TIME > WED.TimeStamp or CS.End_TIME IS null))  
 Left Join #Local_PG_Line_Status LPG on (pl.STLSUnit = LPG.Unit_ID and   
       LPG.Start_DATETIME <= WED.TimeStamp and  
       (LPG.End_DATETIME > WED.TimeStamp or LPG.End_DATETIME IS null))  
 Left Join Phrase PHR on LPG.Line_Status_ID = PHR.Phrase_ID  
Where  
 (wed.TimeStamp >= @InputStart_Time and wed.TimeStamp < @InputEnd_Time)  
  
----------------------------------------------------------------------------  
  
----------------------------------------------------------------------------  
-- Existing Code Starts Below  
----------------------------------------------------------------------------  
  
--Create a local table   
Create Table #SpliceReport (  
     Timestamp  datetime,  
     SpliceStatus Float,  
     Units  varchar(30),  
     Type  Varchar(30),  
     Fault  varchar(30),  
     ConverterCycle varchar(30),  
     Reason1     varchar(50),  
     Reason2  varchar(50),  
     Reason3  varchar(50),  
     Reason4  varchar(50),  
     Location  varchar(75),  
     Product  varchar(50),  
     Team  varchar(25),  
     Shift  varchar(25),  
     LineStatus  varchar(50),  
     Comments  varchar(255),  
     Line_Desc  varchar(75)  
)  
  
-------------------------------------------------------------------------------------  
-- Copy the new data into the existing output table structure  
-------------------------------------------------------------------------------------  
  
INSERT #SpliceReport  
(Timestamp, SpliceStatus, Units, Type, Fault, Reason1, Reason2, Reason3,  
Reason4, Location, Product, Team, Shift, LineStatus, Comments, Line_Desc)  
Select TimeStamp, SpliceStatus, Units, Type, Fault, Reason1, Reason2, Reason3,  
Reason4, Location, Product, Crew, Shift, LineStatus, Comments, Line_Desc  
FROM #Splices  
  
--SELECT * from #Splices  
--SELECT 'PLIDList', * FROM #PLIDList  
  
DROP TABLE #Splices  
DROP TABLE #PLIDList  
DROP TABLE #Local_PG_Line_Status  
  
-- The Stored Procedure result   
  
select @product=null  
select @product = prod_desc from products where prod_id = @prod_id  
  
-- For a specific team and all shift  
If @InputTeam <> 'ALL' and @InputShift = 'ALL' and @lineStatus ='ALL' and @product is not null  
  Begin  
     Select * from #SpliceReport   
 where (CHARINDEX(','+ team+',',  
                ','+@InputTeam+',') > 0) and  
  product = @product   
 order by timestamp  
  
 Drop table #SpliceReport  
 return  
  End  
  
If @InputTeam <> 'ALL' and @InputShift = 'ALL' and @lineStatus ='ALL' and @product is null  
  Begin  
     Select * from #SpliceReport   
 where (CHARINDEX(','+ team+',',  
                ','+@InputTeam+',') > 0)  
  order by timestamp  
 Drop table #SpliceReport  
 return  
  End  
  
If @InputTeam <> 'ALL' and @InputShift = 'ALL' and @lineStatus <>'ALL' and @product is not null  
  Begin  
     Select * from #SpliceReport   
 where (CHARINDEX(','+ team+',',  
                ','+@InputTeam+',') > 0) and  
   product = @product and   
       (CHARINDEX(','+ LineStatus+',',  
                ','+@LineStatus+',') > 0)   
 order by timestamp   Drop table #SpliceReport  
 return  
  End  
  
If @InputTeam <> 'ALL' and @InputShift = 'ALL' and @lineStatus <>'ALL' and @product is null  
  Begin  
    Select * from #SpliceReport   
 where (CHARINDEX(','+ team+',',  
                ','+@InputTeam+',') > 0) and   
       (CHARINDEX(','+ LineStatus+',',  
                ','+@LineStatus+',') > 0)     
 order by timestamp  
 Drop table #SpliceReport  
 return  
  End  
  
  
  
If @InputTeam = 'ALL' and @InputShift <> 'ALL' and @lineStatus ='ALL' and @product is not null  
  Begin  
     Select * from #SpliceReport   
 where (CHARINDEX(','+ Shift+',',  
                ','+@InputShift+',') > 0) and   
  product = @product   order by timestamp  
 Drop table #SpliceReport  
 return  
  End  
  
If @InputTeam = 'ALL' and @InputShift <> 'ALL' and @lineStatus ='ALL' and @product is null  
  Begin  
     Select * from #SpliceReport   
 where (CHARINDEX(','+ Shift+',',  
                ','+@InputShift+',') > 0 )   
 order by timestamp  
 Drop table #SpliceReport  
 return  
  End  
  
If @InputTeam = 'ALL' and @InputShift <> 'ALL' and @lineStatus <>'ALL' and @product is not null  
  Begin  
     Select * from #SpliceReport   
 where (CHARINDEX(','+ Shift+',',  
                ','+@InputShift+',') > 0) and   
 product = @product and   
 (CHARINDEX(','+ LineStatus+',',  
                ','+@LineStatus+',') > 0)    
 order by timestamp  
 Drop table #SpliceReport  
 return  
  End  
  
If @InputTeam = 'ALL' and @InputShift <> 'ALL' and @lineStatus <>'ALL' and @product is null  
  Begin  
     Select * from #SpliceReport   
 where (CHARINDEX(','+ Shift+',',  
                ','+@InputShift+',') > 0) and   
 (CHARINDEX(','+ LineStatus+',',  
                ','+@LineStatus+',') > 0)  
        order by timestamp  
 Drop table #SpliceReport  
 return  
  End  
  
  
-- For a specific team and shift  
If @InputTeam <> 'ALL' and @InputShift <> 'ALL' and @lineStatus ='ALL' and @product is not null  
  Begin  
     Select * from #SpliceReport   
 where (CHARINDEX(','+ team+',',  
                ','+@InputTeam+',') > 0) and   
 (CHARINDEX(','+ Shift+',',  
                ','+@InputShift+',') > 0) and product = @product     
 order by timestamp  
 Drop table #SpliceReport  
 return  
  End  
  
If @InputTeam <> 'ALL' and @InputShift <> 'ALL' and @lineStatus ='ALL' and @product is null  
  Begin  
     Select * from #SpliceReport   
 where (CHARINDEX(','+ team+',',  
                ','+@InputTeam+',') > 0) and   
 (CHARINDEX(','+ Shift+',',  
                ','+@InputShift+',') > 0)  
 order by timestamp  
 Drop table #SpliceReport  
 return  
  End  
  
If @InputTeam <> 'ALL' and @InputShift <> 'ALL' and @lineStatus <>'ALL' and @product is not null  
  Begin  
     Select * from #SpliceReport   
 where (CHARINDEX(','+ team+',',  
                ','+@InputTeam+',') > 0) and   
 (CHARINDEX(','+ Shift+',',  
                ','+@InputShift+',') > 0) and   
 product = @product and (CHARINDEX(','+ LineStatus+',',  
                ','+@LineStatus+',') > 0)   order by timestamp  
 Drop table #SpliceReport  
 return  
  End  
  
If @InputTeam <> 'ALL' and @InputShift <> 'ALL' and @lineStatus <>'ALL' and @product is null  
  Begin  
     Select * from #SpliceReport   
 where (CHARINDEX(','+ team+',',  
                ','+@InputTeam+',') > 0) and   
 (CHARINDEX(','+ Shift+',',  
                ','+@InputShift+',') > 0) and   
 (CHARINDEX(','+ LineStatus+',',  
                ','+@LineStatus+',') > 0)   order by timestamp  
 Drop table #SpliceReport  
 return  
  End  
  
If @InputTeam = 'ALL' and @InputShift = 'ALL' and @lineStatus ='ALL' and @product is not null  
  Begin  
    Select * from #SpliceReport where product = @product   order by timestamp  
 Drop table #SpliceReport  
 return  
  End  
  
If @InputTeam = 'ALL' and @InputShift = 'ALL' and @lineStatus ='ALL' and @product is null  
  Begin  
     Select * from #SpliceReport   order by timestamp  
 Drop table #SpliceReport  
 return  
  End  
  
If @InputTeam = 'ALL' and @InputShift = 'ALL' and @lineStatus <>'ALL' and @product is not null  
  Begin  
     Select * from #SpliceReport where  product = @product and  
       (CHARINDEX(','+ LineStatus+',',  
                ','+@LineStatus+',') > 0)   order by timestamp  
 Drop table #SpliceReport  
 return  
  End  
  
If @InputTeam = 'ALL' and @InputShift = 'ALL' and @lineStatus <>'ALL' and @product is null  
  Begin  
     Select * from #SpliceReport where (CHARINDEX(','+ LineStatus+',',  
                ','+@LineStatus+',') > 0)   order by timestamp  
 Drop table #SpliceReport  
 return  
  End  
  
  
----------------------------------------------------------------------------  
-- Error GOTO Statement or Stored Procedure Clean up:  
--  
-- Will perform anything below "ErrorCode:"  
--  
----------------------------------------------------------------------------  
  
ErrorCode:  
Print @ErrMsg  
  
 GRANT  EXECUTE  ON [dbo].[spLocal_ReportSplice]  TO [comxclient]
