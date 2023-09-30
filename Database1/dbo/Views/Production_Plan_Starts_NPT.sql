Create View [dbo].[Production_Plan_Starts_NPT]
As
Select pps.*,
 	 dbo.[fnCmn_ModifyNPTimeRange](pps.PU_Id, pps.Start_Time, pps.End_Time, 1) Productive_Start_Time,
 	 dbo.[fnCmn_ModifyNPTimeRange](pps.PU_Id, pps.Start_Time, pps.End_Time, 0) Productive_End_Time,
 	 dbo.[fnCmn_SecondsNPTime](pps.PU_Id, pps.Start_Time, pps.End_Time) Non_Productive_Seconds
From [Production_Plan_Starts] pps
