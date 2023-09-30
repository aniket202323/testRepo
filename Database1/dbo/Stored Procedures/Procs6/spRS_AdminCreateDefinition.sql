CREATE PROCEDURE dbo.spRS_AdminCreateDefinition
@ReportTypeId int,
@ReportName varchar(255) = NULL,
@ReportParameters varchar(7000) = NULL,
@ReportId int output
 AS
--------------------------------------------------------
--------------------------------------------------------
/*
Create A new Report Definition based on type
Accept all the default values from the report type
Declare @ReportTypeId int
Select @ReportTypeId  = 16
select * from report_definitions
for testing:
Declare @o int
--exec spRS_AdminCreateDefinition 16, 'First Run 20040616162403', @o output
exec spRS_AdminCreateDefinition 16, Null, @o output
select @o
Declare @ReportId int
Exec spRS_AdminCreateDefinition 16, 'First Run-Today (German - P1 Machine1)', @ReportId output
select @ReportId
select * from report_definitions
*/
--------------------------------------
-- Local Vars
--------------------------------------
Declare @NewReportId int
Declare @NativeExt varchar(20)
Declare @ImageExt varchar(20)
Declare @OwnerId int
Declare @SecurityGroupId int
Declare @Description varchar(255)
Declare @FileName varchar(255)
Declare @TS varchar(50)
-------------------------------------------------
-- Check for an existing definition of this type
-------------------------------------------------
If @ReportName Is Not Null
 	 Begin
 	  	 Select @ReportId = Report_Id From Report_Definitions Where Report_Name = @ReportName and Report_Type_Id = @ReportTypeId
 	  	 If @ReportId Is not Null
 	  	  	 Begin
 	  	  	  	 Print 'Report Definition: (' + @ReportName + ') already exists [' + convert(varchar(10), @ReportId) + ']'
 	  	  	  	 Select @NewReportId = @ReportId
 	  	  	  	 GoTo UpdateParameters
 	  	  	  	 --return 0
 	  	  	 End
 	 End
--------------------------------------
-- Get initial report type values
--------------------------------------
Select @Description = Description, @NativeExt = Native_Ext, @ImageExt = Image_Ext, @OwnerId = OwnerId, @SecurityGroupId = Security_Group_Id From Report_Types Where Report_Type_Id = @ReportTypeID
--------------------------------------
-- Get File and Report Names
--------------------------------------
Select @TS = Convert(VarChar(50), GetDate(), 120)
Select @TS = Replace(@TS, ' ', '')
Select @TS = Replace(@TS, '-', '')
Select @TS = Replace(@TS, ':', '')
Select @TS = Replace(@TS, '.', '')
If @ReportName Is Null
 	 Begin
 	  	 -- Assign It A Random Name
 	  	 Select @ReportName = @Description + ' ' + @TS
 	 End
Select @FileName = Replace(@ReportName, ' ', '')-- Remove All Spaces
--------------------------------------
-- Create Definition
--------------------------------------
Print 'spRS_AdminCreateDefinition::CREATING NEW DEFINITION'
INSERT INTO REPORT_DEFINITIONS(Class,  Priority,  Report_Type_Id,  Report_Name,  File_Name,   AutoRefresh, TimeStamp, Image_Ext, Native_Ext, OwnerId, Security_Group_Id)
 	  	  	  	  	    VALUES(3, 2, @ReportTypeId, @ReportName, @FileName, 0, GetDate(), @ImageExt, @NativeExt, @OwnerId, @SecurityGroupId)
SELECT @NewReportId = Scope_Identity()
--------------------------------------
-- Add Parameters
--------------------------------------
Insert Into Report_Definition_Parameters(rtp_Id, report_Id, value)
Select rtp_Id, @NewReportId, Default_Value From  Report_Type_Parameters where report_type_Id = @ReportTypeId
exec spRS_AddReportDefParam @NewReportId, 'FileName', @FileName
exec spRS_AddReportDefParam @NewReportId, 'ReportName', @ReportName
UpdateParameters:
--------------------------------------
-- Update Parameters
--------------------------------------
Print 'spRS_AdminCreateDefinition::UPDATING PARAMETERS'
Create Table #MyXMLRS(name varchar(255), value varchar(255))
Insert Into #MyXMLRS Exec spRS_AdminXMLToRS @ReportParameters
Declare @Name VarChar(255)
Declare @Value VarChar(255)
Declare @MyXMLRSCursor Cursor
Set  @MyXMLRSCursor = Cursor For
 	 select Name, Value From #MyXMLRS 
Open @MyXMLRSCursor
BeginLoop:
 	 Fetch Next From @MyXMLRSCursor Into @Name, @Value
 	 If (@@Fetch_Status = 0)
 	  	 Begin 
 	  	  	 exec spRS_AddReportDefParam @NewReportId, @Name, @Value
 	  	  	 Goto BeginLoop
 	  	 End
Close @MyXMLRSCursor
Deallocate @MyXMLRSCursor
drop table #MyXMLRS
Select @ReportId = @NewReportId
