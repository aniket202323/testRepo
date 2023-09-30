CREATE PROCEDURE dbo.spRS_GetReportDefs
AS
Declare @ComxClient varchar(25)
Select @ComxClient = username from Users Where User_Id = 1
  select  RD.*, RT.Class_Name, 
 	 Case When U.UserName Is Null Then @ComxClient Else U.username  End 'Owner'
  from report_definitions RD
  Join Report_Types RT on RD.Report_Type_Id = RT.Report_Type_Id
  Left Join Users U on RD.OwnerId = U.User_Id
  Where Class in (2,3)
  Order By RD.Report_Name
/*
  select  RD.*, RT.Class_Name, RDP.Value 'Owner'
  from report_definitions RD
  Join Report_Types RT on RD.Report_Type_Id = RT.Report_Type_Id
  Join Report_Definition_Parameters RDP on RD.Report_Id = RDP.Report_Id
  Join Report_Type_Parameters RTP on RDP.RTP_Id = RTP.RTP_ID and RTP.RP_Id = 28
  Where Class in (2,3)
*/
----------------------------------------------------
--  0 = No Class (Will Be Deleted)
--  1 = Web Request (Will become a 0 after it runs)
--  2 = Scheduled
--  3 = Saved Definition
--  4 = COA Report (Should not be displayed)
----------------------------------------------------
