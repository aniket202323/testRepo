CREATE PROCEDURE dbo.spSDK_GetProductionUnitById
 	 @PUId 	  	  	  	  	 INT
AS
--Neither Line Name or Unit Mask Have Been Specified
SELECT 	 ProductionUnitId 	  	 = pu.PU_Id,
 	  	  	 DeptName 	  	  	  	  	 = d.Dept_Desc,
 	  	  	 UnitName 	  	  	  	  	 = pu.pu_desc,
 	  	  	 LineName 	  	  	  	  	 = pl.pl_desc, 
 	  	  	 MasterUnitName 	  	  	 = 	 CASE 
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN pu.Master_Unit IS NULL THEN pu.pu_desc 
 	  	  	  	  	  	  	  	  	  	  	  	 ELSE pu2.PU_Desc
 	  	  	  	  	  	  	  	  	  	  	 END,
 	  	  	 IsMasterUnit 	  	  	 = 	 CASE 
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN pu.Master_Unit IS NULL THEN 1 
 	  	  	  	  	  	  	  	  	  	  	  	 ELSE 0 
 	  	  	  	  	  	  	  	  	  	  	 END,
 	  	  	 HasProductionEvents 	 = (SELECT COUNT(EC_Id) FROM Event_Configuration WHERE PU_Id = pu.PU_Id AND ET_Id = 1),
 	  	  	 ExtendedInfo 	  	  	 = pu.Extended_Info,
 	  	  	 CommentId 	  	  	  	 = pu.Comment_Id
 	 FROM 	  	  	 Departments d
 	 INNER 	 JOIN 	 Prod_Lines pl 	  	 ON 	  	 d.Dept_Id = pl.Dept_Id
 	  	  	  	  	  	  	  	  	  	  	 AND 	 pl.PL_Id > 0 
 	 INNER 	 JOIN 	 Prod_Units pu 	  	 ON 	  	 pl.pl_id = pu.pl_id
 	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Id > 0 
 	 LEFT 	 JOIN 	 Prod_Units pu2 	  	 ON 	  	 pu2.PU_Id = pu.Master_Unit
 	 WHERE pu.PU_Id = @PUId
