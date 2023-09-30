-----------------------------------------------------------------
-- This stored procedure is used by the following applications:
-- ProficyRPTAdmin
-- ProficyRPTEngine
-- Edit the master document in VSS project: ProficyRPTAdmin
-----------------------------------------------------------------
CREATE PROCEDURE dbo.spRS_GetReportSchedule
@Sched_Id int = null,
@InTimezone varchar(200) = ''
AS
--*******************************************/
DECLARE @Schedule_Table TABLE
(
    Schedule_Id int,
    Report_Id int,
    Start_Date_Time DateTime,
    Interval int,
    Next_Run_Time DateTime,
    Last_Run_Time DateTime,
    Status int,
    Last_Result int,
    Run_Attempts int,
    Computer_Name varchar(20),
    Process_Id int,
    Error_Code int,
    Error_String varchar(255),
    Report_Name varchar(255),
    File_Name varchar(255),
    Class int,
    Description varchar(255),
    Template_Path varchar(255),
    Class_Name varchar(255),
    Owner varchar(255),
    sClass varchar(50),
    sStatus varchar(50),
    sLast_Result varchar(50),
    sError_Code varchar(50),
 	 Schedule_Desc varchar(255)
)
insert into @Schedule_Table(
   Schedule_Id,
    Report_Id ,
    Start_Date_Time,
    Interval,
    Next_Run_Time ,
    Last_Run_Time,
    Status,
    Last_Result ,
    Run_Attempts ,
    Computer_Name ,
    Process_Id ,
    Error_Code ,
    Error_String ,
    Report_Name,
    File_Name ,
    Class ,
    Description ,
    Template_Path ,
    Class_Name ,
    Owner ,
    sClass ,
    sStatus ,
    sLast_Result ,
    sError_Code,
 	 Schedule_Desc 
)
select 
 	 rs.Schedule_Id, 
 	 rs.Report_Id, 
 	 dbo.fnServer_CmnConvertFromDBTime(rs.Start_Date_Time,@InTimeZone), 
 	 rs.Interval, 
 	 dbo.fnServer_CmnConvertFromDBTime(rs.Next_Run_Time,@InTimezone), 
 	 dbo.fnServer_CmnConvertFromDBTime(rs.Last_Run_Time,@InTimezone), 
 	 rs.Status, 
 	 rs.Last_Result, 
 	 rs.Run_Attempts, 
 	 rs.Computer_Name, 
 	 rs.Process_Id, 
 	 rs.Error_Code, 
 	 rs.Error_String,
 	 rd.Report_Name,
 	 rd.File_Name,
 	 rd.Class,
 	 rt.Description, 
 	 rt.Template_Path, 
 	 rt.Class_Name,
 	 rdp1.Value [Owner],
 	 rec1.Code_Desc [sClass],
 	 rec2.Code_Desc [sStatus],
 	 rec3.Code_Desc [sLast_Result],
 	 rec4.Code_Desc [sError_Code],
 	 dbo.fnRS_GetScheduleReportDesc(rs.Interval,rs.Daily,rs.Monthly,dbo.fnServer_CmnConvertFromDBTime(rs.Start_Date_Time,@InTimeZone)) -- Ramesh here: Damn it!!! Had to do this way to send the desc in correct time zone
 	 --rs.Description
from report_schedule rs
 	 Join Report_Definitions RD on RD.Report_Id = rs.Report_Id
 	 Join Report_Types RT on RT.Report_Type_Id = rd.Report_Type_Id
 	 Left Outer Join Report_Type_Parameters rtp1 on rtp1.Report_Type_Id = rd.report_type_Id and rtp1.rp_Id in (28) -- Owner
 	 Left Outer Join Report_Type_Parameters rtp2 on rtp2.Report_Type_Id = rd.report_type_Id and rtp2.rp_Id in (29) --,Class
 	 Left Outer Join Report_Definition_Parameters rdp1 on rdp1.Report_Id = rd.report_Id and rdp1.RTP_Id = rtp1.RTP_Id
 	 Left Outer Join Report_Definition_Parameters rdp2 on rdp2.Report_Id = rd.report_Id and rdp2.RTP_Id = rtp2.RTP_Id
 	 Left Join Return_Error_Codes rec1 on rec1.App_Id = 11 and rec1.Group_Id = 2 and rec1.Code_Value = rd.Class
 	 Left Join Return_Error_Codes rec2 on rec2.App_Id = 11 and rec2.Group_Id = 1 and rec2.Code_Value = rs.Status
 	 Left Join Return_Error_Codes rec3 on rec3.App_Id = 11 and rec3.Group_Id = 3 and rec3.Code_Value = rs.Last_Result
 	 Left Join Return_Error_Codes rec4 on rec4.App_Id = 11 and rec4.Group_Id = 5 and rec4.Code_Value = rs.Error_Code
where @Sched_Id Is NULL or rs.Schedule_Id = @Sched_Id
select * from @Schedule_Table order by Schedule_Id
