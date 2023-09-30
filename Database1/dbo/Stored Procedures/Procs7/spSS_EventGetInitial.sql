Create Procedure dbo.spSS_EventGetInitial
AS
 Declare @NoProductionLine nVarChar(25),
         @NoEventSubType nVarChar(25),
         @NoOrder nVarChar(25),
         @NoShipment nVarChar(25),
         @NoStatus nVarChar(25),
         @NoProductGroup nVarChar(25),
         @NoCrew nVarChar(25),
         @NoShift nVarChar(25)
 Select @NoProductionLine = '<Any>'
 Select @NoEventSubType = '<Any>'
 Select @NoOrder = '<Any>'
 Select @NoShipment = '<Any>'
 Select @NoStatus = '<Any>'
 Select @NoProductGroup = '<Any>'
 Select @NoCrew = '<Any>'
 Select @NoShift = '<Any>'
---------------------------------------------------------
-- Defaults
--------------------------------------------------------
 Select @NoProductionLine as NoProductionLine, @NoEventSubType as  NoEventSubType,
        @NoOrder as NoOrder, @NoShipment as NoShipment, @NoProductGroup as NoProductGroup,
        @NoCrew as NoCrew, @NoShift as NoShift, @NoStatus as NoStatus
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
-- Event SubTypes
-----------------------------------------------------
 Create Table #ES (Event_SubType_Id Int Null, Event_SubType_Desc nVarChar(50) Null)
 Insert Into #ES
  Select Event_SubType_Id, Event_SubType_Desc
   From Event_SubTypes
    Where ET_Id = 1
 Insert Into #ES (Event_SubType_Id, Event_SubType_Desc) 
  Values (0, @NoEventSubType)
 Select Event_SubType_Id, Event_SubType_Desc
  From #ES
   Order by Event_SubType_Desc
 Drop Table #ES
-----------------------------------------------------
-- Production Status
-----------------------------------------------------
 Create Table #ST (ProdStatus_Id Int Null, ProdStatus_Desc nVarChar(50) Null)
 Insert Into #ST
  Select ProdStatus_Id, ProdStatus_Desc
   From Production_Status
 Insert Into #ST (ProdStatus_Id, ProdStatus_Desc) 
  Values (0, @NoStatus)
 Select ProdStatus_Id, ProdStatus_Desc
  From #ST
   Order by ProdStatus_Desc
 Drop Table #ST
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
 Select 'Duration' as CriteriaName, 'Duration' as CriteriaField
 -- Select Null as CriteriaName, Null as CriteriaField
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
