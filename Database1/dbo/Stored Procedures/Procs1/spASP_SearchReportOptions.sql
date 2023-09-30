CREATE procedure [dbo].[spASP_SearchReportOptions]
--declare 
@SearchString nvarchar(255),
@SourceType Int,
@Version nvarchar(10),
@AllReportDefinitions Bit = 1  --When 0, only report definitions of class 2 or 3 will be returned
AS
Declare @RSRoot nVarChar(1000)
Select @RSRoot = Coalesce(Value, 'PAReporting')
From Site_Parameters
Where parm_id = 56
Select rd.Report_Id 'Id', rd.Report_Name 'Name', rd.[Description],
 	 u.Username SavedBy, rd.OwnerId SavedById, rd.[Timestamp] SavedOn,
 	 Case When Xml_Data Is Null Then '/' + @RSRoot + '/Viewer/RSFrontDoor.asp?ReportId=' + Cast(rd.Report_Id As nvarchar(10)) Else Null End 'ViewUrl',
 	 Case When Xml_Data Is Null Then '/' + @RSRoot + '/Viewer/RSFrontDoor.asp?SaveOption=7&ReportId=' + Cast(rd.Report_Id As nvarchar(10)) Else Null End 'EditUrl'
 	 From Report_Definitions rd
 	 Join Users u On rd.OwnerId = u.[User_Id]
 	 Where (@SourceType Is Null Or rd.Report_Type_Id = @SourceType)
 	 And (@SearchString Is Null Or rd.Report_Name Like '%' + @SearchString + '%')
 	 And (@Version Is Null Or rd.Xml_Version = @Version Or rd.Xml_Data Is Null)
 	 And (@AllReportDefinitions = 1 Or rd.Class = 2 Or rd.Class = 3)
