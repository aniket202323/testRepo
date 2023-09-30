     CREATE PROCEDURE dbo.spLocal_ReportProd_Event  
/*  
---------------------------------------------------------------------------------------  
On 03-Oct-03 JJR  Version 3.1.2  
MOD  More new code effects #Production data; 1st record has been returned as a  
  partial event & was being updated by PartialProduction cursor. New code  
  tests the 1st record to determine if it is the start of an event AND  
  that it's EndTime is Greater Than or Equal To the Timestamp of the   
  NEXT Event in the Events table and if so handles it as a   
  complete event rather than a partial event.   
  Removed join to PU_Characteristics table; replaced with join to   
  Characteristics table against Products.Prod_Desc to Char_Desc  
---------------------------------------------------------------------------------------  
On 23-Sep-03 JJR  Version 3.1.1  
MOD  Misc. 'speed-up' modifications (table structures; indexes;   
  NVarchar convert to Varchar data type, cursors; etc.)  
---------------------------------------------------------------------------------------  
On 22-Sep-03 JJR  Version 3.1.0  
MOD  New code effects #Production data; 1st record has been returned as a  
  partial event & was being updated by PartialProduction cursor. New code  
  tests the 1st record to determine if it is the start of an event and  
  if so handles it as a complete event rather than a partial event.   
---------------------------------------------------------------------------------------  
Modified by Reid Minnich  
On 05-September-03  Version 3.0.9  
Change  remove the '.f_cv' on input tags for new configuration standard  
---------------------------------------------------------------------------------------  
Modified by Jerome Ruwe  
On 20-November-02  Version 3.0.8  
Change  Removed code within the ProductionEnd cursor that had been incorporating  
  data from the packer unit into the #Production table.  
---------------------------------------------------------------------------------------  
Modified by Jerome Ruwe  
On 08-October-02  Version 3.0.7  
Change  Updated the 'filters' applied to the output record set so as to compare  
  the Prod_ID against the passed parameter @Prod_ID rather than comparing  
  the text description (the sp was failing when run for a specific product)  
---------------------------------------------------------------------------------------  
Modified by Jerome Ruwe  
On 08-October-02  Version 3.0.6  
Change  Converted the following fields in the outut record set to numeric data  
  type (int): Total_Pads, Running_Scrap, Stop_Scrap, Linespeed_Target,   
  Linespeed_Actual, Total_Cases, ProdperBag, BagsperCase, CasesperPallet,   
  ProdperStat.  
---------------------------------------------------------------------------------------  
Modified by Jerome Ruwe  
On 06-September-02  Version 3.0.5  
FIX  Removed code limiting records populating the #Local_PG_Line_Status  
  table to only those within 6 months of the @InputStart_Time value.  
  The lack of EndTIme values for historical dates in this table was causing faulty look-ups  
  for the linestatus value.  
---------------------------------------------------------------------------------------  
Modified by Jerome Ruwe  
On 19-August-02   Version 3.0.4  
Change  Added code outside ProductionEnd cursor to handle the "Non Event"  
  scenario (eg. if report is run for a short time-frame that is between  
  production events, one partial record should be returned).  
---------------------------------------------------------------------------------------  
Modified by Jerome Ruwe  
On 19-August-02   Version 3.0.3  
Change  Updated LineDesc field in the #Production table to reflect the PL_DESC  
  field from Prod_Lines. The field had been returning the PU_Desc field  
  (eg. had been 'DIMP129 Converter'; should be 'DIMP129') as the added  
  descriptive text was causing problems with the Excel VBA portion of   
  the report.  
---------------------------------------------------------------------------------------  
Modified by Jerome Ruwe  
  
On 15-August-02   Version 3.0.2  
Change  New means of calculating linespeed_act similar to means of calculating   
  RunningScrap and StopScrap (utilizes input_tag as means of identifying  
  proper spec variable)  
---------------------------------------------------------------------------------------  
Modified by Jerome Ruwe  
On 14-August-02   Version 3.0.1  
Change  Incorporated MSI code to allow for passing of multiple lines in  
  @InputUnitDesc field (calls MSI parsing sp).  
---------------------------------------------------------------------------------------  
Modified by Jerome Ruwe  
On 13-August-02   Version 3.0.1  
Change  Fix: Added code to calculate average linespeed target as MSI code had been   
  looking for a direct dependancy from the endtime value to the result-on  
  field in the Tests table (direct relationship not always present)  
---------------------------------------------------------------------------------------  
Created by Ugo Lapierre, Solutions et Technologies Industrielles Inc.  
On date unknown   Version : 1.0.0  
--------------------------------------------------------------------------------------  
Modified by Ugo Lapierre, Solutions et Technologies Industrielles Inc.  
On date unknown   Version : 1.1.0  
Change  Change the sp to allow half event at the beginning of event and at  
  the edn of the event.  
--------------------------------------------------------------------------------------  
Modified by Ugo Lapierre, Solutions et Technologies Industrielles Inc.  
On 17-sep-01   Version   2.0.0  
Change  Add product and line status as input to allow th sp to   
  return data for a specific product or a specific line status  
--------------------------------------------------------------------------------------  
Modified by Ugo Lapierre, Solutions et Technologies Industrielles Inc.  
On 14-dec-01   Version   2.1.0  
Change  Change source of production status.  Use custom datatype instead of production status  
  table.  
--------------------------------------------------------------------------------------  
Modified by Joe Juenger  
On 15-Jan-02   Version   2.2.1  
Change  Added capability to query by multiple line, team, shift, line status.  
--------------------------------------------------------------------------------------  
Modified by Joe Juenger  
On 23-Jan-02   Version   2.3.0  
Change  Added line description to return values.  
--------------------------------------------------------------------------------------  
Modified by Joe Juenger  
On 23-Jan-02   Version   2.3.1  
Change  Added FLOOR function to round-down the LineSpeed (actual and target)  
  values to integers.  
--------------------------------------------------------------------------------------  
Modified by Joe Juenger  
On 23-Jan-02   Version   2.3.2  
Change  Fix: Because an end time is also the start time of the next shift  
  in the Crew_Scedule, changed "where @endtime >= Start_time" to  
  "where @endtime > Start_time".  This returns the accurate shift and   
  team per record.  
--------------------------------------------------------------------------------------  
Modified by Joe Juenger  
On 23-Jan-02   Version   2.3.3  
Change  Fix: Return valid line speed targets for partial records.  
  Return NULL for actual line speed for partial records.  
--------------------------------------------------------------------------------------  
Modified by Joe Juenger  
On 23-Jan-02   Version   2.3.4  
Change  Fix: Allow multiline to return shift,team, and status values per units  
  other than converter.  
--------------------------------------------------------------------------------------  
Modified by Joe Juenger  
On 29-Jan-02   Version   2.4.0  
Change  Add functionality to calculate uptime and actual line speed   
  for partial records.  Added PE_UPTIME_CURSOR to get uptime (mirrors  
  spLocal_ReportsDowntime processing).    
--------------------------------------------------------------------------------------  
Modified by Joe Juenger  
On 30-Jan-02   Version 2.4.1  
  
Change  Filter to remove extraneous records outside the timeframe.  
--------------------------------------------------------------------------------------  
Modified by Joe Juenger  
On 31-Jan-02   Version   2.4.2  
Change  The team, shift, status, and product are now associated with the  
  start time, not end time, for the last partial record.  
--------------------------------------------------------------------------------------  
Modified by Joe Juenger  
On 03-Mar-02   Version   2.4.3  
Change  If a valid start or end time of a shift are not included in the   
  timeframe (very small timeframes), add cursor loop of product lines to  
  get a single, partial record per line.  Get target, ahift, and status info.  
--------------------------------------------------------------------------------------  
Modified by Joe Juenger  
On 11-Apr-02   Version   2.4.4  
Change  Added functionality to return the actual number of cases produced, in addition  
  to number of pads per bag, bags per case, Cases epr Pallet, and Pads pre stat.  
  Total cases is calculated based on the 5-minute variable 'Cases Produced'.  
---------------------------------------------------------------------------------------  
Modified by Joe Juenger  
On 11-Apr-02   Version   2.4.5  
Change  Before returning total pads, scrap, stop scrap, line speed, and total cases,  
  run the ISNULL() function and convert to 0 if null.  
---------------------------------------------------------------------------------------  
Modified by Joe Juenger  
On 15-Apr-02   Version   2.5.0  
Change  Total pads had been returned based on the 'shiftly' variable; now based  
  on '5-minute' variable.  New checks for divide-by-zero errors in  
  actual speed.  Run ISNULL() on actual speed - if true, convert ot zero.  
---------------------------------------------------------------------------------------  
Modified by Joe Juenger  
On 16-Apr-02   Version   2.5.1  
Change  Fix: 'NextStatus' was picking up next status for other lines at the same plant.    
  Added conditions to where clause.  
---------------------------------------------------------------------------------------  
Modified by Joe Juenger  
On 26-Apr-02   Version   2.5.2  
Change  Fix: Prod Line description based on line ID, not master prod unit ID.  
---------------------------------------------------------------------------------------  
Modified by Joe Juenger  
On 1-May-02   Version   2.5.3  
Change  Fix: Set the event start time equal to the input time where the start time  
  occurs prior to input time.  Fix on multi-line queries.  
---------------------------------------------------------------------------------------  
Modified by Joe Juenger  
On 31-May-02   Version   2.5.4  
Change  Fix: If Input Start Time < Event Start Time for partial records, use input start time.  
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
------------------------------------------------  
--TEST DATA  
--  
  Set @InputStart_Time  = '6/1/02 9:00 AM'  
  Set @InputEnd_Time  = '6/1/02 10:00 AM'  
  Set @InputUnitDesc = 'DIMP129 Converter'       
  Set @InputTeam  = 'All'  
  Set @InputShift  = 'All'  
  Set @Prod_id  = 0  
  Set @LineStatus = 'All'  
-------------------------------------------------  
*/  
AS  
Declare  
@total_uptime  float,  
@Uptime   Varchar(30),  
@Product  varchar(25),  
@Seconds  Int, --for backpopulate  
@ErrMsg   Varchar(1000),  
@@EndTime  datetime,  
@@PUID   int,  
@@PLID   int,  
@@ID   int,  
@@StartTime  datetime,  
@@NextStartTime  datetime,  
@PadsPerBagSpecD int,  
@CasesPerPalletSpecID int,  
@PartPadCountVarID int,  
@PartCaseCount  int,  
@@TypeOfEvent  Varchar(50),  
@PadsPerBagSpecID int,  
@BagsPerCaseSpecID int,  
@PartCaseCountVarID int,  
@CompSpeedTargetVarID int,  
@PartSpeedActVarID int,  
@PartSpeedAct  int,  
@PadsPerStatSpecID int,  
@PartRunCountVarID int,  
@SpeedTarget  int,  
@PartPadCount  int,  
@PartRunCount  int,  
@PartStartUPCount int,  
@PartStartUPCountVarID int,  
@@CursorValue  Varchar(50),  
@RPTPadCountTag  Varchar(50), -- = 'PRPadCNTLow'  
@RPTCaseCountTag Varchar(50), -- = 'PRCaseCount'   
@RPTRunCountTag  Varchar(50), -- = 'PRRunCNTLow'  
@RPTStartupCountTag Varchar(50), -- = 'PRSTUPCNTLow',  
@RPTSpeedActTag  Varchar(50), -- = 'PRConverter_Speed_Actual',  
@RPTConverterSpeedTag Varchar(50), -- = 'PRConvertER_Speed_Target',  
@RPTPartSpeedActTag Varchar(50), -- = 'PRConvertER_Speed_Actual',  
@RPTPadsPerStat  Varchar(50), -- = 'Pads Per Stat',  
@RPTPadsPerBag  Varchar(50), -- = 'Pads Per Bag',  
@RPTBagsPerCase  Varchar(50), -- = 'BagS Per Case',  
@RPTCasesPerPallet Varchar(50), -- = 'Cases Per Pallet',  
@RPTSpecProperty Varchar(50), -- = 'RE_Product Information',  
@QVPQM   Varchar(50), -- = 'QV PQM',  
@QVMeasurableAttr Varchar(50), -- = 'QV Measurable Attributes',  
@QAPadAttr  Varchar(50), -- = 'QA Pad Attributes',  
@QAPackageAttr  Varchar(50), -- = 'QA Package Attributes',  
@QACaseAttr  Varchar(50), -- = 'QA Case Attributes',  
@QVReEstablish  Varchar(50), -- = 'QV ReEstablish',  
@QAReEstablish  Varchar(50), -- = 'QA ReEstablish',  
@RPTPLIDList  Varchar(4000),-- = null  
@SpecPropertyID  int,  
@Now   datetime,  
@RPTGroupBy  Varchar(50),  
@Total_Downtime  float,  
@@UpTime  float,  
@Avg_Linespeed_Calc float,  
@Act_Linespeed_Calc float,  
@lblAll   Varchar(50)  
Print convert(varchar(25), getdate(), 120) + ' Creating #Production Table'  
Create Table #Production  
( StartTIME   DATETIME,  
 EndTIME    DATETIME,  
 PLID    int,  
 PUID    int,  
 Product    Varchar(50),  
 Prod_ID    int,  
 Crew    Varchar(25),  
 Shift    Varchar(25),  
 LineStatus   Varchar(25),  
 TotalPad   float,  
 RunningScrap   float,  
 Stopscrap   float,  
 LineSpeedTAR   float,  
 TotalCaseS   float,  
 ProdPerBag   float,  
 BagSPerCase   float,  
 CasesPerPallet   float,  
 ProdPerStat   float,  
 ID    int IDENTITY,  
 TypeOfEvent   Varchar(50),  
 LineDesc   Varchar(50),  
 Uptime    float,  
 LineSpeed_Act   float)  
/*  
CREATE INDEX IDX_Production  
ON #Production(StartTime, EndTime, PLID, PUID) ON [PRIMARY]  
*/  
Print convert(varchar(25), getdate(), 120) + ' Obtaining Default Values'  
----------------------------------------------------------------------------  
-- Check Parameters: Establish default values  
----------------------------------------------------------------------------  
Set @RPTPadCountTag    = 'PRPadCNTLow'  
Set @RPTCaseCountTag   = 'PRCaseCount'  
Set @RPTRunCountTag    = 'PRRunCNTLow'  
Set @RPTSpeedActTag  = 'PRConverter_Speed_Actual'  
Set @RPTStartupCountTag  = 'PRSTUPCNTLow'  
Set @RPTConverterSpeedTag  = 'PRConverter_Speed_Target'  
Set @RPTPartSpeedActTag  = 'PRConverter_Speed_Actual'  
Set @RPTPadsPerStat   = 'Pads Per Stat'  
Set @RPTPadsPerBag   = 'Pads Per Bag'  
Set @RPTBagsPerCase   = 'Bags Per Case'  
Set @RPTCasesPerPallet   = 'Cases Per Pallet'  
Set @RPTSpecProperty   = 'RE_Product Information'  
Set @QVPQM    = 'QV PQM'  
Set @QVMeasurableAttr   = 'QV Measurable Attributes'  
Set @QAPadAttr   = 'QA Pad Attributes'  
Set @QAPackageAttr  = 'QA Package Attributes'  
Set @QACaseAttr   = 'QA Case Attributes'  
Set @QVReEstablish  = 'QV ReEstablish'  
Set @QAReEstablish  = 'QA ReEstablish'  
Set @lblAll    = 'All'  
   
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
-- Check Parameter: Specifications  
----------------------------------------------------------------------------  
Print convert(varchar(25), getdate(), 120) + ' Obtaining Spec_IDs'  
Select @SpecPropertyID = PROP_ID  
 From Product_Properties  
 Where PROP_DESC = @RPTSpecProperty  
Select @PadsPerStatSpecID = Spec_ID  
 From Specifications  
 Where Spec_DESC = @RPTPadsPerStat  
  and PROP_ID = @SpecPropertyID  
Select @PadsPerBagSpecID = Spec_ID  
 From Specifications  
 Where Spec_DESC = @RPTPadsPerBag  
  and PROP_ID = @SpecPropertyID  
Select @BagsPerCaseSpecID = Spec_ID  
 From Specifications  
 Where Spec_DESC = @RPTBagSPerCase  
  and PROP_ID = @SpecPropertyID  
Select @CasesPerPalletSpecID = Spec_ID  
 From Specifications  
 Where Spec_DESC = @RPTCasesPerPallet  
  and PROP_ID = @SpecPropertyID  
Print convert(varchar(25), getdate(), 120) + ' Creating #PLIDList and parsing PLID String'  
Create Table #PLIDList  
( RCDID     int,  
 PLID     int,  
 PLDESC     Varchar(50),  
 ConvUnit    int,  
 SpliceUnit    int,  
 Packerunit    int,  
 QualityUnit   int,  
 ProcUnit    int,  
 PartPadCountVarID  int,  
 CompPadCountVarID  int,  
 PartCaseCountVarID  int,  
 PartRunCountVarID  int,  
 CompRunCountVarID  int,  
 CompSpeedActVarID  int,  
 PartStartUPCountVarID  int,  
 CompStartUPCountVarID  int,  
 CompSpeedTargetVarID  int,  
 PartSpeedActVarID  int,  
 QVPQMPUGID   int,  
 QVMeasurableAttrPUGID  int,  
 QAPadAttrPUGID   int,  
 QAPackageAttrPUGID  int,  
 QACaseAttrPUGID   int,  
 QVReEstablishPUGID  int,  
 QAReEstablishPUGID  int)  
   
----------------------------------------------------------------------------  
-- String Parsing: Parse Line ID, also gets info assoicated Only to the Line  
-- e.g the Converter Unit ID, and Variables used in QA  
----------------------------------------------------------------------------  
If  @InputUnitDesc = '!null'  
Begin  
 Insert #PLIDList (PLID,PLDESC)  
  Select PL_ID, PL_DESC  
  From Prod_Lines  
End  
Else  
Begin  
 Insert #PLIDList (RCDID, PLDesc)  
  Exec SPCMN_ReportCollectionParsing  
  @PRMCollectionString = @InputUnitDesc, @PRMFieldDelimiter = null, @PRMRecordDelimiter = ',',   
  @PRMDataType01 = 'Varchar(50)'  
 --  
 --Update #PLIDList Set PLDESC = PL.PL_DESC  
 -- From #PLIDList  
 -- Join Prod_Lines PL on PLID = PL.PL_ID  
 --  
 Update #PLIDList Set PLID = PU.PL_ID  
  From #PLIDList  
  --Join Prod_Lines PL on PLDESC = PL.PL_DESC  
  Join Prod_Units PU on PLDESC = PU.PU_DESC  
   
End  
Print convert(varchar(25), getdate(), 120) + ' Updates to #PLIDList Table'  
Update TPL Set ConvUnit = PU.PU_ID  
 From #PLIDList TPL  
 Join Prod_Units PU on TPL.PLID = PU.PL_ID and PU.PU_DESC like '%Converter'  
Update TPL Set SpliceUnit = PU.PU_ID  
 From #PLIDList TPL  
 Join Prod_Units PU on TPL.PLID = PU.PL_ID and PU.PU_DESC like '%Splicers'  
Update TPL Set Packerunit = PU.PU_ID  
 From #PLIDList TPL  
 Join Prod_Units PU on TPL.PLID = PU.PL_ID and PU.PU_DESC like '%Packer'  
Update TPL Set QualityUnit = PU.PU_ID  
 From #PLIDList TPL  
 Join Prod_Units PU on TPL.PLID = PU.PL_ID and PU.PU_DESC like '%Quality'  
Update TPL Set ProcUnit = PU.PU_ID  
 From #PLIDList TPL  
 Join Prod_Units PU on TPL.PLID = PU.PL_ID and PU.PU_DESC like '%Process'  
Update TPL Set PartPadCountVarID = VAR_ID  
 From #PLIDList TPL  
 Join Variables V on TPL.ConVUnit = V.PU_ID  
  and V.Event_Type IN(0,5)  
  and V.INPUT_Tag Like '%'+ @RPTPadCountTag + '%'  
  and V.DATA_Type_ID IN(1,2)  
Update TPL Set CompPadCountVarID = VAR_ID  
 From #PLIDList TPL  
 Join Variables V on TPL.ConVUnit = V.PU_ID  
  and V.Event_Type = 1  
  and V.INPUT_Tag Like '%'+ @RPTPadCountTag + '%'  
  and V.DATA_Type_ID IN(1,2)  
Update TPL Set PartCaseCountVarID = VAR_ID  
 From #PLIDList TPL  
 Join Variables V on TPL.ConVUnit = V.PU_ID  
  and V.Event_Type IN(0,5)  
  and V.INPUT_Tag Like '%'+ @RPTCaseCountTag + '%'  
  and V.DATA_Type_ID IN(1,2)  
Update TPL Set PartRunCountVarID = VAR_ID  
 From #PLIDList TPL  
 Join Variables V on TPL.ConVUnit = V.PU_ID  
  and V.Event_Type IN(0,5)  
  and V.INPUT_Tag Like '%'+ @RPTRunCountTag + '%'  
  and V.DATA_Type_ID IN(1,2)  
Update TPL Set CompRunCountVarID = VAR_ID  
 From #PLIDList TPL  
 Join Variables V on TPL.ConVUnit = V.PU_ID  
  and V.Event_Type = 1  
  and V.INPUT_Tag Like '%'+ @RPTRunCountTag + '%'  
  and V.DATA_Type_ID IN(1,2)  
-- 8/15/02 JJR: New code below for calculating linespeed_act  
Update TPL Set CompSpeedActVarID = VAR_ID  
 From #PLIDList TPL  
 Join Variables V on TPL.ConVUnit = V.PU_ID  
  and V.Event_Type = 1  
  and V.INPUT_Tag Like '%'+ @RPTSpeedActTag + '%'  
  and V.DATA_Type_ID IN(1,2)  
Update TPL Set CompStartUPCountVarID = VAR_ID  
 From #PLIDList TPL  
 Join Variables V on TPL.ConVUnit = V.PU_ID  
  and V.Event_Type = 1  
  and V.INPUT_Tag Like '%'+ @RPTStartUPCountTag + '%'  
  and V.DATA_Type_ID IN(1,2)  
Update TPL Set PartStartUPCountVarID = VAR_ID  
 From #PLIDList TPL  
 Join Variables V on TPL.ConVUnit = V.PU_ID  
  and V.Event_Type IN(0,5)  
  and V.INPUT_Tag Like '%'+ @RPTStartUPCountTag + '%'  
  and V.DATA_Type_ID IN(1,2)  
Update TPL Set CompSpeedTargetVarID = VAR_ID  
 From #PLIDList TPL  
 Join Variables V on TPL.ConVUnit = V.PU_ID  
  and V.Event_Type = 1  
  and V.INPUT_Tag Like '%'+ @RPTConvertERSpeedTag + '%'  
  and V.DATA_Type_ID IN(1,2)  
-- 8/16/02 JJR: New code for determining linespeed_act (partial event) below  
Update TPL Set PartSpeedActVarID  = VAR_ID  
 From #PLIDList TPL  
 Join Variables V on TPL.ConVUnit = V.PU_ID  
  and V.Event_Type = 1  
  and V.INPUT_Tag Like '%'+ @RPTPartSpeedActTag + '%'  
  and V.DATA_Type_ID IN(1,2)  
Update TPL Set QVPQMPUGID = PUG.PUG_ID  
 From #PLIDList TPL  
 Join PU_GROUPS PUG on TPL.QUALITYUnit = PUG.PU_ID  
  and PUG.PUG_DESC = @QVPQM  
Update TPL Set QVMeasurableAttrPUGID = PUG.PUG_ID  
 From #PLIDList TPL  
 Join PU_GROUPS PUG on TPL.QUALITYUnit = PUG.PU_ID  
  and PUG.PUG_DESC = @QVMeasurableAttr  
Update TPL Set QAPadAttrPUGID = PUG.PUG_ID  
 From #PLIDList TPL  
 Join PU_GROUPS PUG on TPL.QUALITYUnit = PUG.PU_ID  
  and PUG.PUG_DESC = @QAPadAttr  
Update TPL Set QAPackageAttrPUGID = PUG.PUG_ID  
 From #PLIDList TPL  
 Join PU_GROUPS PUG on TPL.QUALITYUnit = PUG.PU_ID  
  and PUG.PUG_DESC = @QAPackageAttr  
Update TPL Set QACaseAttrPUGID = PUG.PUG_ID  
 From #PLIDList TPL  
 Join PU_GROUPS PUG on TPL.QUALITYUnit = PUG.PU_ID  
  and PUG.PUG_DESC = @QACaseAttr  
Update TPL Set QVReEstablishPUGID = PUG.PUG_ID  
 From #PLIDList TPL  
 Join PU_GROUPS PUG on TPL.QUALITYUnit = PUG.PU_ID  
  and PUG.PUG_DESC = @QVReEstablish  
Update TPL Set QAReEstablishPUGID = PUG.PUG_ID  
 From #PLIDList TPL  
 Join PU_GROUPS PUG on TPL.QUALITYUnit = PUG.PU_ID  
  and PUG.PUG_DESC = @QAReEstablish  
-------------------------------------------------------------------------------  
-- Initialize variables/constants  
-------------------------------------------------------------------------------  
SELECT @Seconds = 0  
----------------------------------------------------------------------------  
-- Get Data: Production  
----------------------------------------------------------------------------  
Print convert(varchar(25), getdate(), 120) + ' Getting Production Data'  
Insert #Production  
 (EndTIME, PLID, PUID, TypeOfEvent)  
 Select E.TimeStamp, TPL.PLID, E.PU_ID, 'Complete'  
 From #PLIDList TPL  
 Join Events E on TPL.ConVUnit = E.PU_ID  
  and E.TimeStamp > @InputStart_Time  
  and E.TimeStamp <= @InputEnd_Time  
Declare ProductionEnd INSENSITIVE Cursor For  
 (Select ConvUnit, PLID  
 From #PLIDList  
 -- 11/20/02 Removed per Tim R as per no packer data desired from sp  
 --Union Select Packerunit, PLID  
 --From #PLIDList  
 )  
 For Read Only  
Open ProductionEnd  
FETCH NEXT From ProductionEnd into @@PUID, @@PLID  
While @@Fetch_Status = 0  
Begin  
 Set @@EndTime = null  
 Select @@EndTime = Max(EndTime)  
  From #Production  
  Where PUID = @@PUID  
 --  
 If @@EndTime <> @InputEnd_Time  
  Insert #Production  
   (PUID, PLID, StartTIME, EndTime, TypeOfEvent)  
   Values (@@PUID, @@PLID, @InputEnd_Time, @InputEnd_Time, 'Partial')  
 --   
   
 Fetch Next From ProductionEnd into @@PUID, @@PLID  
End  
Close ProductionEnd  
Deallocate ProductionEnd  
If @@EndTime Is Null  -- 8/19/02 JJR New Code for "No Event" scenario   
  Insert #Production  
   (PUID, PLID, StartTIME, EndTime, TypeOfEvent)  
   Values (@@PUID, @@PLID, @InputStart_Time, @InputEnd_Time, 'Partial')  
    -- End 8/19/02 JJR New Code  
Declare ProductionStart INSENSITIVE Cursor For  
 (Select ID, EndTIME, PUID  
 From #Production)  
 For Read Only  
Open ProductionStart  
FETCH NEXT From ProductionStart into @@ID, @@EndTIME, @@PUID  
While @@Fetch_Status = 0  
Begin  
 Set @@StartTime = null  
 Select @@StartTime = MAX(EndTIME)  
  From #Production  
  Where PUID = @@PUID  
   and EndTIME < @@EndTIME  
 --  
 Update #Production  
  Set StartTIME = COALESCE(@@StartTIME, @InputStart_Time),   
   TypeOfEvent =   
    Case  
     When @@StartTIME IS null THEN 'Partial'  
     Else TypeOfEvent  
    End  
 Where ID = @@ID  
 --  
 Fetch Next From ProductionStart into @@ID, @@EndTIME, @@PUID  
End  
Close ProductionStart  
Deallocate ProductionStart  
Print convert(varchar(25), getdate(), 120) + ' Updating Team, Shift, Line Production Data'  
Update #Production  
 Set Product = P.Prod_Desc,   
     Prod_ID = P.Prod_ID,   
     Crew = cs.Crew_DESC,   
     Shift = cs.Shift_DESC,   
     LineStatus = phr.Phrase_Value,  
     TotalPad = Convert(float, TPad.RESULT),   
     RunningScrap = Convert(float, TRun.RESULT),  
     Stopscrap = Convert(float, TSTOP.RESULT),  
     LineSpeedTAR = Convert(float, TSpeed.RESULT),  
     LineSpeed_Act = Convert(float, TSpeed.Result),  
       
     ProdPerBag = Convert(float, asBag.Target),  
     BagSPerCase = Convert(float, asCase.Target),  
     CasesPerPallet = Convert(float, aspallet.Target),  
     ProdPerStat = Convert(float, asStat.Target)  
    
 From #Production tpt  
 Join #PLIDList tpl on tpt.PLID = tpl.PLID  
 Join Production_Starts PS on tpl.ConvUnit = PS.PU_ID  
  and tpt.EndTime >= ps.Start_Time   
  and (tpt.EndTime < ps.End_Time or ps.End_Time IS null)  
 Join Products P on ps.Prod_ID = P.Prod_ID  
 Left Join Crew_Schedule cs on tpl.ConvUnit = cs.PU_ID  
  and tpt.EndTime > cs.Start_Time   
  and (tpt.EndTime <= cs.End_Time or cs.End_Time IS null)  
 Left Join Local_PG_Line_Status LPG on tpl.ConvUnit = lpg.Unit_ID  
  and tpt.EndTime > lpg.Start_DateTime   
  and (tpt.EndTime <= lpg.End_DateTime or lpg.End_DateTime IS null)  
 Left Join Phrase phr on lpg.Line_Status_ID = phr.Phrase_ID  
 Left Join TESTS TPad on TPL.CompPadCountVarID = TPad.VAR_ID  
  and TPad.RESULT_on = TPT.EndTIME  
 Left Join TESTS TRun on TPL.CompRunCountVarID = TRun.VAR_ID  
  and TRun.RESULT_on = TPT.EndTIME  
 Left Join TESTS TSTOP on TPL.CompStartUPCountVarID = TSTOP.VAR_ID  
  and TSTOP.RESULT_on = TPT.EndTIME  
 -- Need to calc average line speed from tests table  
 -- where results between starttime and endtime of production event  
 Left Join TESTS TSpeed on TPL.CompSpeedTargetVarID = TSpeed.VAR_ID  
  and TSpeed.RESULT_ON = TPT.EndTIME  
 -------------------------------------------------------------------  
 --10/03/03 JJR Removed join to PU_Characteristics table  
 --             Replaced with join to Characteristics table against  
 --        Products.Prod_Desc to Char_Desc  
 -------------------------------------------------------------------   
 --Left Join PU_CHARACTERISTICS PUC on TPL.ConVUnit = PUC.PU_ID  
 -- and P.Prod_ID = PUC.Prod_ID  
 Join CHARACTERISTICS PUC on P.Prod_Desc = PUC.Char_Desc  
 -- 8/15/02 JJR: New code for calculating linespeed_act below  
 Left Join TESTS TSpeedAct on TPL.CompSpeedActVarID  = TSpeedAct.VAR_ID  
  and TSpeedAct.RESULT_on = TPT.EndTIME   
 --   
 Left Join Active_Specs asBag on @PadsPerBagSpecID = asBag.Spec_ID  
  and PUC.CHAR_ID = asBag.CHAR_ID  
  and asBag.EFFECTIVE_DATE <= TPT.EndTIME  
  and (asBag.EXPIRATIon_DATE > TPT.EndTIME or asBag.EXPIRATIon_DATE IS null)  
   
 Left Join ACTIVE_SpecS asCase on @BagsPerCaseSpecID = asCase.Spec_ID  
  and PUC.CHAR_ID = asCase.CHAR_ID  
  and asCase.EFFECTIVE_DATE <= TPT.EndTIME  
  and (asCase.EXPIRATIon_DATE > TPT.EndTIME or asCase.EXPIRATIon_DATE IS null)  
 Left Join ACTIVE_SpecS asStat on @PadsPerStatSpecID = asStat.Spec_ID  
  and PUC.CHAR_ID = asStat.CHAR_ID  
  and asStat.EFFECTIVE_DATE <= TPT.EndTIME  
  and (asStat.EXPIRATIon_DATE > TPT.EndTIME or asStat.EXPIRATIon_DATE IS null)  
 Left Join ACTIVE_SpecS asPallet on @CasesPerPalletSpecID = asPallet.Spec_ID  
  and PUC.CHAR_ID = asPallet.CHAR_ID  
  and asPallet.EFFECTIVE_DATE <= TPT.EndTIME  
  and (asPallet.EXPIRATION_DATE > TPT.EndTIME or asPallet.EXPIRATION_DATE IS null)  
---------------------------------------------------------------------------------------------  
-- JJR Code below updates the 1st record of the #Production Table. If the first  
-- record's start time is equal to the start of an event (Events table) AND the EndTime  
-- of the #Production first record is Greater Than or Equal to the Timestamp of the NEXT event,  
-- the TypeofEvent field is updated to 'Complete' and will be skipped by PartialProduction cursor  
---------------------------------------------------------------------------------------------  
Select @@StartTime = MIN(StartTime) From #Production  
Select @@EndTime = MIN(EndTime) From #Production  
Select @@NextStartTime = MIN(Timestamp) from Events   
Join #PLIDList tp on tp.ConvUnit = Events.PU_ID  
Where Timestamp > @@StartTime  
If (Select Timestamp from Events   
Join #PLIDList tp on tp.ConvUnit = Events.PU_ID  
Where Timestamp = @@StartTime  
AND @@EndTime >= @@NextStartTime) IS NOT NULL  
BEGIN   
Update #Production  
Set TypeofEvent = 'Complete'  
Where StartTime = @@StartTime  
END  
---------------------------------------------------------------------------------------------  
Declare PartialProduction INSENSITIVE Cursor For  
 (Select ID, PLID, StartTIME, EndTIME, TypeOfEvent  
From #Production)  
For Read Only  
Open PartialProduction  
FETCH NEXT From PartialProduction into @@ID, @@PLID, @@StartTIME, @@EndTIME, @@TypeOfEvent  
While @@FETCH_Status = 0  
Begin  
 Select @PartPadCountVarID = PartPadCountVarID,  
  @PartCaseCountVarID = PartCaseCountVarID,  
  @PartRunCountVarID = PartRunCountVarID,  
  @PartStartUPCountVarID = PartStartUPCountVarID,  
  @CompSpeedTargetVarID = CompSpeedTargetVarID,  
  @PartSpeedActVarID = PartSpeedActVarID   
  From #PLIDList  
  Where PLID = @@PLID  
 --  
 Select @PartCaseCount = Sum(Convert(float, RESULT))  
  From TESTS  
  Where VAR_ID = @PartCaseCountVarID  
   and RESULT_on > @@StartTIME  
   and RESULT_on <= @@EndTIME  
 --  
 Update #Production  
  Set TotalCaseS = @PartCaseCount  
  Where ID = @@ID  
 --  
 If @@TypeOfEvent = 'Partial'  
 Begin  
  Select @SpeedTarget = Convert(float, RESULT)  
   From TESTS  
   Where VAR_ID = @CompSpeedTargetVarID  
    and RESULT_on = (Select MAX(RESULT_on)  
   From TESTS  
   Where VAR_ID = @CompSpeedTargetVarID  
    and RESULT_on < @@EndTIME  
    and RESULT_on >DATEADD(DD, -2, @@EndTIME))    
  --  
  Select @PartPadCount = Sum(Convert(float, RESULT))  
   From TESTS  
   Where VAR_ID = @PartPadCountVarID  
    and RESULT_on > @@StartTIME  
    and RESULT_on <= @@EndTIME  
  --  
  Select @PartRunCount = Sum(Convert(float, RESULT))  
   From TESTS  
   Where VAR_ID = @PartRunCountVarID  
    and RESULT_on > @@StartTIME  
    and RESULT_on <= @@EndTIME  
  --  
  Select @PartStartUPCount = Sum(Convert(float, RESULT))  
   From TESTS  
   Where VAR_ID = @PartStartUPCountVarID  
    and RESULT_on > @@StartTIME  
    and RESULT_on <= @@EndTIME  
  --  
  -- 8/16/02 JJR: New code for calculating linespeed_act below  
  Select @PartSpeedAct = Avg(Convert(float, RESULT))  
   From TESTS  
   Where VAR_ID = @PartSpeedActVarID  
    and RESULT_on > @@StartTIME  
    and RESULT_on <= @@EndTIME  
  --  
  Update #Production  
   Set TotalPad = @PartPadCount,  
    RunningScrap = @PartRunCount,  
    Stopscrap = @PartStartUPCount,  
    LineSpeedTAR = @SpeedTarget,  
    LineSpeed_Act = @PartSpeedAct  
   Where ID = @@ID  
  --  
 End  
 --  
 FETCH NEXT From PartialProduction into @@ID, @@PLID, @@StartTIME, @@EndTIME, @@TypeOfEvent  
 --  
End  
Close PartialProduction  
Deallocate PartialProduction  
Update #Production  
Set LineDesc = PLDESC  
FROM #PLIDList  
----------------------------------------------------------------------------  
-- Get Data: Downtime Data (for purposes of calculating line_speed_act)  
----------------------------------------------------------------------------  
--/*  
Print convert(varchar(25), getdate(), 120) + ' Getting Downtime Data'  
Create Table #Downtimes  
( TedID    int,  
 PU_ID    int,  
 PL_ID    int,  
 Start_Time   datetime,  
 End_Time   datetime,  
 Fault    Varchar(100),  
 Location   Varchar(50),  
 Reason1    Varchar(100),  
 Reason2    Varchar(100),  
 Reason3    Varchar(100),  
 Reason4    Varchar(100),  
 Duration   float,  
 Uptime    float,  
 IsStops    int,  
 Product    Varchar(50),  
 Crew    Varchar(10),  
 Shift    Varchar(10),  
 LineStatus   Varchar(25),  
 ID    int IDENTITY,  
 Total_Downtime   float,  
 Total_Uptime   float,  
 Line_Desc   varchar(255),  
 Comment    varchar(255),  
 Main_Comment   varchar(255))  
----------------------------------------------------------------------------  
-- Get Data: Downtime Data  
----------------------------------------------------------------------------  
Insert #Downtimes  
 (TedID,PU_ID, PL_ID, Start_Time,End_Time, Fault, Location,  
 Reason1, Reason2, Reason3, Reason4, Line_Desc, Comment, Main_Comment)  
Select   
 ted.TEDet_Id, ted.PU_Id, tpl.PLID,     
  Case   
   When ted.Start_Time < @InputStart_Time THEN @InputStart_Time  
   Else ted.Start_Time  
  End,   
  Case  
   When ted.End_Time Is null THEN @Now  
   When ted.End_Time > @InputEnd_Time THEN @InputEnd_Time  
   Else ted.End_Time  
  End,  
  tef.teFault_Name, pu.pu_DESC,   
  er1.Event_Reason_Name, er2.Event_Reason_Name, er3.Event_Reason_Name,  
  er4.Event_Reason_Name, tpl.pldesc, CONVERT(Varchar(255),wtc.comment_text),  
  CONVERT(Varchar(255),wtc2.comment_text)  
  From  Timed_Event_Details ted  
  Join  #PLIDList tpl on ted.PU_Id = tpl.convUnit or ted.pu_Id = tpl.Packerunit  
  Left Join timed_Event_Fault tef on ted.teFault_id = tef.teFault_id    
  Left Join  Prod_Units PU on ted.source_pu_id = pu.pu_id  
  Left Join  Event_Reasons er1 on ted.Reason_level1 = er1.Event_Reason_id   
  Left Join  Event_Reasons er2 on ted.Reason_level2 = er2.Event_Reason_id   
  Left Join  Event_Reasons er3 on ted.Reason_level3 = er3.Event_Reason_id   
  Left Join  Event_Reasons er4 on ted.Reason_level4 = er4.Event_Reason_id   
  --LEFT JOIN waste_n_timed_comments AS wtc on wtc.wtc_source_id = ted.tedet_id  
  Left Join (select wtc_source_id, comment_text  
      from waste_n_timed_comments  
      WHERE wtc_type = 2) as wtc on wtc.wtc_source_id = ted.tedet_id  
  Left Join (select wtc_source_id, comment_text  
      from waste_n_timed_comments  
      WHERE wtc_type = 1) as wtc2 on wtc2.wtc_source_id = ted.tedet_id  
  Where ted.Start_Time < @InputEnd_Time  
   and (ted.End_Time > @InputStart_Time  
   or ted.End_Time IS null)    
If @RPTGroupBy = 'Crew' or @RPTGroupBy = 'Shift'  
Begin  
 Declare DowntimeSplit INSENSITIVE Cursor For (   
  Select tpl.PLID, cs.PU_ID, cs.End_Time  
  From #PLIDList tpl  
  Join Crew_Schedule cs on tpl.convUnit = cs.pu_id  
  Where cs.Start_Time <= @InputEnd_Time and   
  (cs.End_Time > @InputStart_Time or cs.End_Time Is null))  
  For Read Only  
 --  
 Open DowntimeSplit  
 --  
 Fetch Next From DowntimeSplit into @@PLID, @@PUID, @@EndTime  
 --  
 While @@Fetch_Status = 0  
 --  
 Begin  
  Insert #Downtimes  
   (TedID,PU_ID, PL_ID, Start_Time,End_Time, Fault, Location,  
    Reason1, Reason2, Reason3, Reason4, IsStops)  
   Select TedID, PU_ID, PL_ID, @@EndTime, End_Time, Fault, Location,  
    Reason1, Reason2, Reason3, Reason4, 0  
   From #Downtimes tdt  
   Where tdt.PU_ID = @@PUID  
    and tdt.Start_Time < @@EndTime  
    and tdt.End_Time > @@EndTime  
  --  
  Update #Downtimes  
   Set End_Time = @@EndTime  
   Where PU_ID = @@PUID  
    and Start_Time < @@EndTime  
    and End_Time > @@EndTime  
   --  
  FETCH NEXT From DowntimeSplit into @@PLID, @@PUID, @@EndTime  
 End --DowntimeSplit Loop  
   
 Close DowntimeSplit  
 Deallocate DowntimeSplit  
End  
Declare DowntimeEnd INSENSITIVE Cursor For  
  
 (Select ConvUnit, PLID  
  From #PLIDList  
  Union Select Packerunit, PLID  
  From #PLIDList)  
 For Read Only  
Open DowntimeEnd  
FETCH NEXT From DowntimeEnd into @@PUID, @@PLID  
While @@Fetch_Status = 0  
Begin  
 Set @@EndTime = null  
 Select @@EndTime = Max(End_Time)  
  From #Downtimes  
  Where PU_ID = @@PUID  
 --  
 If @@EndTime < @InputEnd_Time  
 Insert #Downtimes  
  (PU_ID, PL_ID, Start_Time, End_Time, IsStops)  
  Values (@@PUID, @@PLID, @InputEnd_Time, @InputEnd_Time, 0)  
 --  
 Set @@StartTime = null  
  Select @@StartTime = Min(Start_Time)  
  From #Downtimes  
  Where PU_ID = @@PUID  
 --  
 If @@StartTime > @InputStart_Time  
 Insert #Downtimes  
  (PU_ID, PL_ID, Start_Time, End_Time, IsStops)  
  Values (@@PUID, @@PLID, @InputStart_Time, @InputStart_Time, 0)  
 --  
 Fetch Next From DowntimeEnd into @@PUID, @@PLID  
End  
Close DowntimeEnd  
Deallocate DowntimeEnd  
Print convert(varchar(25), getdate(), 120) + ' Updating Team, Shift, Line Downtime Data'  
Update TDT  
 Set Duration = DatedIff(ss, tdt.Start_Time, tdt.End_Time) / 60.0,   
  Product = P.Prod_Code,   
  Crew = cs.Crew_DESC,   
  Shift = cs.Shift_DESC,   
  LineStatus = phr.Phrase_Value  
 From #Downtimes tdt  
 Join #PLIDList tpl on tdt.PL_ID = tpl.PLID  
 Join Production_Starts PS on tpl.ConvUnit = PS.PU_ID  
  and tdt.Start_Time >= ps.Start_Time   
  and (tdt.Start_Time < ps.End_Time or ps.End_Time IS null)  
 Join Products P on ps.Prod_ID = P.Prod_ID  
 Left Join Crew_Schedule cs on tpl.ConvUnit = cs.PU_ID  
  and tdt.Start_Time >= cs.Start_Time   
  and (tdt.Start_Time < cs.End_Time or cs.End_Time IS null)  
 Left Join Local_PG_Line_Status LPG on tpl.ConvUnit = lpg.Unit_ID  
  and tdt.Start_Time >= lpg.Start_DateTime   
  and (tdt.Start_Time < lpg.End_DateTime or lpg.End_DateTime IS null)  
 Left Join Phrase phr on lpg.Line_Status_ID = phr.Phrase_ID  
Declare DowntimeUptime INSENSITIVE Cursor For  
 (Select id, Start_Time, PU_ID  
 From #Downtimes)  
 orDER BY PU_ID, Start_Time asC  
 For Read Only  
Open DowntimeUptime  
Fetch Next From DowntimeUptime into @@ID, @@StartTime, @@PUID  
While @@Fetch_Status = 0  
Begin  
 Select @@EndTime = null  
 Select @@EndTime = Max(End_Time)   
  From #Downtimes  
  Where PU_ID = @@PUID  
   and Start_Time < @@StartTime  
 --  
 Update #Downtimes  
  Set Uptime = DatedIff(ss, @@EndTime, @@StartTime) / 60.0  
  Where ID = @@ID  
  --  
 Fetch Next From DowntimeUptime into @@ID, @@StartTime, @@PUID  
 --  
End --DowntimeUptime Loop   
Close DowntimeUptime  
Deallocate DowntimeUptime  
Select @Total_Downtime = Null  
Select @Total_Uptime = Null  
Select @Total_Downtime = Sum(Duration)  
From #Downtimes TDT  
Join #PLIDList TPL on TDT.PU_ID = TPL.ConVUnit  
Update #Downtimes  
Set Total_Downtime = @Total_Downtime  
Select @Total_Uptime = Sum(Uptime)  
From #Downtimes TDT  
Join #PLIDList TPL on TDT.PU_ID = TPL.ConVUnit  
Update #Downtimes  
Set Total_Uptime = @Total_Uptime  
------------------------------------------------------------------------  
-- Code / cursor below to carry-over total uptime figures  
-- for line_speed_act calculation  
------------------------------------------------------------------------  
Print convert(varchar(25), getdate(), 120) + ' Uptime and LineSpeed Calculations'  
Declare UptimeUpdate INSENSITIVE Cursor For  
 (Select StartTime, EndTime, PUID, PLID  
 From #Production)  
 ORDER BY PUID, PLID, StartTime ASC  
 For Read Only  
Open UptimeUpdate  
Fetch Next From UptimeUpdate into @@StartTime, @@EndTime, @@PUID, @@PLID  
While @@Fetch_Status = 0  
Begin  
 Select @@Uptime = NULL  
 Select @@Uptime = Sum(Uptime)   
  From #Downtimes  
  Where PU_ID = @@PUID  
  AND PL_ID = @@PLID   
  AND Start_Time >= @@StartTime  
  AND End_Time <= @@EndTime  
--  
 Update #Production  
 Set Uptime = @@Uptime  
 From #Production  
 Where StartTime = @@StartTime  
   
 Fetch Next From UptimeUpdate into @@StartTime, @@EndTime, @@PUID, @@PLID  
--  
End -- UptimeUpdate Loop   
Close UptimeUpdate  
Deallocate UptimeUpdate  
--  
-- Calculates average linespeedtarget between the input start time and end time   
Select @Avg_Linespeed_Calc = avg(convert(float, result))  
From TESTS TSpeed  
join #PLIDList tpl on TPL.CompSpeedTargetVarID = TSpeed.VAR_ID  
join #Production tpt on tpt.PLID = tpl.PLID  
where TSpeed.RESULT_ON Between TPT.StartTIME and tpt.Endtime  
--  
Update #Production  
Set LineSpeedTAR = @Avg_Linespeed_Calc  
Where LineSpeedTAR Is NULL  
--  
Select @Act_Linespeed_Calc = avg(convert(float, result))  
From TESTS TSpeed  
join #PLIDList tpl on TPL.CompSpeedActVarID = TSpeed.VAR_ID  
join #Production tpt on tpt.PLID = tpl.PLID  
where TSpeed.RESULT_ON Between TPT.StartTIME and tpt.Endtime  
--  
Update #Production  
Set LineSpeed_Act = @Act_Linespeed_Calc  
Where LineSpeed_Act Is NULL  
--  
Update #Production  
Set LineDesc = PL_Desc  
From Prod_Lines PL  
Join #Production tpt on PL.PL_ID = tpt.PLID  
--Select '#Downtimes', * from #Downtimes  
--Select '#Production', * from #Production  
-----------------------------------------------------------------------------  
-- Old Code Begins Below  
-----------------------------------------------------------------------------  
--  
-- Create a local table    
Create Table #PEReport   
     (StartTime  datetime,   
     EndTime  datetime,  
     Product  varchar(50),  
     Team  varchar(25),  
     Shift  varchar(25),  
     Status  varchar(25),  
     NextStatus  varchar(30),  
     TotalPad  int,  
     RunningScrap int,  
     StopScrap  int,  
     LineSpeed_Tar int,  
     LineSpeed_Act int,  
     Type_of_Event varchar(30),  
     Line_Desc  varchar(75),  
     TotalCases  int,  
     ProdPerBag         int,  
     BagsPerCase        int,  
     CasesPerPallet     int,  
     ProdPerStat        int,  
     Prod_ID  int)  
INSERT #PEReport  
  (StartTime, EndTime, Product, Team, Shift, Status,   
      TotalPad, RunningScrap, StopScrap, LineSpeed_Tar, LineSpeed_Act,  
      Type_of_Event, Line_Desc, TotalCases, ProdPerBag, BagsPerCase, CasesPerPallet,  
      ProdPerStat, Prod_ID)  
SELECT StartTIME, EndTIME, Product, Crew, Shift, LineStatus,   
 TotalPad, RunningScrap, Stopscrap, LineSpeedTAR, LineSpeed_Act,   
 TypeOfEvent, LineDesc, TotalCases, ProdPerBag, BagSPerCase, CasesPerPallet,  
 ProdPerStat, Prod_ID  
FROM #Production  
--SELECT 'TESTING #PRODUCTION', * FROM #Production  
--SELECT 'TESTING #PLIDLIST', * FROM #PLIDLIST  
DROP TABLE #Production   
DROP TABLE #PLIDLIST  
DROP TABLE #Downtimes  
select @product=null  
select @product = prod_desc from products where prod_id = @prod_id  
-- The Stored Procedure result   
Print convert(varchar(25), getdate(), 120) + ' The output recordset'  
-- For a specific team and all shift  
If @InputTeam <> 'ALL' and @InputShift = 'ALL' and @lineStatus ='ALL' and @prod_id <> 0  
  Begin  
     Select * from #PEReport   
 where (CHARINDEX(','+team+',', ','+@InputTeam+',') > 0) and   
 prod_id = @prod_id   
 and endtime > @InputStart_Time   
 order by starttime  
 Drop table #PEReport  
 return  
  End  
If @InputTeam <> 'ALL' and @InputShift = 'ALL' and @lineStatus ='ALL' and @prod_id = 0  
  Begin  
     Select * from #PEReport   
 where (CHARINDEX(','+team+',', ','+@InputTeam+',') > 0)  
 and endtime > @InputStart_Time   
 order by starttime  
 Drop table #PEReport  
 return  
  End  
If @InputTeam <> 'ALL' and @InputShift = 'ALL' and @lineStatus <>'ALL' and @prod_id <> 0  
  Begin  
     Select * from #PEReport   
 where (CHARINDEX(','+team+',', ','+@InputTeam+',') > 0) and   
 prod_id = @prod_id and  
 (CHARINDEX(','+status+',', ','+@LineStatus+',') > 0)  
 and endtime > @InputStart_Time    
 order by starttime  
 Drop table #PEReport  
 return  
  End  
If @InputTeam <> 'ALL' and @InputShift = 'ALL' and @lineStatus <>'ALL' and @prod_id = 0  
  Begin  
    Select * from #PEReport   
 where (CHARINDEX(','+team+',', ','+@InputTeam+',') > 0) and   
 (CHARINDEX(','+status+',', ','+@LineStatus+',') > 0)   
 and endtime > @InputStart_Time   
 order by starttime  
 Drop table #PEReport  
 return  
  End  
If @InputTeam = 'ALL' and @InputShift <> 'ALL' and @lineStatus ='ALL' and @prod_id <> 0  
  Begin  
     Select * from #PEReport   
 where (CHARINDEX(','+Shift+',', ','+@InputShift+',') > 0) and   
 prod_id = @prod_id   
 and endtime > @InputStart_Time   
 order by starttime  
 Drop table #PEReport  
 return  
  End  
If @InputTeam = 'ALL' and @InputShift <> 'ALL' and @lineStatus ='ALL' and @prod_id = 0  
  Begin  
     Select * from #PEReport   
 where (CHARINDEX(','+Shift+',', ','+@InputShift+',') > 0)  
 and endtime > @InputStart_Time   
 order by starttime  
 Drop table #PEReport  
 return  
  End  
If @InputTeam = 'ALL' and @InputShift <> 'ALL' and @lineStatus <>'ALL' and @prod_id <> 0  
  Begin  
     Select * from #PEReport   
 where (CHARINDEX(','+Shift+',', ','+@InputShift+',')> 0) and   
 prod_id = @prod_id and  
 (CHARINDEX(','+status+',', ','+@LineStatus+',') > 0)  
 and endtime > @InputStart_Time    
 order by starttime  
 Drop table #PEReport  
 return  
  End  
If @InputTeam = 'ALL' and @InputShift <> 'ALL' and @lineStatus <>'ALL' and @prod_id = 0  
  Begin  
     Select * from #PEReport   
 where (CHARINDEX(','+Shift+',', ','+@InputShift+',')> 0) and   
 (CHARINDEX(','+status+',', ','+@LineStatus+',') > 0)   
 and endtime > @InputStart_Time   
 order by starttime  
 Drop table #PEReport  
 return  
  End  
-- For a specific team and shift  
If @InputTeam <> 'ALL' and @InputShift <> 'ALL' and @lineStatus ='ALL' and @prod_id <> 0  
  Begin  
     Select * from #PEReport   
 where (CHARINDEX(','+team+',', ','+@InputTeam+',') > 0) and   
 (CHARINDEX(','+Shift+',', ','+@InputShift+',')> 0) and  
 prod_id = @prod_id  
 and endtime > @InputStart_Time   
 order by starttime  
 Drop table #PEReport  
 return  
  End  
If @InputTeam <> 'ALL' and @InputShift <> 'ALL' and @lineStatus ='ALL' and @prod_id = 0  
  Begin  
     Select * from #PEReport   
 where (CHARINDEX(','+team+',', ','+@InputTeam+',') > 0) and  
 (CHARINDEX(','+Shift+',', ','+@InputShift+',') > 0)  
 and endtime > @InputStart_Time   
 order by starttime  
 Drop table #PEReport  
 return  
  End  
If @InputTeam <> 'ALL' and @InputShift <> 'ALL' and @lineStatus <>'ALL' and @prod_id <> 0  
  Begin  
     Select * from #PEReport where (CHARINDEX(','+team+',', ','+@InputTeam+',') > 0) and   
 (CHARINDEX(','+Shift+',', ','+@InputShift+',') > 0)  
 and prod_id = @prod_id and  
 (CHARINDEX(','+status+',', ','+@LineStatus+',') > 0)  
 and endtime > @InputStart_Time   
 order by starttime  
 Drop table #PEReport  
 return  
  End  
If @InputTeam <> 'ALL' and @InputShift <> 'ALL' and @lineStatus <>'ALL' and @prod_id = 0  
  Begin  
     Select * from #PEReport   
 where (CHARINDEX(','+team+',', ','+@InputTeam+',') > 0) and   
 (CHARINDEX(','+Shift+',', ','+@InputShift+',')> 0) and   
 (CHARINDEX(','+status+',', ','+@LineStatus+',') > 0)   
 and endtime > @InputStart_Time   
 order by starttime  
 Drop table #PEReport  
 return  
  End  
If @InputTeam = 'ALL' and @InputShift = 'ALL' and @lineStatus ='ALL' and @prod_id <> 0  
  Begin  
    Select * from #PEReport   
 where prod_id = @prod_id  
 and endtime > @InputStart_Time   
 order by starttime  
 Drop table #PEReport  
 return  
  End  
If @InputTeam = 'ALL' and @InputShift = 'ALL' and @lineStatus ='ALL' and @prod_id = 0  
  Begin  
 Select * from #PEReport   
 Where endtime > @InputStart_Time   
 order by starttime  
 Drop table #PEReport  
 return  
  End  
If @InputTeam = 'ALL' and @InputShift = 'ALL' and @lineStatus <>'ALL' and @prod_id <> 0  
  Begin  
     Select * from #PEReport  
        where prod_id = @prod_id and   
 (CHARINDEX(','+status+',', ','+@LineStatus+',') > 0)   
 and endtime > @InputStart_Time   
 order by starttime  
 Drop table #PEReport  
 return  
  End  
If @InputTeam = 'ALL' and @InputShift = 'ALL' and @lineStatus <>'ALL' and @prod_id = 0  
  Begin  
     Select * from #PEReport   
 where (CHARINDEX(','+status+',', ','+@LineStatus+',') > 0)  
 and endtime > @InputStart_Time    
 order by starttime  
 Drop table #PEReport  
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
  
  
  
  
GRANT  EXECUTE  ON [dbo].[spLocal_ReportProd_Event]  TO [comxclient]
