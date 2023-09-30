Create View [dbo].[Alarms_NPT]
As
Select a.*,
 	 dbo.[fnCmn_ModifyNPTimeRange](a.Source_PU_Id, a.start_time, a.End_Time, 1) Productive_Start_Time,
 	 dbo.[fnCmn_ModifyNPTimeRange](a.Source_PU_Id, a.start_time, a.End_Time, 0) Productive_End_Time,
 	 dbo.[fnCmn_SecondsNPTime](a.Source_PU_Id, a.start_time, a.End_Time) Non_Productive_Seconds
From [Alarms] a
