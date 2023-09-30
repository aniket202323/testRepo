Create View [dbo].[Events_NPT]
As
Select e.*,
 	 dbo.[fnCmn_ModifyNPTimeRange](e.PU_Id, e.Actual_Start_Time, e.[TimeStamp], 1) Productive_Start_Time,
 	 dbo.[fnCmn_ModifyNPTimeRange](e.PU_Id, e.Actual_Start_Time, e.[TimeStamp], 0) Productive_End_Time,
 	 dbo.[fnCmn_SecondsNPTime](e.PU_Id, e.Actual_Start_Time, e.[TimeStamp]) Non_Productive_Seconds
From [Events_With_StartTime] e
