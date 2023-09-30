Create View [dbo].[Timed_Event_Details_NPT]
As
Select d.*,
 	 dbo.[fnCmn_ModifyNPTimeRange](d.PU_Id, d.Start_Time, d.End_Time, 1) Productive_Start_Time,
 	 dbo.[fnCmn_ModifyNPTimeRange](d.PU_Id, d.Start_Time, d.End_Time, 0) Productive_End_Time,
 	 dbo.[fnCmn_SecondsNPTime](d.PU_Id, d.Start_Time, d.End_Time) Non_Productive_Seconds
From Timed_Event_Details d
