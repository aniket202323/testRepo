  
  
/*  
Stored Procedure: spLocal_CreateStopsReportRecord  
Author:   Matthew Wells (MSI)  
Date Created:  04/10/02  
  
Description:  
=========  
The sp creates a downtime summary record for the purposes of reporting.  Creating the record prior to report run time speeds up retrieval of the data and makes the  
same data available for multiple reports with differing time periods.  
  
Change Date Who What  
=========== ==== =====  
04/10/02 MKW Created.  
*/  
CREATE procedure dbo.spLocal_CreateStopsReportRecord  
@OutputValue  varchar(25) OUTPUT,  
@TEDet_Id  int,  
@Schedule_PU_Id int,  
@Line_Status_PU_Id int  
As  
  
Declare @RSF_Id   int,  
 @TEDC_Id   int,  
 @UserName   varchar(20),  
 @PU_Id   int,  
 @PU_Desc   varchar(50),  
 @PL_Id    int,  
 @PL_Desc   varchar(50),  
 @Start_Time   datetime,  
 @End_Time   datetime,  
 @Source_PU_Id  int,  
 @Source_PU_Desc  varchar(50),  
 @Tree_Id   int,  
 @ERTD_Id   int,  
 @Reason_Id1   int,  
 @Reason_Id2   int,  
 @Reason_Id3   int,  
 @Reason_Id4   int,  
 @Reason_Name1  varchar(100),  
 @Reason_Name2  varchar(100),  
 @Reason_Name3  varchar(100),  
 @Reason_Name4  varchar(100),  
 @ERC_Id   int,  
 @ERC_Delimiter   char(1),  
 @Category_Desc  varchar(50),  
 @Category_Id   int,  
 @Category_Filter  varchar(50),  
 @GroupCause_Desc  varchar(50),  
 @GroupCause_Id  int,  
 @GroupCause_Filter  varchar(50),  
 @Schedule_Desc  varchar(50),  
 @Schedule_Id   int,  
 @Schedule_Filter  varchar(50),  
 @Subsystem_Desc  varchar(50),  
 @Subsystem_Id   int,  
 @Subsystem_Filter  varchar(50),  
 @TEFault_Id   int,  
 @TEFault_Name  varchar(50),  
 @TEStatus_Id   int,  
 @TEStatus_Name  varchar(50),  
 @TESum_Id   int,  
 @TESum_Start_Time  datetime,  
 @TESum_End_Time  datetime,  
 @Primary_Stop   bit,  
 @Prod_Id   int,  
 @Prod_Desc   varchar(50),  
 @Prod_Code   varchar(25),  
 @Crew_Desc   varchar(50),  
 @Shift_Desc   varchar(50),  
 @Uptime_Duration  float,  
 @Downtime_Duration  float,  
 @Duration_Conversion  float,  
 @Line_Status_Id  int,  
 @Line_Status_Value  varchar(50),  
 @Res_Id   int,   -- Report Configuration  
 @Home_Unit   int,   -- Report Configuration  
 @PUType_ID   int,   -- Report Configuration  
 @PUType_Desc  varchar(50),  -- Report Configuration  
 @PUIDSubType_ID  int,   -- Report Configuration  
 @PUIDType_ID   int,   -- Report Configuration  
 @PUIDType_Desc  varchar(50),  -- Report Configuration  
 @GBU    varchar(50),  -- Report Configuration  
 @Plant    varchar(50),  -- Report Configuration  
 @Module   varchar(50),  -- Report Configuration  
 @Dept    varchar(50),  -- Report Configuration  
 @EquipGRP_Id   int,   -- Report Configuration  
 @EquipGRP_Desc  varchar(50),  -- Report Configuration  
 @Equip_Id   int,   -- Report Configuration  
 @Equip_Desc   varchar(50),  -- Report Configuration  
 @Dept_Id   int,   -- Report Configuration  
 @Module_Id   int,   -- Report Configuration  
 @Plant_Id   int,   -- Report Configuration  
 @GBU_Id   int,   -- Report Configuration  
 @UPLTRx   bit,   -- If uptime of event was less than 2x time  
 @Minor_Stop_Limit  float,   -- Time limit (in min) for a minor stop.  
 @Minor_Stop   bit,   -- If downtime of event was less than Minor_Stop_Limit minutes  
 @Breakdown   bit,   -- Category = 'Mechanical Equipment'/'Electrical Equipement' And DT >= Minor_Stop_Limit min  
 @Breakdown_Desc1  varchar(50),  -- Category 'Mechanical Equipment'    
 @Breakdown_Desc2  varchar(50),  -- Category 'Electrical Equipment'  
 @Process_Failure  bit,   -- Category = 'Process/Operational' And DT >= Minor_Stop_Limit min  
 @Process_Failure_Desc  varchar(50),  -- Category 'Process/Operational'  
 @Blocked_Starved  bit,   -- Category = 'Blocked/Starved'  
 @Blocked_Starved_Desc varchar(50),  -- Category 'Blocked/Starved'  
 @Comment   varchar(800),  
 @Event_Type   varchar(10)  
  
--Begin Transaction  
  
--Rollback Transaction  
--Select @OutputValue = '0'  
Return  
  
/* Initialization */  
Select  @UserName   = 'XXXX0001',  
 @Duration_Conversion  = 60.0,  
 @RSF_Id   = Null,  
 @Category_Filter  = 'Category%',  
 @GroupCause_Filter   = 'GroupCause%',  
 @Schedule_Filter   = 'Schedule%',  
 @Subsystem_Filter   = 'GroupCause%',  
 @ERC_Delimiter   = ':',  
 @Minor_Stop_Limit  = 10.0,  
 @Breakdown_Desc1  = 'Mechanical Equipment', -- Must match the Category description (minus the header)  
 @Breakdown_Desc2  = 'Electrical Equipment',  -- Must match the Category description (minus the header)  
 @Process_Failure_Desc  = 'Process/Operational',  -- Must match the Category description (minus the header)  
 @Blocked_Starved_Desc = 'Blocked/Starved',  -- Must match the Category description (minus the header)  
 @Uptime_Duration   = 0.0,  
 @Primary_Stop    = 0,  
 @UPLTRx   = 0,  
 @Minor_Stop    = 0,  
 @Breakdown   = 0,  
 @Process_Failure  = 0,  
 @Blocked_Starved  = 0,  
 @Comment   = 'No Comment Entered'  
  
/* Check for existing report record */  
Select @RSF_Id = TEDet_Id  
From Local_ReportStopsFinal2  
Where TEDet_Id = @TEDet_Id And UserName = @UserName  
  
/************************************************************************************************************************************************************************  
*                                                                                    Get Downtime Detail Record Data                                          *  
************************************************************************************************************************************************************************/  
Select  @PU_Id   = PU_Id,   
 @Start_Time  = Start_Time,   
 @End_Time   = End_Time,  
 @Source_PU_Id = Source_PU_Id,  
 @Reason_Id1  = Reason_Level1,  
 @Reason_Id2  = Reason_Level2,  
 @Reason_Id3  = Reason_Level3,  
 @Reason_Id4  = Reason_Level4,  
 @TEFault_Id  = TEFault_Id,  
 @TEStatus_Id  = TEStatus_Id  
From Timed_Event_Details   
Where TEDet_Id = @TEDet_Id  
  
/************************************************************************************************************************************************************************  
*                                                                               Convert Ids to  Names/Descriptions                                                                                        *  
************************************************************************************************************************************************************************/  
-- Production Unit and Production Line  
Select  @PU_Desc  = PU_Desc,  
 @PL_Id  = PL_Id  
From Prod_Units  
Where PU_Id = @PU_Id  
  
Select @PL_Desc = PL_Desc  
From Prod_Lines  
Where PL_Id = @PL_Id  
  
--Location  
Select  @Source_PU_Desc  = PU_Desc  
From Prod_Units  
Where PU_Id = @Source_PU_Id  
  
-- Reasons  
Select  @Reason_Name1 = Event_Reason_Name  
From Event_Reasons  
Where Event_Reason_Id = @Reason_Id1  
  
Select  @Reason_Name2 = Event_Reason_Name  
From Event_Reasons  
Where Event_Reason_Id = @Reason_Id2  
  
Select  @Reason_Name3 = Event_Reason_Name  
From Event_Reasons  
Where Event_Reason_Id = @Reason_Id3  
  
Select  @Reason_Name4 = Event_Reason_Name  
From Event_Reasons  
Where Event_Reason_Id = @Reason_Id4  
  
-- Category  
Select @Tree_Id = Name_Id  
From Prod_Events  
Where PU_Id = @Source_PU_Id And Event_Type = 2 -- Event_Type = Downtime (as opposed to Waste)  
  
If @Reason_Id1 Is Not Null  
     Begin  
     Select @ERTD_Id = Event_Reason_Tree_Data_Id  
     From Event_Reason_Tree_Data  
     Where Tree_Name_Id = @Tree_Id And Event_Reason_Id = @Reason_Id1 And Event_Reason_Level = 1 And Parent_Event_R_Tree_Data_Id Is Null  
     If @Reason_Id2 Is Not Null  
          Begin  
          Select @ERTD_Id = Event_Reason_Tree_Data_Id  
          From Event_Reason_Tree_Data  
          Where Tree_Name_Id = @Tree_Id And Event_Reason_Id = @Reason_Id2 And Event_Reason_Level = 2 And Parent_Event_R_Tree_Data_Id = @ERTD_Id  
  
          If @Reason_Id3 Is Not Null  
               Begin  
               Select @ERTD_Id = Event_Reason_Tree_Data_Id  
               From Event_Reason_Tree_Data  
               Where Tree_Name_Id = @Tree_Id And Event_Reason_Id = @Reason_Id3 And Event_Reason_Level = 3 And Parent_Event_R_Tree_Data_Id = @ERTD_Id  
  
               If @Reason_Id4 Is Not Null  
                    Begin  
                    Select @ERTD_Id = Event_Reason_Tree_Data_Id  
                    From Event_Reason_Tree_Data  
                    Where Tree_Name_Id = @Tree_Id And Event_Reason_Id = @Reason_Id4 And Event_Reason_Level = 4 And Parent_Event_R_Tree_Data_Id = @ERTD_Id  
                    End  
               End  
          End  
     End  
  
Select  @Category_Desc = ltrim(right(erc.ERC_Desc, len(erc.ERC_Desc)-charindex(@ERC_Delimiter, erc.ERC_Desc))),  
 @Category_Id = ercd.ERC_Id  
From Event_Reason_Category_Data ercd  
     Inner Join Event_Reason_Catagories erc On ercd.ERC_Id = erc.ERC_Id  
Where ercd.Event_Reason_Tree_Data_Id = @ERTD_Id And erc.ERC_Desc Like @Category_Filter  
  
Select  @GroupCause_Desc = ltrim(right(erc.ERC_Desc, len(erc.ERC_Desc)-charindex(@ERC_Delimiter, erc.ERC_Desc))),  
 @GroupCause_Id = ercd.ERC_Id  
From Event_Reason_Category_Data ercd  
     Inner Join Event_Reason_Catagories erc On ercd.ERC_Id = erc.ERC_Id  
Where ercd.Event_Reason_Tree_Data_Id = @ERTD_Id And erc.ERC_Desc Like @GroupCause_Filter  
  
Select  @Schedule_Desc = ltrim(right(erc.ERC_Desc, len(erc.ERC_Desc)-charindex(@ERC_Delimiter, erc.ERC_Desc))),  
 @Schedule_Id = ercd.ERC_Id  
From Event_Reason_Category_Data ercd  
     Inner Join Event_Reason_Catagories erc On ercd.ERC_Id = erc.ERC_Id  
Where ercd.Event_Reason_Tree_Data_Id = @ERTD_Id And erc.ERC_Desc Like @Schedule_Filter  
  
Select  @Subsystem_Desc = ltrim(right(erc.ERC_Desc, len(erc.ERC_Desc)-charindex(@ERC_Delimiter, erc.ERC_Desc))),  
 @Subsystem_Id = ercd.ERC_Id  
From Event_Reason_Category_Data ercd  
     Inner Join Event_Reason_Catagories erc On ercd.ERC_Id = erc.ERC_Id  
Where ercd.Event_Reason_Tree_Data_Id = @ERTD_Id And erc.ERC_Desc Like @Subsystem_Filter  
  
-- Downtime Fault and Downtime Status  
Select @TEFault_Name = TEFault_Name  
From Timed_Event_Fault  
Where TEFault_Id = @TEFault_Id  
  
Select @TEStatus_Name = TEStatus_Name  
From Timed_Event_Status  
Where TEStatus_Id = @TEStatus_Id  
  
-- Downtime Duration  
Select @Downtime_Duration = convert(float, datediff(s, @Start_Time, @End_Time))/@Duration_Conversion  
  
-- Downtime Detail Comment  
Select @Comment = convert(varchar(800), Comment_Text)  
From Waste_n_Timed_Comments  
Where WTC_Type = 2 And WTC_Source_Id = @TEDet_Id  
  
/************************************************************************************************************************************************************************  
*                                                                                             Get Supplimentary Data                                                                                             *  
************************************************************************************************************************************************************************/  
-- Downtime Summary Data  
Select @TESum_Id  = TESum_Id,  
 @TESum_Start_Time  = Start_Time,  @TESum_End_Time = End_Time  
From Timed_Event_Summarys  
Where PU_Id = @PU_Id And Start_Time <= @Start_Time And (End_Time >= End_Time Or End_Time Is Null)  
  
-- Primary Stop + Uptime + UPLTRx + Minor Stop + Summary comment  
If @TESum_Start_Time = @Start_Time  
     Begin  
     Select @Primary_Stop  = 1,  
    @Event_Type  = 'Primary'  
  
     -- If there is no detail comment then check for a summary comment.  
     If @Comment =  'No Comment Entered'  
          Select @Comment = convert(varchar(800), Comment_Text)  
          From Waste_n_Timed_Comments  
          Where WTC_Type = 1 And WTC_Source_Id = @TESum_Id  
  
     Select TOP 1 @Uptime_Duration = convert(float, datediff(s, End_Time, @TESum_Start_Time))/@Duration_Conversion  
     From Timed_Event_Details  
     Where PU_Id = @PU_Id And End_Time < @TESum_Start_Time  
     Order By End_Time Desc  
  
     If @Uptime_Duration  < (2.0 * @Downtime_Duration)  
          Select @UPLTRx = 1  
  
     If @Downtime_Duration < @Minor_Stop_Limit  
          Select @Minor_Stop = 1  
  
     If @Downtime_Duration >= @Minor_Stop_Limit And @Category_Desc = @Process_Failure_Desc  
          Select @Process_Failure = 1  
  
     If @Downtime_Duration >= @Minor_Stop_Limit And (@Category_Desc = @Breakdown_Desc1 Or @Category_Desc = @Breakdown_Desc2)   
          Select @Breakdown = 1  
  
     If @Category_Desc = @Blocked_Starved_Desc  
          Select @Blocked_Starved = 1  
     End  
Else  
     Select @Event_Type  = 'Extended'  
  
-- Product   
Select @Prod_Id = Prod_Id  
From Production_Starts  
Where PU_Id = @PU_Id And Start_Time <= @Start_Time And (End_Time > @Start_Time Or End_Time Is Null)  
  
Select @Prod_Code = Prod_Code,  
 @Prod_Desc = Prod_Desc  
From Products  
Where Prod_Id = @Prod_Id  
  
-- Crew & Schedule  
Select @Crew_Desc = Crew_Desc,  
 @Shift_Desc = Shift_Desc  
From Crew_Schedule  
Where PU_Id = @Schedule_PU_Id And Start_Time <= @Start_Time And End_Time > @Start_Time  
  
-- Line Status  
Select TOP 1 @Line_Status_Id = Line_Status_Id  
From Local_PG_Line_Status  
Where Unit_Id = @Line_Status_PU_Id And Start_DateTime < @Start_Time  
Order By Start_DateTime Desc  
  
Select @Line_Status_Value  = Phrase_Value  
From Phrase  
Where Phrase_Id = @Line_Status_Id  
  
/************************************************************************************************************************************************************************  
*                                                                                             Get Report Configuration Data                                                                                  *  
************************************************************************************************************************************************************************/  
If @RSF_Id Is Null  
     Begin  
     Select @Home_Unit  = Home_Unit,  
  @PUIDSubType_Id = PUIDSubType_Id,  
  @Equip_Id  = Equip_Id,  
  @Res_Id  = Res_Id  
     From Local_ReportProdUnits  
     Where PU_Id = @PU_Id  
  
     Select @PUIDType_Id   = PUIDTypes_Id,  
  @PUType_Id  = PUType_Id  
     From Local_ReportPUIDSubTypes  
     Where PUIDSubType_Id = @PUIDSubType_Id  
  
     Select @PUIDType_Desc = PUIDType_Desc  
     From Local_ReportPUIDTypes  
     Where PUIDType_Id = @PUIDType_Id  
  
     Select @PUType_Desc = PUType_Desc  
     From Local_ReportPUType  
     Where PUType_Id = @PUType_Id  
  
     Select  @EquipGRP_Id   = EquipGRP_Id,  
  @Equip_Desc  = EquipmentDescription  
     From Local_ReportEquipment  
     Where Equip_Id = @Equip_Id  
  
     Select  @EquipGRP_Desc = EquipmentGroup  
     From Local_ReportEquipmentGrouping  
     Where EquipGRP_Id = @EquipGRP_Id  
  
     Select @Dept_Id  = Dept_Id  
     From Local_Resources  
     Where Res_Id = @Res_Id  
  
     Select  @Dept   = Dept_Desc,  
  @Module_Id  = Module_Id  
     From Local_Department  
     Where Dept_Id = @Dept_Id  
  
     Select @Module  = Module_Desc,  
  @Plant_Id  = Plant_Id  
     From Local_Module  
     Where Module_Id = @Module_Id  
  
     Select @Plant   = Plant_Desc,  
  @GBU_Id  = GBU_Id  
     From Local_Plant  
     Where Plant_Id = @Plant_Id  
  
     Select @GBU   = GBU_Desc  
     From Local_GBU  
     Where GBU_Id = @GBU_Id  
     End  
  
/************************************************************************************************************************************************************************  
*                                                                                                        Output Results                                                                                               *  
************************************************************************************************************************************************************************/  
-- Check for existing record in the summary table  
If @RSF_Id Is Null  
     Begin  
     -- Insert new record into the summary table  
     Insert Into Local_ReportStopsFinal2 ( UserName,   --1  (All) Report UserName - Required to filter the data  
     tedet_id,   --2  (All) Downtime Id  
     Starttime,   --3  (All) Downtime Start Time  
     EndTime,   --4  (All) Downtime End Time  
     Fault,    --5  (All) Downtime Fault Name  
     Reason1_ERID,   --6  (All) Downtime Reason Level 1 Id  
     Reason2_ERID,   --7  (All) Downtime Reason Level 2 Id  
     Reason3_ERID,   --8  (All) Downtime Reason Level 3 Id  
     Reason4_ERID,   --9  (All) Downtime Reason Level 4 Id  
     Location,   --10 (All) Downtime Location Name  
     Reason1,   --11  (All) Downtime Reason Level 1 Name  
     Reason2,   --12 (All) Downtime Reason Level 2 Name  
     Reason3,   --13  (All) Downtime Reason Level 3 Name  
     Reason4,   --14  (All) Downtime Reason Level 4 Name  
     Category,   --15  (All) Downtime Reason Category 'Category'  
     GroupCause,   --16 (All) Downtime Reason Category 'Group Cause'  
     Schedule,   --17 (All) Downtime Reason Category 'Schedule'  
     SubSystem,   --18 (All) Downtime Reason Category 'Subsystem'  
     TEStatus_Name,  --19  (All) Downtime Status Name - 'Valid'/'Invalid' - Only 'Valid' records are required in the summary table  
     tesum_id,   --20  (All) Downtime Summary Id  
     tesstart,    --21  (All) Downtime Summary Start Time  
     tesend,    --22 (All) Downtime Summary End Time  
     PL_ID,    --23 (All) Downtime Production Line Id  
     PL_Desc,   --24 (All) Downtime Production Line Name/Description  
     PU_ID,    --25 (All) Downtime Production Unit Id  
     PU_Desc,   --26 (All) Downtime Production Unit Name/Description  
     Team,    --27 (All) Team On at Downtime Start  
     Shift,    --28 (All) Shift On at Downtime Start  
     Line_Status,   --29 (All) Line Status at Downtime Start  
     Product,   --30 (All) Product Description at Downtime Start  
     ProdCode,   --31 (All) Product Code at Downtime Start  
     TotalTime,   --32   (All) Downtime duration  
     Uptime,    --33 (All) Uptime since last downtime  
     Home_Unit,   --34 (Rpt)    
     PUType_ID,   --35 (Rpt)  
     PUIDSubType_ID,  --36 (Rpt)  
     PUIDType_ID,   --37 (Rpt)  
     GBU,    --38 (Rpt)  
     Plant,    --39 (Rpt)  
     Module,    --40 (Rpt)  
     Dept,    --41 (Rpt)  
     EquipGRP_Desc,  --42 (Rpt)  
     Equip_Desc,   --43 (Rpt)  
     PUType_Desc,   --44 (Rpt)  
     PUIDType_Desc,  --45 (Rpt)  
     TotalStop,   --46 (All)     
     UPLTRx,   --47 (All)  
     MinorStop,   --48 (All)  
     BreakDown,   --49 (All)  
     ProcessFailure,   --50 (All)  
     BLKStraved,   --51 (All)  
     Comments,   --52 (All)  
     EventType   --53 (All)  
--     Area,  
--     DateCorrected,  
--     LostProd,  
--     RealLostProd,  
--     Turnover,   -- Cvtg  
--     SheetWidth,   -- Cvtg  
--     ActualSpeed,   -- Rate Loss  
--     TargetSpeed,   -- Rate Loss  
--     EffectiveDowntime  -- Rate Loss  
--     EventTime,   -- Has to be done dynamically by report  
--     RealUptime,   -- Has to be done dynamically by report  
--     Master_Unit   --(All) Downtime Master Unit - REDUNDANT as PU_Id has to be a master unit to have an event on it.  
--     ReportDate,   -- Leave Null  
--     RMonth,   -- Leave Null  
--     RDay,    -- Leave Null  
--     RYear,    -- Leave Null  
--     RTime,    -- Leave Null  
     )  
     Values (    @UserName,   --1  
     @TEDet_Id,   --2  
     @Start_Time,   --3  
     @End_Time,   --4  
     @TEFault_Name,  --5  
     @Reason_Id1,   --6  
     @Reason_Id2,   --7  
     @Reason_Id3,   --8  
     @Reason_Id4,   --9  
     @Source_PU_Desc,  --10  
     @Reason_Name1,  --11  
     @Reason_Name2,  --12  
     @Reason_Name3,  --13  
     @Reason_Name4,  --14  
     @Category_Desc,  --15  
     @GroupCause_Desc,  --16  
     @Schedule_Desc,  --17  
     @SubSystem_Desc,  --18  
     @TEStatus_Name,  --19  
     @TESum_Id,   --20  
     @TESum_Start_Time,  --21  
     @TESum_End_Time,  --22  
     @PL_Id,   --23  
     @PL_Desc,   --24  
     @PU_Id,   --25  
     @PU_Desc,   --26  
     @Crew_Desc,   --27  
     @Shift_Desc,   --28  
     @Line_Status_Value,  --29  
     @Prod_Desc,   --30  
     @Prod_Code,   --31   
     @Downtime_Duration,  --32  
     @Uptime_Duration,  --33  
     @Home_Unit,   --34  
     @PUType_ID,   --35  
     @PUIDSubType_ID,  --36  
     @PUIDType_ID,  --37  
     @GBU,    --38  
     @Plant,    --39  
     @Module,   --40  
     @Dept,    --41  
     @EquipGRP_Desc,  --42  
     @Equip_Desc,   --43  
     @PUType_Desc,  --44  
     @PUIDType_Desc,  --45  
     @Primary_Stop,   --46  
     @UPLTRx,   --47  
     @Minor_Stop,   --48  
     @Breakdown,   --49  
     @Process_Failure,  --50  
     @Blocked_Starved,  --51  
     @Comment,   --52  
     @Event_Type   --53  
--     EventTime  
--     RealUptime,  
--     Area,  
--     DateCorrected,  
--     LostProd,  
--     RealLostProd,  
--     Turnover,  
--     SheetWidth,  
--     ActualSpeed,  
--     TargetSpeed,  
--     EffectiveDowntime  
--     @PU_Desc   --43  
--     ReportDate,  
--     RMonth,  
--     RDay,  
--     RYear,  
--     RTime,  
     )  
     End  
Else  
     Begin  
     Update Local_ReportStopsFinal2   
     Set Starttime  = @Start_Time,  
 EndTime  = @End_Time,  
 Fault   = @TEFault_Name,  
 Reason1_ERID  = @Reason_Id1,  
 Reason2_ERID  = @Reason_Id2,  
 Reason3_ERID  = @Reason_Id3,  
 Reason4_ERID  = @Reason_Id4,  
 Location  = @Source_PU_Desc,  
 Reason1  = @Reason_Name1,  
 Reason2  = @Reason_Name2,  
 Reason3  = @Reason_Name3,  
 Reason4  = @Reason_Name4,  
 Category  = @Category_Desc,   
 GroupCause  = @GroupCause_Desc,  
 Schedule  = @Schedule_Desc,  
 SubSystem  = @SubSystem_Desc,  
 TEStatus_Name  = @TEStatus_Name,  
 tesstart   = @TESum_Start_Time,  
 tesend   = @TESum_End_Time,  
 Team   = @Crew_Desc,  
 Shift   = @Shift_Desc,  
 Line_Status  = @Line_Status_Value,  
 Product   = @Prod_Desc,   
 ProdCode  = @Prod_Code,   
 TotalTime  = @Downtime_Duration,  
 Uptime   = @Uptime_Duration,  
 UPLTRx  = @UPLTRx,  
 MinorStop  = @Minor_Stop,   
 BreakDown  = @Breakdown,   
 ProcessFailure  = @Process_Failure,  
 BLKStraved  = @Blocked_Starved,  
 Comments  = @Comment,  
 EventType  = @Event_Type  
-- TotalStop  = @Primary_Stop,  
-- Home_Unit  = @Home_Unit,  
-- PUType_ID  = @PUType_ID,  
-- PUIDSubType_ID = @PUIDSubType_Id,  
-- PUIDType_ID  = @PUIDType_Id,  
-- GBU   = @GBU,  
-- Plant   = @Plant,  
-- Module   = @Module,  
-- Dept   = @Dept,  
-- EquipGRP_Desc = @EquipGRP_Desc,  
-- Equip_Desc  = @Equip_Desc,  
-- PUType_Desc  = @PUType_Desc,  
-- PUIDType_Desc = @PUIDType_Desc,  
--     ReportDate,   -- Leave Null  
--     RMonth,   -- Leave Null  
--     RDay,    -- Leave Null  
--     RYear,    -- Leave Null  
--     RTime,    -- Leave Null  
--     RealUptime,  
--     Area,  
--     DateCorrected,  
--     LostProd,  
--     RealLostProd,  
--     Turnover,  
--     SheetWidth,  
--     ActualSpeed,  
--     TargetSpeed,  
--     EffectiveDowntime  
     Where TEDet_Id = @TEDet_Id And UserName = @UserName  
     End  
  
-- Update category table information for MKW's reports  
Select @TEDC_Id = TEDet_Id  
From Local_Timed_Event_Detail_Categories  
Where TEDet_Id = @TEDet_Id  
  
If @TEDC_Id Is Null  
     Insert Into Local_Timed_Event_Detail_Categories ( TEDet_Id,   --1  
       Category_Id,   --2  
       Group_Cause_Id,  --3  
       Schedule_Id,   --4  
       Subsystem_Id   --5  
       )  
     Values (      @TEDet_Id,   --1  
       @Category_Id,   --2  
       @GroupCause_Id,  --3  
       @Schedule_Id,   --4  
       @Subsystem_Id   --5  
       )  
Else  
     Update Local_Timed_Event_Detail_Categories  
     Set Category_Id  = @Category_Id,  
 Group_Cause_Id = @GroupCause_Id,  
 Schedule_Id  = @Schedule_Id,  
 Subsystem_Id  = @Subsystem_Id  
     Where TEDet_Id = @TEDet_Id  
  
Select @OutputValue = convert(varchar(25), @TEDet_Id)  
  
/* Cleanup */  
  
--Commit Transaction  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
