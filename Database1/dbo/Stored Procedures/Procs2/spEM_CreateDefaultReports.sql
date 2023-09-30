/*
-------------------------------------
NOTES:
-------------------------------------
[2004-09-03 DS]  @RebuildLinks input parameter was added to the stored procedure.
Default value = 1 or 'YES' or 'TRUE'
When RebuildLinks = 1 then as tree node links get generated, the url will be restored and
the link to the report definition (if there) will be removed.
============== TESTING ==============
select PL_Id, PL_Desc from prod_Lines
select PU_Id, PU_Desc from prod_units
-- Whole Tree
EXEC spEM_CreateDefaultReports 'dz', 1, -4
-- Particular Line
EXEC spEM_CreateDefaultReports 'ad', 2, -4
-- Particular Unit
EXEC spEM_CreateDefaultReports 'ae', 2, -4 
Problem: this creates report nodes at the line level
=====================================
*/
CREATE   PROCEDURE dbo.spEM_CreateDefaultReports
@NodeType nVarChar(2),
@Id int,
@TreeId Int,
@RebuildLinks Int = 1
AS
/*
Administrator node types
dz - Department
ad - Line
ae - unit
*/
if @RebuildLinks = 0 
 	 Print 'DO NOT REBUILD THE LINKS'
Else
 	 print 'YES - REBUILD ALL THE LINKS' 
-----------------------------------------------------
-- Local Parameters
-----------------------------------------------------
Declare @PU_Id int
Declare @PL_Id int
Declare @Dept_Id int
Declare @NewRowId Int
Declare @LocalDeptId int
Declare @LocalPLId int
Declare @LocalPUId int
Declare @LocalDesc nvarchar(50)
Declare @LocalParentNodeId int
Declare @TempId int
Declare @ReportId int
Declare @ReportName nvarchar(255)
Declare @ReportTypeName nvarchar(255)
-- Constants --
Create Table #LocalLog(Msg nvarchar(255))
Declare @DefaultTreeName nvarchar(20)
Select @DefaultTreeName = 'Plant Model'
-----------------------------------------------------
-- Initialize
-----------------------------------------------------
If @NodeType = 'dz' Select @Dept_Id = @Id
If @NodeType = 'ad' Select @PL_Id = @Id
If @NodeType = 'ae' Select @PU_Id = @Id
-----------------------------------------------------
-- Setup The Default Plant Tree
-----------------------------------------------------
If @TreeId Is Null
  Begin
 	 Select @TreeId = Report_Tree_Template_Id From Report_Tree_Templates Where Report_Tree_Template_Name = @DefaultTreeName
 	 If @TreeId Is Null 
 	  	 Begin
 	  	  	 Insert Into #LocalLog(Msg) Values('Creating New Default Plant Tree')
 	  	  	 Insert Into Report_Tree_Templates(Report_Tree_Template_Name) Values(@DefaultTreeName)
 	  	  	 Select @TreeId = Scope_Identity()
 	  	 End 
 	 Else
 	  	 Begin
 	  	  	 Insert Into #LocalLog(Msg) Values('Updating Default Plant Tree')
 	  	 End
  End
Else
  Begin
 	 Insert Into #LocalLog(Msg) Values('Updating User Selected Tree')
  End
-----------------------------------------------------
-- Setup Temp Tables
-----------------------------------------------------
Create Table #Departments(Insert_Id int,Dept_Id int,Dept_Desc nvarchar(50))
Create Table #Prod_Lines(Insert_Id int,PL_Id int,Dept_Id int,PL_Desc nvarchar(50))
Create Table #Prod_Units(Insert_Id int, PU_Id int, PL_Id int, PU_Desc nvarchar(50))
-----------------------------------------------------
-- Get All units for selected Dept, Line or Unit 
-----------------------------------------------------
If @Dept_Id Is Not Null
 	 Begin
 	  	 Print 'Building Reports From Department Level'
 	  	 Insert Into #LocalLog(Msg) Values('Building Reports From Department Level')
 	  	 Insert Into #Departments(Dept_Id, Dept_Desc)
 	  	 Select Dept_Id, Dept_Desc from departments Where Dept_Id = @Dept_Id
 	  	 Insert Into #Prod_Lines(PL_Id, Dept_Id, PL_Desc)
 	  	 Select PL_ID, Dept_Id, PL_Desc From Prod_Lines Where PL_Id <> 0 AND Dept_Id in (Select Dept_Id From  #Departments)
 	  	 Insert Into #Prod_Units(PU_Id, PL_Id, PU_Desc)
 	  	 Select PU_Id, PL_Id, PU_Desc From Prod_Units Where PL_Id in (Select PL_Id From Prod_Lines)
 	 End
Else If @PL_Id Is Not Null
 	 Begin
 	  	 Print 'Building Reports From Production Line Level'
 	  	 Insert Into #LocalLog(Msg) Values('Building Reports From Production Line Level')
 	  	 Insert Into #Prod_Lines(PL_Id, Dept_Id, PL_Desc)
 	  	 Select PL_Id, Dept_Id, PL_Desc From Prod_Lines Where PL_Id = @PL_Id
 	  	 Insert Into #Departments(Dept_Id, Dept_Desc)
 	  	 Select Dept_Id, Dept_Desc from departments Where Dept_Id in (Select distinct(Dept_Id) From #Prod_Lines)
 	  	 Insert Into #Prod_Units(PU_Id, PL_Id, PU_Desc)
 	  	 Select PU_Id, PL_Id, PU_Desc From Prod_Units Where PL_Id in (Select distinct(PL_Id) From Prod_Lines) 	  	 
 	 End
Else If @PU_Id Is Not Null
 	 Begin
 	  	 Print 'Building Reports From Production Unit Level'
 	  	 Insert Into #LocalLog(Msg) Values('Building Reports From Production Unit Level')
 	  	 Insert Into #Prod_Units(PU_Id, PL_Id, PU_Desc)
 	  	 Select distinct PU_Id, PL_Id, PU_Desc From Prod_Units Where PU_Id = @PU_Id
 	  	 Insert Into #Prod_Lines(PL_Id, Dept_Id, PL_Desc)
 	  	 Select PL_Id, Dept_Id, PL_Desc From Prod_Lines Where PL_Id in (Select PL_Id From #Prod_Units)
 	  	 Insert Into #Departments(Dept_Id, Dept_Desc)
 	  	 Select Dept_Id, Dept_Desc from departments Where Dept_Id in (Select distinct(Dept_Id) From #Prod_Lines)
 	 End
------------------------------------
-- DEPARTMENTS
------------------------------------
Declare @DepartmentCursor Cursor
Set  @DepartmentCursor = Cursor For
 	 Select Dept_Id, Dept_Desc From #Departments
Open @DepartmentCursor
BeginDepartmentLoop:
 	 Fetch Next From @DepartmentCursor Into @LocalDeptId, @LocalDesc
 	 If (@@Fetch_Status = 0)
 	  	 Begin 
 	  	  	 -- ALSO check for an existing node by this name prior to doing an insert
 	  	  	 -- if one exists, then do a select and get it's node id
 	  	  	 Select @NewRowId = Null
 	  	  	 Select @NewRowId = Node_Id From Report_Tree_Nodes Where Report_Tree_Template_Id = @TreeId AND Node_Name = @LocalDesc AND Parent_Node_Id Is Null
 	  	  	 -- Add A Department Level Folder
 	  	  	 If @NewRowId Is Null Exec spRS_AddReportTreeNode @TreeId, 1, @LocalDesc, Null, Null, Null, Null, @NewRowId output
 	  	  	 Insert Into #LocalLog(Msg) Values('Adding Department Level Tree Node ' + @LocalDesc)
 	  	  	 Update #Departments Set Insert_Id = @NewRowId Where Dept_Id = @LocalDeptId
 	  	  	 Print 'Adding Department Level Tree Node ' + Convert(nVarChar(10), @NewRowId)
 	  	  	 Goto BeginDepartmentLoop
 	  	 End 
Close @DepartmentCursor
Deallocate @DepartmentCursor
Select @NewRowId = Null
------------------------------------
-- PRODUCTION LINES
------------------------------------
Declare @ProductionLineCursor Cursor 	 
Set  @ProductionLineCursor = Cursor For
 	 select D.Insert_Id as Parent_Node_Id, PL.PL_Id, PL.Dept_Id, PL.PL_Desc from #Prod_Lines PL
 	 Join #Departments D on PL.Dept_Id = PL.Dept_Id
Open @ProductionLineCursor
BeginProductionLineLoop:
 	 Fetch Next From @ProductionLineCursor Into @LocalParentNodeId, @LocalPLId, @LocalDeptId, @LocalDesc
 	 If (@@Fetch_Status = 0)
 	  	 Begin 
 	  	  	 -- ALSO check for an existing node by this name prior to doing an insert
 	  	  	 -- if one exists, then do a select and get it's node id
 	  	  	 Select @NewRowId = Null
 	  	  	 Select @NewRowId = Node_Id From Report_Tree_Nodes Where Node_Name = @LocalDesc and Parent_Node_Id = @LocalParentNodeId
 	  	  	 -- Add A Line Level Folder
 	  	  	 If @NewRowId Is Null Exec spRS_AddReportTreeNode @TreeId, 1, @LocalDesc, @LocalParentNodeId, Null, Null, Null, @NewRowId output
 	  	  	 Update #Prod_Lines Set Insert_Id = @NewRowId Where PL_Id = @LocalPLId
 	  	  	 Insert Into #LocalLog(Msg) Values('Adding Production Line Node ' + @LocalDesc)
 	  	  	 -- Add Line Level Reports
 	  	  	 Exec spRS_AdminAddPlantModelReports @LocalPLId, Null, @NewRowId, @RebuildLinks
 	  	  	 Goto BeginProductionLineLoop
 	  	 End 
Close @ProductionLineCursor
Deallocate @ProductionLineCursor
Select @NewRowId = Null
------------------------------------
-- PRODUCTION Units
------------------------------------
Declare @ProductionUnitCursor Cursor
Set  @ProductionUnitCursor = Cursor For
 	 select PL.Insert_Id as Parent_Node_Id, PU.PU_Id, PU.PL_Id, PU.PU_Desc from #Prod_Units PU
 	 Join #Prod_Lines PL on PU.PL_Id = PL.PL_Id
Open @ProductionUnitCursor
BeginProductionUnitLoop:
 	 Fetch Next From @ProductionUnitCursor Into @LocalParentNodeId, @LocalPUId, @LocalPLId, @LocalDesc
 	 If (@@Fetch_Status = 0)
 	  	 Begin 
 	  	  	 
 	  	  	 Select @NewRowId = Null
 	  	  	 Select @NewRowId = Node_Id From Report_Tree_Nodes Where Node_Name = @LocalDesc and Parent_Node_Id = @LocalParentNodeId
 	  	  	 -- Add A Unit Level Folder
 	  	  	 If @NewRowId Is Null Exec spRS_AddReportTreeNode @TreeId, 1, @LocalDesc, @LocalParentNodeId, Null, Null, Null, @NewRowId output
 	  	  	 Insert Into #LocalLog(Msg) Values('Adding Production Unit Node ' + @LocalDesc)
 	  	  	 -- Add Unit Level Reports
 	  	  	 Exec spRS_AdminAddPlantModelReports Null, @LocalPUId, @NewRowId, @RebuildLinks
 	  	  	 Goto BeginProductionUnitLoop
 	  	 End 
Close @ProductionUnitCursor
Deallocate @ProductionUnitCursor
Insert Into #LocalLog(Msg) Values('== Tree Generation Complete ==')
Insert Into #LocalLog(Msg) Values('Results Can Be Viewed Using The Web Server Administrator')
Select * From #LocalLog
-----------------------------------------------------
-- Cleanup Temp Tables
-----------------------------------------------------
Drop Table #LocalLog
Drop Table #Prod_Units
Drop Table #Prod_Lines
Drop Table #Departments
