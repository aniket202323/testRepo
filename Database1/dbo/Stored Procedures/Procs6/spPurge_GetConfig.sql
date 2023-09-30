CREATE PROCEDURE dbo.spPurge_GetConfig(@PurgeId int) AS
--get config details for a purge config
/* Get Globle Config */
SELECT  	 TableName,RetentionMonths,ElementPerBatch
 	 FROM PurgeConfig_Detail
 	 WHERE Purge_Id = @PurgeId AND PU_Id is Null and TableName is not null
/* Get Unit Config */
SELECT pl.PL_Id,pl.PL_Desc,pu.PU_Id,pu.PU_Desc,pd.RetentionMonths,pd.ElementPerBatch
 	 FROM PurgeConfig_Detail pd
 	 JOIN Prod_Units pu On pu.PU_Id = pd.PU_Id
 	 JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
 	 WHERE pd.Purge_Id = @PurgeId AND pd.PU_Id is Not Null AND pd.Var_Id IS Null and TableName is not null
/*Get Variable Configuration */
SELECT pl.PL_Id,pl.PL_Desc,pu.PU_Id,pu.PU_Desc,v.Var_Id,v.Var_Desc,pd.RetentionMonths,pd.ElementPerBatch
 	 FROM PurgeConfig_Detail pd
 	 JOIN Variables v on v.Var_Id = pd.Var_Id
 	 JOIN Prod_Units pu On pu.PU_Id = v.PU_Id
 	 JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
 	 WHERE pd.Purge_Id = @PurgeId AND pd.Var_Id is Not Null and TableName is not null
/*
select 
 	 TableName,
 	 RetentionMonths,
 	 ElementPerBatch,
 	 TimeSliceMinutes,
 	 PU_Id,
 	 Var_Id 
from
 	 PurgeConfig_Detail
where
 	 Purge_Id=@PurgeId
order by
 	 Purge_Detail_Id
*/
