/*
-------------------------------------
NOTES:
-------------------------------------
[2004-09-03 DS]  @RebuildLinks input parameter was added to the stored procedure.
Default value = 1 or 'YES' or 'TRUE'
When RebuildLinks = 1 then as tree node links get generated, the url will be restored and
the link to the report definition (if there) will be removed.
[2004-July DS]
This sp will read the report configuration from the Report_Tree_Model table.
This table contains static data regarding what the plant model tree structure 
should look like and what reports to attach to a given node.  The column SQL
contains a valid sql string to be executed.  If 1 or more rows are returned from 
the statement, then that folder will be added to the tree - otherwise it will
be skipped.
This procedure is called by spEM_CreateDefaultReports
 	 spEM_CreateDefaultReports <dz|ad|ae>, ID, TreeId
 	 dz = Whole Tree
 	 ad = Particular Line
 	 ae = Particular Unit
-- Whole Tree
EXEC spEM_CreateDefaultReports 'dz', 1, -4
-- Particular Line
EXEC spEM_CreateDefaultReports 'ad', 2, -4
-- Particular Unit
EXEC spEM_CreateDefaultReports 'ae', 2, -4, 0  -- do not rebuild links
EXEC spEM_CreateDefaultReports 'ae', 2, -4, 1  -- YES rebuild all links
*/
CREATE PROCEDURE dbo.spRS_AdminAddPlantModelReports
@PL_Id int = NULL,
@PU_Id int = NULL,
@ParentNodeId int,
@RebuildLinks Int = 1
 AS
if @RebuildLinks = 0 
 	 Print 'DO NOT REBUILD THE LINKS'
Else
 	 print 'YES - REBUILD ALL THE LINKS' 
---------------------------------
-- Local Parameters
---------------------------------
Declare @Unit_Level_Report tinyint
Declare @Report_Type_Id int
Declare @Report_Name varchar(255)
Declare @Report_Parameters varchar(7000)
Declare @Sub_Node_Name varchar(255)
Declare @URL varchar(1000)
Declare @TempSQL varchar(1000)
Declare @SQL varchar(1000)
Declare @SubFolderId int
Declare @TreeId int
Declare @ReportNamePrefix varchar(255)
Declare @NewReportName varchar(255)
Declare @ReportId Int
Declare @NewReportTreeNodeId int
Declare @ExecuteThisRow int
Declare @ExistingNodeId int
Declare @UnitConformanceVariables varchar(8000)
Declare @UnitConformanceVariableQuery varchar(1000)
Declare @AllUnitsOnThisLine varchar(8000)
Declare @AllUnitsOnThisLineQuery varchar(1000)
Declare @InventoryUnitsOnThisLine varchar(8000)
Declare @InventoryUnitsOnThisLineQuery varchar(1000)
Declare @DefaultUnitSheetID int
Declare @DefaultUnitSheetName varchar(50)
Declare @DefaultUnitTimeBasedSheetID int
Declare @DefaultUnitEventBasedSheetID int
Declare @ThisProductionLine int
-- Get A Default Sheet Name In Case None Are Specified For A Given Unit
Declare @FirstSheetName VarChar(255)
Create Table #SheetNameTable(SheetName VarChar(255), Sheet_Desc Varchar(255))
Insert Into #SheetNameTable Exec spWO_GetSheetNameList
Select @FirstSheetName = (Select Top 1 SheetName From #SheetNameTable)
Drop Table #SheetNameTable
Create Table #SQLFilter(Id Int)
---------------------------------
-- Initialize Local Variables
---------------------------------
-- Get The Template Id
Select @TreeId = Report_Tree_Template_Id From Report_Tree_Nodes Where Node_Id = @ParentNodeId
If @PL_Id Is Not Null
 	 Select @ReportNamePrefix = PL_Desc from Prod_Lines Where PL_Id = @PL_Id
If @PU_Id Is Not Null
     Begin
 	  	 Select @ReportNamePrefix = PU_Desc from Prod_Units Where PU_Id = @PU_Id
 	  	 Select @ThisProductionLine = PL_Id From Prod_Units Where PU_ID = @PU_ID
 	 End
---------------------------------
-- Begin Parsing
---------------------------------
Declare @ReportCursor Cursor
Set  @ReportCursor = Cursor For
 	 --select Unit_Level_Report, Report_Type_Id, Report_Name, Report_Parameters, Sub_Node_Name, URL, SQL From Report_Tree_Model
 	 select Unit_Level_Report, Report_Name, Sub_Node_Name, URL, SQL From Report_Tree_Model
Open @ReportCursor
BeginReportCursorLoop:
 	 Fetch Next From @ReportCursor Into @Unit_Level_Report, @Report_Name, @Sub_Node_Name, @URL, @TempSQL
 	 If (@@Fetch_Status = 0)
 	  	 Begin 
 	  	  	 -- Set New Report Name
 	  	  	 Select @NewReportName = NULL
 	  	  	 Select @NewReportName = @ReportNamePrefix + ' ' + @Report_Name
 	  	  	 -- Initialize Variables
 	  	  	 Select @ReportId = NULL
 	  	  	 Select @ExistingNodeId = NULL
 	  	  	 Select @DefaultUnitSheetID = NULL
 	  	  	 Select @DefaultUnitSheetName = Coalesce(@FirstSheetName, '')
 	  	  	 -------------------------------
 	  	  	 -- Should I Process This Row?
 	  	  	 -------------------------------
 	  	  	 Select @ExecuteThisRow = 1 	 -- Default = YES
 	  	  	 Select @SQL = NULL
 	  	  	 -- String Replacement
 	  	  	 If (@PL_Id Is Not Null)
 	  	  	  	 Begin
 	  	  	  	  	 Select @SQL = Replace(@TempSQL, '@PL_Id', @PL_Id)
 	  	  	  	  	 Select @ThisProductionLine = @PL_ID
 	  	  	  	  	 If @URL Is Not Null
 	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	 -- Get All Units On This Line
 	  	  	  	  	  	  	 Select @AllUnitsOnThisLine = NULL
 	  	  	  	  	  	  	 Select @AllUnitsOnThisLineQuery = 'Select PU_ID from Prod_Units Where PL_Id = ' + Convert(Varchar(5), @PL_ID)
 	  	  	  	  	  	  	 EXEC spRS_MakeStringFromQueryResults @AllUnitsOnThisLineQuery, @AllUnitsOnThisLine output
 	  	  	  	  	  	  	 -- Get Inventory Units On This Line
 	  	  	  	  	  	  	 Select @InventoryUnitsOnThisLine = NULL
 	  	  	  	  	  	  	 Select @InventoryUnitsOnThisLineQuery = 'Select pu.pu_id from prod_units pu Join event_configuration ec on ec.pu_id = pu.pu_id and ec.et_id = 1 where pu.pu_id <> 0 and pu.pl_id = ' + Convert(Varchar(5), @PL_ID)
 	  	  	  	  	  	  	 EXEC spRS_MakeStringFromQueryResults @InventoryUnitsOnThisLineQuery, @InventoryUnitsOnThisLine output
 	  	  	  	  	  	  	 If Len(@InventoryUnitsOnThisLine) = 0 Select @InventoryUnitsOnThisLine = '0'
 	  	  	  	  	  	 End
 	  	  	  	 End 
 	  	  	 If (@PU_Id Is Not Null)
 	  	  	  	 Begin
 	  	  	  	  	 -- Replace PU_ID
 	  	  	  	  	 Print '@PU_Id Is Not Null'
 	  	  	  	  	 Select @SQL = Replace(@SQL, '@PU_Id', @PU_Id)
 	  	  	  	  	 -- Get Conformance Variables
 	  	  	  	  	 Select @UnitConformanceVariables = NULL
 	  	  	  	  	 Select @UnitConformanceVariableQuery = 'select top 20 var_Id from variables where Is_Conformance_Variable = 1 and PU_Id = ' + Convert(VarChar(5), @PU_Id)
 	  	  	  	  	 EXEC spRS_MakeStringFromQueryResults @UnitConformanceVariableQuery, @UnitConformanceVariables output
 	  	  	  	  	 -- First Time Based Sheet With Attached Variables
 	  	  	  	  	 Select @DefaultUnitTimeBasedSheetID = min(sv.sheet_Id) from sheet_variables sv Join Sheets s on s.sheet_id = sv.sheet_Id and s.master_Unit is null and s.sheet_type = 1
 	  	  	  	  	 -- First Event Based Sheet With Attached Variables
 	  	  	  	  	 Select @DefaultUnitEventBasedSheetID = min(sv.sheet_Id) from sheet_variables sv Join Sheets s on s.sheet_id = sv.sheet_Id and s.master_Unit is null and s.sheet_type = 2
 	  	  	  	  	 -- Default Sheets
 	  	  	  	  	 Select @DefaultUnitSheetId = Sheet_Id From Prod_Units Where PU_ID = @PU_ID
 	  	  	  	  	 If @DefaultUnitSheetId Is Null
 	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	 -- There is no default sheet configured
 	  	  	  	  	  	  	 
 	  	  	  	  	  	  	 If (CharIndex('[DEFAULTTIMESHEETNAME]', @URL) > 0) or (CharIndex('[DEFAULTTIMESHEETID]', @URL) > 0)
 	  	  	  	  	  	  	  	 Select @DefaultUnitSheetId = @DefaultUnitTimeBasedSheetID
 	 
 	  	  	  	  	  	  	 If (CharIndex('[DEFAULTEVENTSHEETNAME]', @URL) > 0) or (CharIndex('[DEFAULTEVENTSHEETID]', @URL) > 0)
 	  	  	  	  	  	  	  	 Select @DefaultUnitSheetId = @DefaultUnitEventBasedSheetID
 	  	  	  	  	  	 End
 	  	  	  	  	 -- Get the name of the selected sheet
 	  	  	  	  	 If @DefaultUnitSheetId Is Not Null
 	  	  	  	  	  	 Select @DefaultUnitSheetName = Sheet_Desc From Sheets Where Sheet_Id = @DefaultUnitSheetId
 	  	 
 	  	  	  	  	 --Parameter Criteria
 	  	  	  	  	 If (CharIndex('[CONFORMANCEVARIABLES]', @URL) > 0) AND (LEN(@UnitConformanceVariables) = 0)
 	  	  	  	  	  	 Select @ExecuteThisRow = 0
 	  	  	  	  	 If (CharIndex('[DEFAULTSHEETNAME]', @URL) > 0) AND (LEN(@DefaultUnitSheetName) = 0)
 	  	  	  	  	  	 Select @ExecuteThisRow = 0
 	  	  	  	  	 If (CharIndex('[DEFAULTSHEETID]', @URL) > 0) AND (LEN(@DefaultUnitSheetID) = 0)
 	  	  	  	  	  	 Select @ExecuteThisRow = 0 	  	 
 	  	  	  	  	 If ((CharIndex('[DEFAULTTIMESHEETNAME]', @URL) > 0) OR (CharIndex('[DEFAULTEVENTSHEETNAME]', @URL) > 0)) AND (@DefaultUnitSheetName Is NULL)
 	  	  	  	  	  	 Select @ExecuteThisRow = 0
 	  	  	  	  	 If ((CharIndex('[DEFAULTTIMESHEETID]', @URL) > 0) OR (CharIndex('[DEFAULTEVENTSHEETID]', @URL) > 0)) AND (@DefaultUnitSheetID Is NULL)
 	  	  	  	  	  	 Select @ExecuteThisRow = 0 	  	 
 	  	  	  	 End
 	  	  	 -- Do not process this sql string if @PL_ID or @PU_ID are still in it
 	  	  	 If (CharIndex('@PL_Id', @SQL, 1) = 0) and (CharIndex('@PU_Id', @SQL, 1) = 0)
 	  	  	  	 Begin
 	  	  	  	  	 --Print 'Executing Filter SQL:: ' + @SQL
 	  	  	  	  	 Insert Into #SQLFilter Exec(@SQL)
 	 
 	  	  	  	  	 --Exec (@SQL)
 	  	  	  	  	 -- If 1 or more rows are returned then the criteria for this unit or line has been met
 	  	  	  	  	 Select @ExecuteThisRow = @@RowCount
 	  	  	  	 End
 	  	 
 	  	  	 -------------------------------
 	  	  	 -- Fetch Next Row or Add Node ?
 	  	  	 -------------------------------
 	  	  	 If @ExecuteThisRow = 0 
 	  	  	  	 Begin
 	  	  	  	  	 --Print 'Row Will Not Be Generated'
 	  	  	  	  	 GoTo BeginReportCursorLoop
 	  	  	  	 End
 	  	  	 -------------------------------
 	  	  	 -- Continue Processing
 	  	  	 -------------------------------
 	  	  	 Select @URL = Replace(@URL, '@PL_Id', Coalesce(@ThisProductionLine, ''))
 	  	  	 Select @URL = Replace(@URL, '@PU_Id', Coalesce(@PU_Id, ''))
 	  	  	 Select @URL = Replace(@URL, '[ALLUNITSONLINE]', Coalesce(@AllUnitsOnThisLine, ''))
 	  	  	 Select @URL = Replace(@URL, '[INVENTORYUNITSONLINE]', Coalesce(@InventoryUnitsOnThisLine, ''))
 	  	  	 Select @URL = Replace(@URL, '[CONFORMANCEVARIABLES]', Coalesce(@UnitConformanceVariables, ''))
 	  	  	 Select @URL = Replace(@URL, '[DEFAULTSHEETNAME]', Coalesce(@DefaultUnitSheetName, ''))
 	  	  	 Select @URL = Replace(@URL, '[DEFAULTSHEETID]', Convert(VarChar(5), Coalesce(@DefaultUnitSheetID, '')))
 	  	  	 Select @URL = Replace(@URL, '[DEFAULTTIMESHEETNAME]', Coalesce(@DefaultUnitSheetName, ''))
 	  	  	 Select @URL = Replace(@URL, '[DEFAULTTIMESHEETID]', Convert(VarChar(5), Coalesce(@DefaultUnitSheetID, '')))
 	  	  	 Select @URL = Replace(@URL, '[DEFAULTEVENTSHEETNAME]', Coalesce(@DefaultUnitSheetName, ''))
 	  	  	 Select @URL = Replace(@URL, '[DEFAULTEVENTHEETID]', Convert(VarChar(5), Coalesce(@DefaultUnitSheetID, '')))
 	  	  	 Print '============== new url ============='
 	  	  	 Print @URL
 	  	  	 Print '============== new url ============='
 	  	  	 -------------------------------
 	  	  	 -- This Is A Line Level Report
 	  	  	 -------------------------------
 	  	  	 If @PL_Id Is Not NULL AND @Unit_Level_Report = 0
 	  	  	  	 Begin 	  	  	  	  	  	  	  	 
 	  	  	  	  	 -- Does This Node Already Exist In The Tree
 	  	  	  	  	 Select @ExistingNodeId = Node_Id From Report_Tree_Nodes Where Parent_Node_Id = @ParentNodeId And Node_Name = @NewReportName
 	  	  	  	  	 if (@ExistingNodeId Is Not NULL) 
 	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	 If @RebuildLinks = 1
 	  	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	 If CharIndex('MSWebPart', @URL, 1) > 0
 	  	  	  	  	  	  	  	  	  	 Update Report_Tree_Nodes Set ForceRunMode = NULL, URL = @URL, Node_Id_Type = 16, Report_Def_Id = NULL Where Node_Id = @ExistingNodeId
 	  	  	  	  	  	  	  	  	 Else
 	  	  	  	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  	  	 Select @ReportId = Report_Def_Id From Report_Tree_Nodes Where Node_Id = @ExistingNodeId
 	  	  	  	  	  	  	  	  	  	  	 If @ReportId Is Not Null
 	  	  	  	  	  	  	  	  	  	  	  	 Exec spRS_AdminIncrementSimilarReportNames @ReportId
 	  	  	  	  	  	  	  	  	  	  	 Update Report_Tree_Nodes Set ForceRunMode = NULL, URL = @URL, Node_Id_Type = 17, Report_Def_Id = NULL Where Node_Id = @ExistingNodeId
 	  	  	  	  	  	  	  	  	  	 End
 	  	  	  	  	  	  	  	 End
 	  	  	  	  	  	 End
 	  	  	  	  	 Else
 	  	  	  	  	  	 Begin 	  	  	  	  	  	 
 	  	  	  	  	  	  	 If CharIndex('MSWebPart', @URL, 1) > 0
 	  	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	 Insert Into #LocalLog(Msg) Values('Adding Web Part ' + @NewReportName)
 	  	  	  	  	  	  	  	  	 Exec spRS_AddReportTreeNode @TreeId, 16, @NewReportName, @ParentNodeId, NULL, Null, @URL, @NewReportTreeNodeId output 	  	  	  	  	  	  	  	 
 	  	  	  	  	  	  	  	 End
 	  	  	  	  	  	  	 Else
 	  	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	 Insert Into #LocalLog(Msg) Values('Adding ASP Report ' + @NewReportName)
 	  	  	  	  	  	  	  	  	 Exec spRS_AddReportTreeNode @TreeId, 17, @NewReportName, @ParentNodeId, NULL, Null, @URL, @NewReportTreeNodeId output 	  	  	  	  	  	  	  	 
 	  	  	  	  	  	  	  	 End
 	  	  	  	  	  	 End
 	  	  	  	  	 
 	  	  	  	 End
 	  	  	 -------------------------------
 	  	  	 -- This Is A Unit Level Report
 	  	  	 -------------------------------
 	  	  	 If (@PU_Id Is Not Null) AND (@Unit_Level_Report = 1)
 	  	  	  	 Begin
 	  	  	  	  	 Select @SubFolderId = NULL
 	  	  	  	  	 -- Add Unit Level Folder
 	  	  	  	  	 If @Sub_Node_Name Is Null
 	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	 Select @SubFolderId = @ParentNodeId
 	  	  	  	  	  	 End
 	  	  	  	  	 Else
 	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	 Select @SubFolderId = Node_Id From Report_Tree_Nodes Where Node_Name = @Sub_Node_Name and Parent_Node_Id = @ParentNodeId
 	  	  	  	  	  	  	 If @SubFolderId Is Null 
 	  	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	 Print 'spRS_AdminCreateDefinition::Adding Production Unit Folder ' + @Sub_Node_Name
 	  	  	  	  	  	  	  	  	 Insert Into #LocalLog(Msg) Values('Adding Sub Folder ' + @Sub_Node_Name)
 	  	  	  	  	  	  	  	  	 Exec spRS_AddReportTreeNode @TreeId, 1, @Sub_Node_Name, @ParentNodeId, Null, Null, Null, @SubFolderId output 	 
 	  	  	  	  	  	  	  	 End
 	  	  	  	  	  	 End
 	  	  	  	  	 Select @ExistingNodeId = Node_Id From Report_Tree_Nodes Where Parent_Node_Id = @SubFolderId And Node_Name = @NewReportName
 	  	  	  	  	 
 	  	  	  	  	 If (@ExistingNodeId Is Not NULL)
 	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	 Print 'Updating Unit Level Report Tree Node'
 	  	  	  	  	  	  	 Print @NewReportName + ' = ' + @URL
 	  	  	  	  	  	  	 Insert Into #LocalLog(Msg) Values('Updating URL For Report ' + @NewReportName)
 	  	  	  	  	  	  	 -- If Rebuild = True then update the link in the tree
 	  	  	  	  	  	  	 If @RebuildLinks = 1
 	  	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	 If CharIndex('MSWebPart', @URL, 1) > 0
 	  	  	  	  	  	  	  	  	  	 Update Report_Tree_Nodes Set ForceRunMode = NULL, URL = @URL, Node_Id_Type = 16, Report_Def_Id = NULL Where Node_Id = @ExistingNodeId
 	  	  	  	  	  	  	  	  	 Else
 	  	  	  	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  	  	 Select @ReportId = Report_Def_Id From Report_Tree_Nodes Where Node_Id = @ExistingNodeId
 	  	  	  	  	  	  	  	  	  	  	 If @ReportId Is Not Null
 	  	  	  	  	  	  	  	  	  	  	  	 Exec spRS_AdminIncrementSimilarReportNames @ReportId
 	  	  	  	  	  	  	  	  	  	  	 Update Report_Tree_Nodes Set ForceRunMode = NULL, URL = @URL, Node_Id_Type = 17, Report_Def_Id = NULL Where Node_Id = @ExistingNodeId
 	  	  	  	  	  	  	  	  	  	 End
 	  	  	  	  	  	  	  	 End
 	  	  	  	  	  	 End
 	  	  	  	  	 Else
 	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	 If CharIndex('MSWebPart', @URL, 1) > 0
 	  	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	 Insert Into #LocalLog(Msg) Values('Adding Web Part ' + @NewReportName)
 	  	  	  	  	  	  	  	  	 Exec spRS_AddReportTreeNode @TreeId, 16, @NewReportName, @SubFolderId, NULL, Null, @URL, @NewReportTreeNodeId output 	  	 
 	  	  	  	  	  	  	  	 End
 	  	  	  	  	  	  	 Else
 	  	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	 Insert Into #LocalLog(Msg) Values('Adding ASP Report ' + @NewReportName)
 	  	  	  	  	  	  	  	  	 Exec spRS_AddReportTreeNode @TreeId, 17, @NewReportName, @SubFolderId, NULL, Null, @URL, @NewReportTreeNodeId output 	  	 
 	  	  	  	  	  	  	  	 End
 	  	  	  	  	  	 End
 	  	  	  	 End -- @PU_Id Is Not Null
 	  	  	 Goto BeginReportCursorLoop
 	  	 End 
Close @ReportCursor
Deallocate @ReportCursor
Drop Table #SQLFilter
