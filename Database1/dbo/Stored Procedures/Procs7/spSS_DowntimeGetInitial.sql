Create Procedure dbo.spSS_DowntimeGetInitial
AS
 Declare @NoProductionLine nVarChar(25),
         @NoCause nVarChar(25),
         @NoAction nVarChar(25),
         @NoProductGroup nVarChar(25),
         @NoCrew nVarChar(25),
         @NoShift nVarChar(25),
         @NoStatus nVarChar(25),
         @NoFault nVarChar(25)
 Select @NoProductionLine = '<Any>'
 Select @NoCause = '<Any>'
 Select @NoAction = '<Any>'
 Select @NoProductGroup = '<Any>'
 Select @NoCrew = '<Any>'
 Select @NoShift = '<Any>'
 Select @NoStatus = '<Any>'
 Select @NoFault = '<Any>'
---------------------------------------------------------
-- Defaults
--------------------------------------------------------
 Select @NoProductionLine as NoProductionLine, @NoStatus as NoStatus,
        @NoCause as NoCause, @NoAction as NoAction, @NoProductGroup as NoProductGroup,
        @NoCrew as NoCrew, @NoShift as NoShift, @NoFault as NoFault 
-------------------------------------------------------
-- Production Lines
-------------------------------------------------------
 Create Table #PL (PL_Id Int Null, PL_Desc nVarChar(50) Null)
 Insert Into #PL
  Select PL_Id, PL_Desc
   From Prod_Lines
    Where PL_Id<>0
 Insert Into #PL (PL_Id, PL_Desc) 
  Values (0, @NoProductionLine)
 Select PL_Id, PL_Desc 
  From #PL
   Order by PL_Desc
 Drop Table #PL
-----------------------------------------------------
-- TImed_Event_Status
-----------------------------------------------------
 Create Table #ES ( TEStatus_Name nVarChar(50) Null)
 Insert Into #ES
  Select Distinct (TEStatus_Name)
   From Timed_Event_Status
 Insert Into #ES (TEStatus_Name) 
  Values (@NoStatus)
 Select TEStatus_Name
  From #ES
   Order by TEStatus_Name
 Drop Table #ES
----------------------------------------------------------
-- Product Groups
---------------------------------------------------------
 Create Table #ProductGroups (Product_Grp_Id Int NULL, Product_Grp_Desc nVarChar(50) NULL)
 Insert Into #ProductGroups
  Select Product_Grp_Id, Product_Grp_Desc
   From Product_Groups
 Insert Into #ProductGroups
  Values (0, @NoProductGroup)
 Select Product_Grp_Id, Product_Grp_Desc
  From #ProductGroups
   Order by Product_Grp_Desc
 Drop Table #ProductGroups
---------------------------------------------------------
-- Crew
-----------------------------------------------------------
 Create Table #Crew(CrewDesc nVarChar(50) NULL)
 Insert Into #Crew
  Select Distinct Crew_Desc 
   From Crew_Schedule
 Insert Into #Crew
  Values (@NoCrew)
 Select CrewDesc
  From #Crew
   Order by CrewDesc
 Drop Table #Crew
-------------------------------------------------------
-- Shift
---------------------------------------------------------
 Create Table #Shift(ShiftDesc nVarChar(50) NULL)
 Insert Into #Shift
  Select Distinct Shift_Desc 
   From Crew_Schedule
 Insert Into #Shift
  Values (@NoShift)
 Select ShiftDesc
  From #Shift
   Order by ShiftDesc
 Drop Table #Shift
---------------------------------------------------------
-- Filter by Statistics criteria
---------------------------------------------------------
-- Select 'Duration' as CriteriaName, 'Duration' as CriteriaField
 Select 'Duration' as CriteriaName, 'DateDiff(mi,Start_Time, End_Time)' as CriteriaField
---------------------------------------------------------
-- Filter by Statistics operation
---------------------------------------------------------
 Create Table #Operation ( OperationName nVarChar(50) Null, OperationString nVarChar(50) Null)
 Insert Into #Operation Values ('Greater Than','>')
 Insert Into #Operation Values ('Greater Than or Equal To','>=')
 Insert Into #Operation Values ('Smaller Than','<')
 Insert Into #Operation Values ('Smaller Than or Equal To','<=')
 Insert Into #Operation Values ('Equal To','=')
 Select OperationName, OperationString 
  From #Operation
   Order By OperationName
 Drop Table #Operation
/*   Not Supported at this time
--------------------------------------------------------
-- Get the tree ids used by alarms, and gets all levels for them
--------------------------------------------------------
 Create Table #CauseTree (Tree_Id int NULL)
 Insert Into #CauseTree
  Select Distinct Name_Id 
   From Prod_Events 
    Where Event_Type= 2
     And Name_Id Is Not Null
  Select 0 as Event_Reason_Id, @NoCause as Event_Reason_Name, 0 as parent_Event_Reason_Id, 0 as Event_Reason_Level
  Union
  Select Distinct D.Event_Reason_Id, E.Event_Reason_Name, D.Parent_Event_Reason_Id,
                  D.Event_Reason_Level
   From Event_Reason_Tree_Data D Inner Join #CauseTree T On D.Tree_Name_Id = T.Tree_Id
                                 Inner Join Event_Reasons E On E.Event_Reason_Id = D.Event_Reason_Id
    Order by E.Event_Reason_Name
 Drop Table #CauseTree
--------------------------------------------------------
-- Get the tree ids used by alarms, and gets all levels for them
--------------------------------------------------------
 Create Table #ActionTree (Tree_Id int NULL)
 Insert Into #ActionTree
  Select Distinct Action_Tree_Id 
   From Prod_Events 
    Where Event_Type= 2
     And Action_Tree_Id Is Not Null
  Select 0 as Event_Reason_Id, @NoAction as Event_Reason_Name, 0 as parent_Event_Reason_Id, 0 as Event_Reason_Level
  Union
  Select Distinct D.Event_Reason_Id, E.Event_Reason_Name, D.Parent_Event_Reason_Id,
                  D.Event_Reason_Level
   From Event_Reason_Tree_Data D Inner Join #ActionTree T On D.Tree_Name_Id = T.Tree_Id
                                 Inner Join Event_Reasons E On E.Event_Reason_Id = D.Event_Reason_Id
    Order by E.Event_Reason_Name
 Drop Table #ActionTree
*/
