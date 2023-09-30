Create View [dbo].[Production_Starts_NPT]
As
Select ps.*,
 	 dbo.[fnCmn_ModifyNPTimeRange](ps.PU_Id, ps.Start_Time, ps.End_Time, 1) Productive_Start_Time,
 	 dbo.[fnCmn_ModifyNPTimeRange](ps.PU_Id, ps.Start_Time, ps.End_Time, 0) Productive_End_Time,
 	 dbo.[fnCmn_SecondsNPTime](ps.PU_Id, ps.Start_Time, ps.End_Time) Non_Productive_Seconds
From Production_Starts ps
