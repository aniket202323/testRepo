CREATE PROCEDURE dbo.spRS_GetReportQue
AS
select RQ.*, RD.File_Name, RD.Report_Name, RD.Class, RS.Interval, RS.Last_Run_Time, RS.Status, RS.Last_Result,RDP.Value 'Owner'
  From Report_Que RQ
  left join Report_Schedule RS on RS.Schedule_Id = RQ.Schedule_Id
  left join Report_Definitions RD on RS.Report_Id = RD.Report_Id
    Left Join Report_Types RT on RD.Report_Type_Id = RT.Report_Type_Id
    Left Join Report_Type_Parameters RTP on RT.Report_Type_Id = RTP.Report_Type_Id  -- this gives me RTP_Id
    Left Join Report_Definition_Parameters RDP on RDP.RTP_Id = RTP.RTP_Id and RS.Report_Id = RDP.Report_Id
    Where RTP.RP_Id = 28
  Order By RQ.Que_Id
