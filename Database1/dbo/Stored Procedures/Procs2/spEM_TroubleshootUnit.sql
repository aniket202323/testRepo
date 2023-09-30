CREATE   PROCEDURE [dbo].[spEM_TroubleshootUnit] 
@UnitId int
AS
/*
*/
-- Check various log tables for info
Declare @SQLString nvarchar(255)
Declare @Message Varchar(5000)
Declare @Service_Desc nvarchar(50)
Declare @Problem nvarchar(2000)
Declare @Cause nvarchar(2000)
Declare @Action nvarchar(2000)
Declare @Prod_Id int
Declare @Prod_Desc nvarchar(50)
Create Table #TT(
 	 ID int NOT NULL IDENTITY (1, 1),
 	 Area int,
 	 Problem nvarchar(2000),
 	 Cause nvarchar(2000),
 	 [Action] nvarchar(2000)
)
Create Table #TT1(
 	 Problem nvarchar(2000),
 	 Cause nvarchar(2000),
 	 [Action] nvarchar(2000)
)
------------------------------------------------------------------
-- 1. event types with detection models configured but not active
------------------------------------------------------------------
Insert Into #TT1 (Problem, Cause, [Action])
 	 Select 'Model Number ' + Convert(nvarchar(255), Model_Num), 'Model [' + Convert(nvarchar(255), Model_Num) + '] "' + Model_Desc + '" Is Configured On This Unit But Is Not Active' , 'Activate This Model Using Plant Applications Administrator'
 	 From Event_Configuration EC
 	 Join ED_Models ED on EC.ED_Model_Id = ED.ED_Model_Id
 	 where EC.PU_ID = @UnitId
 	 And EC.Is_Active = 0
If (Select Count(*) from #TT1) > 0
Begin
 	 Select @Problem = NULL
 	 Select @Cause = NULL
 	 Select @Action = NULL
 	 Declare MyCursor1 INSENSITIVE CURSOR
 	   For (Select Problem, Cause, Action FRom #TT1)
 	   For Read Only
 	   Open MyCursor1  
 	 
 	 -- Go through the Result set and find a report for this engine to run
 	 MyLoop1:
 	   Fetch Next From MyCursor1 Into @Problem, @Cause, @Action 
 	   If (@@Fetch_Status = 0)
 	  	 Begin -- Begin Loop Here
 	  	  	 Insert Into #TT(Area, Problem, Cause, Action) Values(0, @Problem, @Cause, @Action)
 	  	  	 Goto MyLoop1
 	  	 End -- End Loop Here
 	 
 	 myEnd:
 	 Close MyCursor1
 	 Deallocate MyCursor1
 	 Delete from #TT1
End
------------------------------------------------------------------
-- 2. Search through logfile tables for error messages associated 
--    with ec_ids on this unit
------------------------------------------------------------------
Select @SQLString = '%ECId__' + Convert(varchar(5), @UnitId) + '%'
Select @Message = NULL
Select @Message = Message, @Service_Desc = Service_Desc from Server_Log_Records Where Message Like @SQLString
If (@Message Is Not Null)
 	 Insert Into #TT(Area, Problem, Cause, Action) Values(0, 'Server Log Records Contain Error Messages Associated With EC_IDs For This Unit', Convert(nvarchar(2000), @Message), 'Examine The ' + @Service_Desc + ' Log Files For Details')
------------------------------------------------------------------
-- 3. variables with a non-null spec_id and no rows in var_specs
------------------------------------------------------------------
Insert Into #TT1 (Problem, Cause, [Action])
select 'No Rows For ' + V.Var_Desc ' Appear In Var_Specs', 'The Unit Variable [' + Convert(nvarchar(30), VS.Effective_Date) + '] Has Specifications Configured But No Rows Are Being Added To The Var_Specs Table For It' + V.Var_Desc, ''
from var_specs VS
Join Variables V on VS.Var_Id = V.Var_Id 
and  V.PU_Id = @UnitId
and V.Spec_Id Is Not Null 
If (Select Count(*) from #TT1) > 0
Begin
 	 Select @Message = NULL
 	 Declare MyCursor2 INSENSITIVE CURSOR
 	   For (Select Problem, Cause, Action From #TT1)
 	   For Read Only
 	   Open MyCursor2  
 	 
 	 -- Go through the Result set and find a report for this engine to run
 	 MyLoop2:
 	   Fetch Next From MyCursor2 Into @Problem, @Cause, @Action 
 	   If (@@Fetch_Status = 0)
 	  	 Begin -- Begin Loop Here
 	  	  	 Insert Into #TT(Area, Problem, Cause, Action) Values(0, @Problem, @Cause, @Action)
 	  	  	 Goto MyLoop2
 	  	 End -- End Loop Here
 	 
 	 myEnd2:
 	 Close MyCursor2
 	 Deallocate MyCursor2
End
------------------------------------------------------------------
-- 4. products + properties that have no characteristics assigned 
--    to this unit (pu_characteristics)
------------------------------------------------------------------
Create Table #R(Prod_Id int)
Insert Into #R(Prod_Id) (select distinct Prod_Id From PU_Products Where PU_ID = @UnitID)
Delete From #R Where Prod_Id In(Select Prod_Id From PU_Characteristics where PU_ID = @UnitID)
If (Select Count(*) From #R) > 0
Begin
 	 Declare MyCursor3 INSENSITIVE CURSOR
 	 For (
 	  	 Select #R.Prod_Id, P.Prod_Desc From #R
 	  	 Join Products P on P.Prod_Id = #R.Prod_Id
 	 )
 	 For Read Only
 	 Open MyCursor3
 	 MyLoop3:
 	   Fetch Next From MyCursor3 Into @Prod_Id, @Prod_Desc
 	   If (@@Fetch_Status = 0)
 	  	 Begin -- Begin Loop Here
 	  	  	 Insert Into #TT(Area, Problem, Cause, Action) Values(0, @Prod_Desc + ' Has No Characteristics', 'The Product "' + @Prod_Desc + '" ID = ' + Convert(VarChar(5), @Prod_Id)+  ', Is Configured For This Unit But No Characteristics Are Assigned', 'Configure Production Unit Characteristics')
 	  	  	 Goto MyLoop3
 	  	 End -- End Loop Here
 	 
 	 Close MyCursor3
 	 Deallocate MyCursor3
End
Drop Table #R
------------------------------------------------------------------
-- 5. No products assigned to the unit (pu_products)
------------------------------------------------------------------
If (select count(PU_Id) from pu_products where pu_id = @UnitId) = 0 
 	 Insert Into #TT(Area, Problem, Cause, Action) Values(0, 'No Products Are Associated With This Unit', 'Unit May Not Be Configured Correctly', 'Add Appropriate Products To This Unit')
if (Select Count(*) From #TT) = 0
 	 Insert Into #TT(Area, Problem, Cause, Action) Values(0, 'No Issues Were Found On This Unit', '', '')
goto Finish
-- Steps below are not complete yet
------------------------------------------------------------------
-- 6.  No Events Configured On Unit (Event_Configuration)
------------------------------------------------------------------
If (select Count(PU_ID) from event_configuration where PU_Id = @UnitId) = 0 
 	 Insert Into #TT(Area, Problem, Cause, Action) Values(0, 'No Events Are Configured For This Unit', 'Events May Not Be Configured Or Configured Correctly', 'Use The Administrator To Configured Events For This Unit')
------------------------------------------------------------------
-- 7.  Multiple Products But No Product Change Event (PU_Products)
-- What is the solution to this???
------------------------------------------------------------------
if (select Count(*) from PU_Products where PU_ID = @UnitId) > 0
 	 If (select Count(*) from production_starts where pu_Id = @UnitId) < 2
 	  	 begin
 	  	  	 Insert Into #TT(Area, Problem, Cause, Action) Values(0, 'No Product Change Events', 'Multiple Products Are Configured On This Unit But No Change Events Were Recorded', 'Examine The Server Log Files For More Details')
 	  	 end
------------------------------------------------------------------
-- 8.  Variables Attached to specification but no PU_Characteristics 
--     for those properties
-- Check Variables For Non-NULL spec_Id 
-- where there are no rows in PU_Characteristics
------------------------------------------------------------------
if (select Count(*) from variables where PU_ID = @UnitId and spec_Id > 0) > 0
 	 If (select Count(*) from pu_characteristics where PU_ID = @UnitId) = 0
 	  	 begin
 	  	  	 Insert Into #TT(Area, Problem, Cause, Action) Values(0, 'Unit Variables Have Specifications But No Characteristics', 'Variables Have Been Configured On This Unit To Have Specifications However No Rows Exist In Table "PU_Characteristics"', 'Examine The Server Log Files For More Details')
 	  	 end
------------------------------------------------------------------
-- 9. and 10.  Events Configured but no events or No Detection Model
-- Check Event_Configuration for production(1), downtime(2), waste(3)
-- See ED_Model_Id
-- Check for rows in Event_Configuration but no rows in the corresponding tables
------------------------------------------------------------------
Declare @Is_Active Int
Declare @ED_Model_Id Int
-- Check Production Events
If (select Count(*) from Event_Configuration where PU_ID = @UnitId and et_Id = 1) > 0
 	 Begin
 	  	 If (select Count(*) from Events where PU_ID = @UnitId) = 0
 	  	  	 Begin
 	  	  	  	 -- No Rows In Corresponding Event Table
 	  	  	  	 Select @Is_Active = Is_Active, @ED_Model_Id = ED_Model_Id From Event_Configuration Where PU_ID = @UnitId and et_Id = 1
 	  	  	  	 If @Is_Active = 0
 	  	  	  	  	 Begin
 	  	  	  	  	  	 Insert Into #TT(Area, Problem, Cause, Action) Values(0, 'Production Event Detection Not Active', 'Monitoring Production Events Is Configured On This Unit But Is Set As Inactive In Table "Event_Configuration"', 'Set The [IsActive]Field To Begin Collecting Production Events')
 	  	  	  	  	 End
 	  	  	  	 If @ED_Model_Id Is Null
 	  	  	  	  	 Begin
 	  	  	  	  	  	 Insert Into #TT(Area, Problem, Cause, Action) Values(0, 'No Production Events Model Assigned', 'No Event Detection Model Is Assigned To Detect Production Events In Table "Event_Configuration"', 'Assign A Model To This Configuration To Begin Collecting Production Events') 	  	  	  	  	 
 	  	  	  	  	 End
 	  	  	 End
 	 End
-- Check Downtime
If (select Count(*) from Event_Configuration where PU_ID = @UnitId and et_Id = 2) > 0
 	 Begin
 	  	 If (select Count(*) from Timed_Event_Details where PU_ID = @UnitId) = 0
 	  	  	 Begin
 	  	  	  	 -- No Rows In Corresponding Event Table
 	  	  	  	 Select @Is_Active = Is_Active, @ED_Model_Id = ED_Model_Id From Event_Configuration Where PU_ID = @UnitId and et_Id = 1
 	  	  	  	 If @Is_Active = 0
 	  	  	  	  	 Begin
 	  	  	  	  	  	 Insert Into #TT(Area, Problem, Cause, Action) Values(0, 'Downtime Event Detection Not Active', 'Downtime Is Configured On This Unit But Is Set As Inactive In Table "Event_Configuration"', 'Set The [IsActive] Field To Begin Collecting Downtime')
 	  	  	  	  	 End
 	  	  	  	 If @ED_Model_Id Is Null
 	  	  	  	  	 Begin
 	  	  	  	  	  	 Insert Into #TT(Area, Problem, Cause, Action) Values(0, 'No Downtime Model Assigned', 'No Event Detection Model Is Assigned To Detect Downtime In Table "Event_Configuration"', 'Assign A Model To This Configuration To Begin Collecting Downtime') 	  	  	  	  	 
 	  	  	  	  	 End
 	  	  	 End
 	 End
-- Check Downtime
If (select Count(*) from Event_Configuration where PU_ID = @UnitId and et_Id = 3) > 0
 	 Begin
 	  	 If (select Count(*) from Waste_Event_Details where PU_ID = @UnitId) = 0
 	  	  	 Begin
 	  	  	  	 -- No Rows In Corresponding Event Table
 	  	  	  	 Select @Is_Active = Is_Active, @ED_Model_Id = ED_Model_Id From Event_Configuration Where PU_ID = @UnitId and et_Id = 1
 	  	  	  	 If @Is_Active = 0
 	  	  	  	  	 Begin
 	  	  	  	  	  	 Insert Into #TT(Area, Problem, Cause, Action) Values(0, 'Downtime Event Detection Not Active', 'Downtime Is Configured On This Unit But Is Set As Inactive In Table "Event_Configuration"', 'Set The [IsActive] Field To Begin Collecting Downtime')
 	  	  	  	  	 End
 	  	  	  	 If @ED_Model_Id Is Null
 	  	  	  	  	 Begin
 	  	  	  	  	  	 Insert Into #TT(Area, Problem, Cause, Action) Values(0, 'No Downtime Model Assigned', 'No Event Detection Model Is Assigned To Detect Downtime In Table "Event_Configuration"', 'Assign A Model To This Configuration To Begin Collecting Downtime') 	  	  	  	  	 
 	  	  	  	  	 End
 	  	  	 End
 	 End
/*
select * from event_configuration where PU_ID = 2 and et_Id = 1 -- Production  (See Events)
select * from event_configuration where PU_ID = 2 and et_Id = 2 -- Downtime    (See Timed_Event_Details)
select * from event_configuration where PU_ID = 2 and et_Id = 3 -- Waste 	     (See Waste_Event_Details)
select * from timed_event_details where PU_ID = 2
select * from waste_event_details where PU_ID = 2
select * from event_details where PU_ID = 2
select * from events where PU_ID = 2
*/
------------------------------------------------------------------
-- 10. No Event Detection Model 
-- select * from event_configuration where unit_id = x and ed_model_id is null
-- or Is_Active = 0
-- do this after checking step 9
------------------------------------------------------------------
------------------------------------------------------------------
-- 11. No specifications for product change 
--(check the time stamps of the first product change and first spec entry) (Var_Specs and Production_Starts)
-- When were the Var_Specs approved (effective) vs when did the production starts occur
/*
select v.var_Id, v.var_desc, ps.Start_Time, vs.Effective_Date from var_specs vs
Join Variables v on v.var_Id = vs.var_Id and v.PU_ID = 2
Join Production_Starts ps on ps.pu_Id = 2
Where PS.Start_Time < vs.Effective_Date
order by v.var_Id
*/
------------------------------------------------------------------
Declare @FirstProductionStart datetime
Declare @FirstVarSpecEntry datetime
-- Get First Production Start
select @FirstProductionStart = Min(Start_Time) from production_starts where PU_ID = @UnitId and confirmed = 1
-- Get Last Var_Spec Entry For Variables On This Unit
select @FirstVarSpecEntry = Min(Effective_Date) from var_specs vs
Join Variables v on v.var_Id = vs.var_Id and v.PU_ID = @UnitId
If (@FirstProductionStart < @FirstVarSpecEntry)
 	 Begin
 	  	 Insert Into #TT(Area, Problem, Cause, Action) Values(0, 'Variable Specifications Not Applied To Product Change', 'Variable Specifications Applied To This Unit Have Not Taken Effect And Will Not Until A Product Change Occurs.', 'If This Is The First Specification, Make The Effective Date Prior To The First Production Start On This Unit')
 	 End
------------------------------------------------------------------
-- 12. No Product Changes At All (Production_Starts) for this unit
-- @@rowcount > 1
------------------------------------------------------------------
if (select Count(*) from Production_Starts where PU_ID = @UnitId) <= 1
 	 begin
 	  	 Insert Into #TT(Area, Problem, Cause, Action) Values(0, 'No Product Changes', 'No Product Changes Have Occured On This Unit.  One (1) or Less Rows Appear In Table "Production_Starts".', 'Verify The Event Detection Model Is Configured Correctly')
 	 end
------------------------------------------------------------------
-- 13. No Crew Schedule For Unit (Crew_Schedule)
-- where @@Rowcount = 0
------------------------------------------------------------------
if (select Count(*) from Crew_Schedule where PU_ID = @UnitId) = 0
 	 begin
 	  	 Insert Into #TT(Area, Problem, Cause, Action) Values(0, 'Crew Schedule Not Configured', 'The Crew Schedule For This Unit Is Not Configured Or Not Configured Correctly', 'Use The Administrator To Configure The Crew Schedule')
 	 end
------------------------------------------------------------------
-- 14. No Fault List for Downtime/waste (Event_Configuration, Timed_event_FAults, Waste_Event_Faults)
-- check event configuation to see if downtime and/or waste is configured then:
-- check timed_event_fault for no rows for this unit
-- check waste_event_fault for no rows for this unit 
------------------------------------------------------------------
If (select Count(*) from event_configuration where PU_ID = @UnitId and ET_ID = 2) > 0
 	 If (select Count(*) from Timed_Event_Fault Where PU_ID = @UnitId) = 0
 	  	 begin
 	  	  	 Insert Into #TT(Area, Problem, Cause, Action) Values(0, 'No Fault List For Downtime', 'This Unit Is Configured For Downtime However No Rows Appear In Table "Timed_Event_Fault"', 'Use The Administrator To Verify Downtime Is Configured Correctly')
 	  	 end
If (select Count(*) from event_configuration where PU_ID = @UnitId and ET_ID = 2) > 0
 	 If (select Count(*) from Waste_Event_Fault Where PU_ID = @UnitId) = 0
 	  	 begin
 	  	  	 Insert Into #TT(Area, Problem, Cause, Action) Values(0, 'No Fault List For Downtime', 'This Unit Is Configured For Waste However No Rows Appear In Table "Timed_Event_Fault"', 'Use The Administrator To Verify Waste Is Configured Correctly')
 	  	 end
Finish:
Select ID,Area, Problem, Cause,Action From #TT
Drop Table #TT
Drop Table #TT1
