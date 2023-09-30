Create View [dbo].[Tests_NPT]
As
Select t.*,
 	 dbo.fnWA_IsNonProductiveTime(v.PU_ID, t.Result_ON, NULL) AS Is_Non_Productive
From [Tests] t
Join Variables v on v.var_Id = t.var_id
