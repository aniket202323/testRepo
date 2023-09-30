     CREATE PROCEDURE dbo.spLocal_ReportWaste  
  
-------------------------------------------------------------------------------  
-- MODIFICATION HISTORY  
-------------------------------------------------------------------------------  
--  2004-2-13   Tim Rogers  
--  Version    4.1.0  
--    Changes to reason code field lengths to accomadate 100 chars.  
-------------------------------------------------------------------------------  
--  2003-6-03   Jerome Ruwe  
--  Version    4.0.2  
--    Changes to reason code field lengths to accomadate 100 chars.  
-------------------------------------------------------------------------------  
--  2002-8-14   Jerome Ruwe  
--  Version    4.0.1  
--    Incorporated MSI code to allow for passing of multiple lines in  
--       @in_ProductionUnitDesc field  
--    New code requires MSI parsing sp SPCMN_REPORTCOLLECTIONPARSING  
--           Also requires modified Local_PG_Line_Schedule table per MSI  
-------------------------------------------------------------------------------  
--                Ugo Lapierre, Solutions et Technologies Industrielles Inc.  
--                Created  
--    Version     1.0.0  
---------------------------------------------------------------------------------  
--   2002-6-11    Joe Juenger  
--   Version   2.3.2  
--           Changed the inclusive 'between' keywords to '>=' and '<'   
--        exclusive conditions.  
---------------------------------------------------------------------------------  
--   2002-1-28    Joe Juenger  
--   Version   2.3.1  
--           Order by timestamp.  
---------------------------------------------------------------------------------  
--   2002-1-28    Joe Juenger  
--   Version   2.3.0  
--           Revise multi-shift,team, and status values for units other than   
--    converter.  
---------------------------------------------------------------------------------  
--   2002-1-22     Joe Juenger  
--   Version   2.2.2  
--           Revise Line Description to the return values.   
---------------------------------------------------------------------------------  
--   2002-1-7     Joe Juenger  
--   Version   2.2.1  
--           Add Line Description to the return values.    
---------------------------------------------------------------------------------  
--   2002-1-4     Joe Juenger  
--   Version   2.2.0  
--           Allow multiple Lines, Teams, Shifts and Line Status as input.   
---------------------------------------------------------------------------------  
--    2001-12     David Cornell  P&G  
--    Version     2.1.0  
--                Rewrote for improved performance, stopped sorting output.  
-------------------------------------------------------------------------------  
--    2001-09-17  Ugo Lapierre, Solutions et Technologies Industrielles Inc.  
--    Version     2.0.0  
--                Add product and line status as input to allow th sp to  
--                return data for a specific product or a specific line status  
---------------------------------------------------------------------------------  
-------------------------------------------------------------------------------  
-- spLocal_ReportWaste  
--  
-- Description  
--  
--    This procedure returns waste events for the specified time range,  
--    during the specified Shift, while the specified  
--    crew was working, on the specified line, while the line was making the  
--    specified product and while the line was in the specified status.  
--  
--    If a value of 'All' is specified for any of the following parameters  
--    they will not be used to limit the selection of variable tests:  
--  
--       Crew Description  
--       Shift Description  
--       Line Status  
--  
--    If a value of 0 is specified for any of the following parameters  
--    they will not be used to limit the selection of variable tests:  
--  
--       Product ID  
--  
-------------------------------------------------------------------------------  
-- Call Examples  
--  
-- For Unit = 'CR15AW Converter', All Teams, All Shifts, All Products, All Line Statuses  
--    spLocal_ReportWaste  '15-aug-01','16-aug-01','CR15AW Converter','All','All',0,'All'  
--  
  
--DECLARE  
  
   @in_StartTime           Datetime,      -- Start Time of Sample Set  
   @in_EndTime             DateTime,      -- End Time of Sample Set  
   @in_ProductionUnitDesc  varchar(2000),   -- Decsription of Production Unit; for Line  
   @in_CrewDesc            varchar(1250),   -- Crew Description or 'All' (Also called Team)  
   @in_ShiftDesc           varchar(8),   -- Shift Description or 'All'  
   @in_ProdID           int,           -- Primary Key of Product; 0 for all  
   @in_LineStatus          varchar(600)    -- Line Status or 'All'  
  
AS  
/*  
---------------------------------  
--TEST DATA  
   set @in_StartTime           ='5/1/2002 9:00:00'       -- Start Time of Sample Set  
   set @in_EndTime             ='5/1/2002 10:00:00'       -- End Time of Sample Set  
   set @in_ProductionUnitDesc  ='DIMP129 Converter'    -- Decsription of Production Unit; for Line  
   set @in_CrewDesc            ='All'     -- Crew Description or 'All' (Also called Team)  
   set @in_ShiftDesc           ='All'     -- Shift Description or 'All'  
   set @in_ProdID           =0             -- Primary Key of Product; 0 for all  
   set @in_LineStatus        ='All'--   
--------------------------------------  
*/  
  
Declare  
   @Master_PUIDString      VARCHAR(240),  
   @MasterLine_PUIDString  VARCHAR(240),  
   @Master_PUIDStringTemp   VARCHAR(240),  
   @Master_PUIDSingleInt    INT,  
   @MasterLine_PUIDSingleInt    INT,  
   @Master_PUIDSingleString  VARCHAR(6),  
   @include_crew            varchar(3),  
   @include_linestatus      varchar(3),  
   @include_product         varchar(3),  
   @include_result          varchar(3),  
   @include_shift           varchar(3),  
   @master_puid             int,  
   @prod_id              int,  
   @status_time             datetime,  
   @PL_Desc   VARCHAR(50),  
   @PL_ID   INT,  
----  
--  Output Variables  
----  
   @TimeStamp               datetime,  
   @Amount                  float,  
   @Units                   varchar(30),  
   @Type                    varchar(30),  
   @fault                   varchar(30),  
   @Location                varchar(75),  
   @Reason1                 varchar(50),  
   @Reason2                 varchar(50),  
   @Reason3                 varchar(50),  
   @Reason4                 varchar(50),  
   @Team                    varchar(25),  
   @Shift                   varchar(25),  
   @Product                 varchar(50),  
   @Status                  varchar(50),  
   @Comment                 varchar(255),  
   @Line_Desc      varchar(75),  
   @ErrMsg                  nVarChar(1000),   
   @StatusScheduleId     Int,   --for backpopulate  
   @UnitId      Int,   --for backpopulate  
   @PreviousStatusScheduleId  Int,   --for backpopulate  
   @Seconds      Int,   --for backpopulate  
   @MaxDateTime      DateTime,  --for backpopulate  
   @StartDateTime     DateTime,  --for backpopulate  
   @lblAll             nVarChar(50),  
   @PLDESCList      nVarChar(4000)  
-----------------------------------------  
--  Uncomment to output Processing Time  
-----------------------------------------  
--  ,@start_cpu           int  
--set @start_cpu = @@CPU_BUSY  
  
-- TABLE BELOW USED TO ELIMINATE CHARINDEX FUNCTION AGAINST PROD_DESC  
  
-----------------------------------------------------------------------------  
-- New Table Creation / Structure Below  
-----------------------------------------------------------------------------  
Create Table #PLIDList  
( RCDID     int,  
 PLID     int,  
 PLDESC     nVarChar(50),  
 MasterDesc   varchar(50),  
 MasterUnit    int,  
 STLSUnit   int)  
  
Create Table #Rejects   
( TimeStamp   datetime,  
      PadCount   float,  
      Units    varchar(30),  
      Type    Varchar(30),  
      Fault    varchar(30),  
      ConverterCycle   varchar(30),  
      Reason1       varchar(100),  
      Reason2    varchar(100),  
      Reason3    varchar(100),  
      Reason4    varchar(100),  
      Location   varchar(75),  
      Product    varchar(50),  
      Crew    varchar(25),  
      Shift    varchar(25),  
      LineStatus   varchar(50),  
      PLID    int,  
      PUID    int,  
 Comments   varchar(255),  
      Line_Desc   varchar(75))  
  
CREATE INDEX IDX_Rejects  
ON #Rejects(TimeStamp, PLID, PUID) ON [PRIMARY]  
-----------------------------------------------------------------------------  
  
----  
-- Define Output Temp Table  
----  
create table #outdata (  
   Timestamp               datetime,  
   Amount                  float,  
   Units                   varchar(30),  
   Type                    varchar(30),  
   Fault                   varchar(30),  
   Reason1                 varchar(100),  
   Reason2                 varchar(100),  
   Reason3                 varchar(100),  
   Reason4                 varchar(100),  
   Location                varchar(75),  
   Product                 varchar(50),  
   Team                    varchar(25),  
   Shift                   varchar(25),  
   Status                  varchar(50),  
   Comments                varchar(255),  
   Line_Desc     varchar(75))  
  
----------------------------------------------------------------------------  
-- Check Parameters: Establish default values  
----------------------------------------------------------------------------  
Set @lblAll    = 'All'  
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
CREATE INDEX IDX_LineStatus_UnitTime  
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
  
----------------------------------------------------------------------------  
-- Check Parameters: @in_StartTime  
----------------------------------------------------------------------------  
If @in_StartTime > @in_EndTime  
Begin  
 Select @ErrMsg = 'Start Date is greater than End Date'  
 GOTO ErrorCode  
End  
  
----------------------------------------------------------------------------  
-- Check Parameter: Period InComplete  
----------------------------------------------------------------------------  
If @in_EndTime > GetDate()  
Begin  
 Select @ErrMsg = 'Period is InComplete'  
End  
  
----------------------------------------------------------------------------  
-- String Parsing: Parse Line ID, also gets info assoicated Only to the Line  
-- e.g the Converter Unit ID, and Variables used in QA  
----------------------------------------------------------------------------  
If  @in_ProductionUnitDesc = '!null'  
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
  @PRMCollectionString = @in_ProductionUnitDesc, @PRMFieldDelimiter = null, @PRMRecordDelimiter = ',',   
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
-- Get Data: Reject Data  
----------------------------------------------------------------------------  
Insert into #Rejects (TimeStamp, PadCount, Units, Type, Fault, Reason1,  
 Reason2, Reason3, Reason4, Location, Product, Crew, Shift, LineStatus, PLID, PUID,  
 Comments, Line_Desc)  
Select  
 wed.TimeStamp as 'TimeStamp',  
 wed.amount as 'PadCount',  
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
 Inner Join ProductS P on PS.Prod_ID = P.Prod_ID   
 Left Join Crew_SCHEDULE CS on (pl.STLSUnit = CS.PU_ID and   
       CS.Start_TIME <= WED.TimeStamp and  
       (CS.End_TIME > WED.TimeStamp or CS.End_TIME IS null))  
 Left Join #Local_PG_Line_Status LPG on (pl.STLSUnit = LPG.Unit_ID and   
       LPG.Start_DATETIME <= WED.TimeStamp and  
       (LPG.End_DATETIME > WED.TimeStamp or LPG.End_DATETIME IS null))  
 Left Join Phrase PHR on LPG.Line_Status_ID = PHR.Phrase_ID  
Where  
 (wed.TimeStamp >= @in_StartTime and wed.TimeStamp < @in_EndTime)  
----------------------------------------------------------------------------  
  
----------------------------------------------------------------------------  
-- Copy data into the final (existing) output table  
----------------------------------------------------------------------------  
  
INSERT INTO #OutData(Timestamp, Amount, Units, Type, Fault,  
                     Reason1, Reason2, Reason3, Reason4, Location, Product,  
       Team, Shift, Status, Comments, Line_Desc)  
     SELECT TimeStamp, PadCount, Units, Type, Fault,  
     Reason1, Reason2, Reason3, Reason4, Location, Product,  
     Crew, Shift, LineStatus, Comments, Line_Desc  
     FROM #Rejects   
  
----  
-- Output  
----  
DROP TABLE #Rejects  
DROP TABLE #PLIDList  
DROP TABLE #Local_PG_Line_Status  
  
select @product=null  
select @product = prod_desc from products where prod_id = @prod_id  
  
-- The Stored Procedure result   
  
-- For a specific team and all shift  
If @in_CrewDesc <> 'ALL' and @in_shiftDesc = 'ALL' and @in_LineStatus ='ALL' and @product is not null  
  Begin  
     Select * from #OUTDATA   
 where (CHARINDEX(','+ team+',',  
                ','+@in_CrewDesc+',') > 0) and  
  product = @product   
 order by timestamp  
  
 Drop table #OUTDATA  
 return  
  End  
  
If @in_CrewDesc <> 'ALL' and @in_shiftDesc = 'ALL' and @in_linestatus ='ALL' and @product is null  
  Begin  
     Select * from #OUTDATA   
 where (CHARINDEX(','+ team+',',  
                ','+@in_CrewDesc+',') > 0)  
  order by timestamp  
 Drop table #OUTDATA  
 return  
  End  
  
If @in_CrewDesc <> 'ALL' and @in_shiftDesc = 'ALL' and @in_linestatus <>'ALL' and @product is not null  
  Begin  
     Select * from #OUTDATA   
 where (CHARINDEX(','+ team+',',  
                ','+@in_CrewDesc+',') > 0) and  
   product = @product and   
       (CHARINDEX(','+ Status+',',  
                ','+@in_linestatus+',') > 0)   
 order by timestamp  
 Drop table #OUTDATA  
 return  
  End  
  
If @in_CrewDesc <> 'ALL' and @in_shiftDesc = 'ALL' and @in_linestatus <>'ALL' and @product is null  
  Begin  
    Select * from #OUTDATA   
 where (CHARINDEX(','+ team+',',  
                ','+@in_CrewDesc+',') > 0) and   
       (CHARINDEX(','+ Status+',',  
                ','+@in_linestatus+',') > 0)     
 order by timestamp  
 Drop table #OUTDATA  
 return  
  End  
  
  
  
If @in_CrewDesc = 'ALL' and @in_shiftDesc <> 'ALL' and @in_linestatus ='ALL' and @product is not null  
  Begin  
     Select * from #OUTDATA   
 where (CHARINDEX(','+ Shift+',',  
                ','+@in_shiftDesc+',') > 0) and   
  product = @product   order by timestamp  
 Drop table #OUTDATA  
 return  
  End  
  
If @in_CrewDesc = 'ALL' and @in_shiftDesc <> 'ALL' and @in_linestatus ='ALL' and @product is null  
  Begin  
     Select * from #OUTDATA   
 where (CHARINDEX(','+ Shift+',',  
                ','+@in_shiftDesc+',') > 0 )   
 order by timestamp  
 Drop table #OUTDATA  
 return  
  End  
  
If @in_CrewDesc = 'ALL' and @in_shiftDesc <> 'ALL' and @in_linestatus <>'ALL' and @product is not null  
  Begin  
     Select * from #OUTDATA   
 where (CHARINDEX(','+ Shift+',',  
                ','+@in_shiftDesc+',') > 0) and   
 product = @product and   
 (CHARINDEX(','+ Status+',',  
                ','+@in_linestatus+',') > 0)    
 order by timestamp  
 Drop table #OUTDATA  
 return  
  End  
  
If @in_CrewDesc = 'ALL' and @in_shiftDesc <> 'ALL' and @in_linestatus <>'ALL' and @product is null  
  Begin  
     Select * from #OUTDATA   
 where (CHARINDEX(','+ Shift+',',  
                ','+@in_shiftDesc+',') > 0) and   
 (CHARINDEX(','+ Status+',',  
                ','+@in_linestatus+',') > 0)  
        order by timestamp  
 Drop table #OUTDATA  
 return  
  End  
  
  
-- For a specific team and shift  
If @in_CrewDesc <> 'ALL' and @in_shiftDesc <> 'ALL' and @in_linestatus ='ALL' and @product is not null  
  Begin  
     Select * from #OUTDATA   
 where (CHARINDEX(','+ team+',',  
                ','+@in_CrewDesc+',') > 0) and   
 (CHARINDEX(','+ Shift+',',  
                ','+@in_shiftDesc+',') > 0) and product = @product     
 order by timestamp  
 Drop table #OUTDATA  
 return  
  End  
  
If @in_CrewDesc <> 'ALL' and @in_shiftDesc <> 'ALL' and @in_linestatus ='ALL' and @product is null  
  Begin  
     Select * from #OUTDATA   
 where (CHARINDEX(','+ team+',',  
                ','+@in_CrewDesc+',') > 0) and   
 (CHARINDEX(','+ Shift+',',  
                ','+@in_shiftDesc+',') > 0)  
 order by timestamp  
 Drop table #OUTDATA  
 return  
  End  
  
If @in_CrewDesc <> 'ALL' and @in_shiftDesc <> 'ALL' and @in_linestatus <>'ALL' and @product is not null  
  Begin  
     Select * from #OUTDATA   
 where (CHARINDEX(','+ team+',',  
                ','+@in_CrewDesc+',') > 0) and   
 (CHARINDEX(','+ Shift+',',  
                ','+@in_shiftDesc+',') > 0) and   
 product = @product and (CHARINDEX(','+ Status+',',  
                ','+@in_linestatus+',') > 0)   order by timestamp  
 Drop table #OUTDATA  
 return  
  End  
  
If @in_CrewDesc <> 'ALL' and @in_shiftDesc <> 'ALL' and @in_linestatus <>'ALL' and @product is null  
  Begin  
     Select * from #OUTDATA   
 where (CHARINDEX(','+ team+',',  
                ','+@in_CrewDesc+',') > 0) and   
 (CHARINDEX(','+ Shift+',',  
                ','+@in_shiftDesc+',') > 0) and   
 (CHARINDEX(','+ Status+',',  
                ','+@in_linestatus+',') > 0)   order by timestamp  
 Drop table #OUTDATA  
 return  
  End  
  
If @in_CrewDesc = 'ALL' and @in_shiftDesc = 'ALL' and @in_linestatus ='ALL' and @product is not null  
  Begin  
    Select * from #OUTDATA where product = @product   order by timestamp  
 Drop table #OUTDATA  
 return  
  End  
  
If @in_CrewDesc = 'ALL' and @in_shiftDesc = 'ALL' and @in_linestatus ='ALL' and @product is null  
  Begin  
     Select * from #OUTDATA   order by timestamp  
 Drop table #OUTDATA  
 return  
  End  
  
If @in_CrewDesc = 'ALL' and @in_shiftDesc = 'ALL' and @in_linestatus <>'ALL' and @product is not null  
  Begin  
     Select * from #OUTDATA where  product = @product and  
       (CHARINDEX(','+ Status+',',  
                ','+@in_linestatus+',') > 0)   order by timestamp  
 Drop table #OUTDATA  
 return  
  End  
  
If @in_CrewDesc = 'ALL' and @in_shiftDesc = 'ALL' and @in_linestatus <>'ALL' and @product is null  
  Begin  
     Select * from #OUTDATA where (CHARINDEX(','+ Status+',',  
                ','+@in_linestatus+',') > 0)   order by timestamp  
 Drop table #OUTDATA  
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
  
----  
-- Clean up  
----  
-----------------------------------------  
--  Uncomment to output Processing Time  
-----------------------------------------  
--select  
--   @@CPU_BUSY - @start_cpu as 'CPU Milliseconds'  
  
  
  
  
  
  