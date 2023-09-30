CREATE PROCEDURE dbo.spSDK_QueryProductionUnits
 	 @LineMask 	  	 nvarchar(50) 	 = NULL,
 	 @UnitMask 	  	 nvarchar(50) 	 = NULL,
 	 @UserId 	  	  	 INT  	  	  	  	 = NULL,
 	 @DeptMask 	  	 nvarchar(50) 	 = NULL
AS
SET 	 @LineMask = REPLACE(COALESCE(@LineMask, '*'), '*', '%')
SET 	 @LineMask = REPLACE(REPLACE(@LineMask, '?', '_'), '[', '[[]')
SET 	 @UnitMask = REPLACE(COALESCE(@UnitMask, '*'), '*', '%')
SET 	 @UnitMask = REPLACE(REPLACE(@UnitMask, '?', '_'), '[', '[[]')
SET 	 @DeptMask = REPLACE(COALESCE(@DeptMask, '*'), '*', '%')
SET 	 @DeptMask = REPLACE(REPLACE(@DeptMask, '?', '_'), '[', '[[]')
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
 	  	  	  	  	  	  	  	  	  	  	 AND 	 d.Dept_Desc LIKE @DeptMask
 	  	  	  	  	  	  	  	  	  	  	 AND 	 pl.PL_Desc LIKE @LineMask
 	  	  	  	  	  	  	  	  	  	  	 AND 	 pl.PL_Id > 0 
 	 INNER 	 JOIN 	 Prod_Units pu 	  	 ON 	  	 pl.pl_id = pu.pl_id
 	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Desc LIKE @UnitMask
 	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Id > 0 
 	 LEFT 	 JOIN 	 Prod_Units pu2 	  	 ON 	  	 pu2.PU_Id = pu.Master_Unit
 	 LEFT 	 JOIN 	 User_Security pls 	 ON 	  	 pl.Group_Id = pls.Group_Id AND
 	  	  	  	  	  	  	  	  	  	  	  	  	 pls.User_Id = @UserId
 	 LEFT 	 JOIN 	 User_Security pus 	 ON 	  	 pu.Group_Id = pus.Group_Id AND
 	  	  	  	  	  	  	  	  	  	  	  	  	 pus.User_Id = @UserId 	 
 	 AND 	 COALESCE(pus.Access_Level, COALESCE(pls.Access_Level, 3)) >= 2
 	 ORDER BY pl.PL_Desc, pu.PU_Order
