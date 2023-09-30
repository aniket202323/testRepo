CREATE Procedure dbo.spSV_GetAlarms
@PP_Id int
AS
Select a.Alarm_Id, a.Alarm_Desc, pepa.AP_Id, a.Start_Time, a.Ack, u.Username as 'Ack_By', pep.Path_Code
From Alarms a
Join Production_Plan pp on pp.PP_Id = a.Key_Id
Join PrdExec_Paths pep on pep.Path_Id = pp.Path_Id
Join PrdExec_Path_Alarms pepa on pepa.Path_Id = pp.Path_Id and pepa.PEPAT_Id = a.SubType
Left Outer Join Users u on u.User_Id = a.Ack_By
Where (a.Key_Id = @PP_Id or a.Key_Id in (Select PP_Id from Production_Plan Where Parent_PP_Id = @PP_Id))
And a.Alarm_Type_Id = 3
Order By a.Start_Time
