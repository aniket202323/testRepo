Create View [dbo].[Waste_Event_Details_NPT]
As
Select w.*,
 	 dbo.fnWA_IsNonProductiveTime(2, W.[TimeStamp], null) Is_Non_Productive
From Waste_Event_Details w
