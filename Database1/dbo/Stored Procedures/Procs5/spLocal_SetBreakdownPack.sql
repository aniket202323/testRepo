 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-07  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
-- This procedure is used to set the Breakdown flag for packing downtime events.    
-- The variable Breakdown is set to 1 if the event is a breakdown and 0 if it is not.  
-- A breakdown is determined by using a Proficy Data Type as a list of valid breakdowns.    
-- The variable @CompareList is a constant variable that contains the  
-- the name of the Data Type.  The value of the Failure Mode (Reason1) for the event is compared  
-- to the breakdown list.  If the Failure Mode description is in the list, Breakdown = True Value, else Breakdown = False Value.  
--  
-- Vince King, Albany, Georgia July 2001  
*/  
CREATE PROCEDURE spLocal_SetBreakdownPack  
@OutputValue varchar(25) OUTPUT,  
@Pu_Id int,      -- Production Unit for the Breakdown Variable.  
@TimeStamp varchar(30),    -- Time Stamp of the event.  
@CompareList varchar(50),    -- Name of the Data Type used for the Breakdown Compare List.  
@Var_Id int,      -- Variable Id for this variable (Breakdown).  
@TrueValue int,      -- Value to use if the compare is true.  
@FalseValue int,     -- Value to use if the compare is false.  
@DowntimeVarId int     -- The downtime value for the event.  
AS  
  
Declare @ReasonName varchar(50)  
  
/*  
Select @PU_Id = 44  
Select @TimeStamp = '2001-08-09 14:42:58.000'  
Select @Result_VarId = 0 --This will be the Failure Mode Reason Id value.  
Select @TrueValue = 1  
Select @FalseValue = 0  
Select @ProdStatus_Id = 3341  
Select @ProdStatus_Value = 'Unplanned'  
Select @CompareList = "PACK Breakdown List"  
*/  
  
Declare @Ext_Info varchar(50),  
 @Start_Position int,  
 @Compare_Result_DataType_Id int,   
 @PU_Compare_VarId int,  
 @Test_Result varchar(50),  
 @Count int,  
 @Compare_Result int,  
 @Entry_Date datetime,  
 @EventDowntime float,  
 @AppVersion   varchar(30),  
 @User_id   int  
  
 -- user id for the resulset  
 SELECT @User_id = User_id   
 FROM [dbo].Users  
 WHERE username = 'Reliability System'  
   
  
 -- Get the Proficy database version  
 SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'   
   
DECLARE @CompareList_tbl TABLE (  
  Phrase_Desc varchar(50))  
  
--Get the downtime value for the event.  
Select @EventDowntime = result  
From [dbo].tests  
Where Result_On = @Timestamp and Var_Id = @DowntimeVarId  
  
--Get the Reason Name for Reason1 of the Event.  
Select @ReasonName = Event_Reason_Name  
From [dbo].timed_event_details   
  join [dbo].event_reasons on reason_level1 = event_reason_id  
where start_time = @timestamp and PU_Id = @PU_Id  
  
--Get variable id for the Prod Unit variable, Breakdown.  
Select @PU_Compare_VarId = @Var_Id  
  
--Get the Data_Type_Id for the Breakdown list Data Type.  
Select @Compare_Result_DataType_Id = Data_Type_Id  
From [dbo].Data_Type  
Where Data_Type_Desc = @CompareList  
  
--Select the list of Breakdowns (Categories) and insert them into a temporary table (#CompareList)  
INSERT INTO @CompareList_tbl  
Select Phrase_Value as Phrase_Desc  
From [dbo].Phrase Where Data_Type_ID = @Compare_Result_DataType_Id  
  
--If the downtime Failure Mode Reason value is in the list, @Compare_Result = 1, else @Compare_Result = 0  
If (Select Count(*) From @CompareList_tbl Where Phrase_Desc = @ReasonName) > 0 and @EventDowntime >= 10  
  Select @Compare_Result = @TrueValue  
Else  
  Select @Compare_Result = @FalseValue  
  
--Return the info required to have the Proficy service write result value to the Tests table  
IF @AppVersion LIKE '4%'  
 BEGIN  
  Select ResultSetType = 2,@PU_Compare_VarId,@PU_Id,@User_id,0,@Compare_Result,Result_On = Convert(varchar(30),@TimeStamp, 120),1,0,  
     NULL,NULL,NULL,NULL,NULL  
 END  
ELSE  
 BEGIN  
  Select ResultSetType = 2,@PU_Compare_VarId,@PU_Id,@User_id,0,@Compare_Result,Result_On = Convert(varchar(30),@TimeStamp, 120),1  
 END  
  
--Assign the result to the output variable.  
Select @OutputValue = @Compare_Result  
  
-- Drop the temporary table #CompareList  
drop table #CompareList  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
