Create View [dbo].[User_Defined_Events_NPT]
As
Select ude.*,
 	 dbo.[fnCmn_ModifyNPTimeRange](ude.PU_Id, ude.Start_Time, ude.End_Time, 1) Productive_Start_Time,
 	 dbo.[fnCmn_ModifyNPTimeRange](ude.PU_Id, ude.Start_Time, ude.End_Time, 0) Productive_End_Time,
 	 dbo.[fnCmn_SecondsNPTime](ude.PU_Id, ude.Start_Time, ude.End_Time) Non_Productive_Seconds
From [User_Defined_Events] ude
