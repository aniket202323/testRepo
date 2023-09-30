Create View [dbo].[Sheet_Columns_NPT]
As
Select sc.*,
 	 dbo.fnWA_IsNonProductiveTime(s.Master_Unit, sc.Result_ON, NULL) AS Is_Non_Productive
From Sheet_Columns sc
Join Sheets s on s.Sheet_Id = sc.Sheet_Id
