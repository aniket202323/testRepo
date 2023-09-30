CREATE PROCEDURE dbo.spSDK_QueryPathDestinationUnits
 	 @SrcLineMask  	  	 nvarchar(50) 	 = NULL,
 	 @SrcUnitMask  	  	 nvarchar(50) 	 = NULL,
 	 @DestLineMask 	  	 nvarchar(50) 	 = NULL,
 	 @DestUnitMask 	  	 nvarchar(50) 	 = NULL,
 	 @UserId 	  	  	  	 INT 	  	  	  	 = NULL
AS
SELECT 	 @SrcLineMask = REPLACE(COALESCE(@SrcLineMask, '*'), '*', '%')
SELECT 	 @SrcLineMask = REPLACE(REPLACE(@SrcLineMask, '?', '_'), '[', '[[]')
SELECT 	 @SrcUnitMask = REPLACE(COALESCE(@SrcUnitMask, '*'), '*', '%')
SELECT 	 @SrcUnitMask = REPLACE(REPLACE(@SrcUnitMask, '?', '_'), '[', '[[]')
SELECT 	 @DestLineMask = REPLACE(COALESCE(@DestLineMask, '*'), '*', '%')
SELECT 	 @DestLineMask = REPLACE(REPLACE(@DestLineMask, '?', '_'), '[', '[[]')
SELECT 	 @DestUnitMask = REPLACE(COALESCE(@DestUnitMask, '*'), '*', '%')
SELECT 	 @DestUnitMask = REPLACE(REPLACE(@DestUnitMask, '?', '_'), '[', '[[]')
--Mask For Name Has Been Specified
SELECT 	 DISTINCT 
 	  	  	 ProductionUnitId = dpu.PU_Id,
 	  	  	 DeptName = dd.Dept_Desc,
 	  	  	 UnitName = dpu.pu_desc,
 	  	  	 LineName = dpl.pl_desc, 
 	  	  	 MasterUnitName = dpu.PU_Desc,
 	  	  	 IsMasterUnit = 	 1,
 	  	  	 HasProductionEvents = (SELECT COUNT(EC_Id) FROM Event_Configuration WHERE PU_Id = dpu.pu_id and et_id = 1),
 	  	  	 ExtendedInfo = dpu.Extended_Info,
 	  	  	 CommentId 	 = dpu.Comment_Id,
 	  	  	 PU_Order = COALESCE(dpu.PU_Order,99999999)
 	 FROM 	  	  	 Departments sd
 	 JOIN 	  	  	 Prod_Lines spl 	  	  	  	  	 ON  	 sd.Dept_Id = spl.Dept_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 spl.PL_Desc LIKE @SrcLineMask 
 	 JOIN 	  	  	 Prod_Units spu  	  	  	  	 ON 	  	 spl.PL_Id = spu.PL_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 spu.PU_Id > 0
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 spu.PU_Desc LIKE @SrcUnitMask 
 	 LEFT JOIN 	 User_Security spls 	  	  	 ON  	 spl.Group_Id = spls.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 spls.User_Id = @UserId
 	 LEFT JOIN 	 User_Security spus 	  	  	 ON  	 spu.Group_Id = spus.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 spus.User_Id = @UserId 	 
 	 JOIN 	  	  	 PrdExec_Input_Sources peis 	 ON  	 spu.PU_Id = peis.PU_Id
 	 JOIN 	  	  	 PrdExec_Inputs pei 	  	  	 ON  	 peis.PEI_Id = pei.PEI_Id
 	 JOIN 	  	  	 Prod_Units dpu 	  	  	  	  	 ON  	 pei.PU_Id = dpu.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 dpu.PU_Desc LIKE @DestUnitMask
 	 JOIN 	  	  	 Prod_Lines dpl 	  	  	  	  	 ON  	 dpu.PL_Id = dpl.PL_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 dpl.PL_Desc LIKE @DestLineMask
 	 JOIN 	  	  	 Departments dd 	  	  	  	  	 ON  	 dpl.Dept_Id = dd.Dept_Id
 	 LEFT JOIN 	 User_Security dpls 	  	  	 ON  	 dpl.Group_Id = dpls.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 dpls.User_Id = @UserId
 	 LEFT JOIN 	 User_Security dpus 	  	  	 ON  	 dpu.Group_Id = dpus.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 dpus.User_Id = @UserId 	 
 	 WHERE 	 COALESCE(dpus.Access_Level, COALESCE(dpls.Access_Level, 3)) >= 2
 	 AND 	 COALESCE(spus.Access_Level, COALESCE(spls.Access_Level, 3)) >= 2
 	 ORDER BY dd.Dept_Desc ASC, dpl.PL_Desc ASC, COALESCE(dpu.PU_Order,99999999) ASC, dpu.PU_Desc ASC
SET QUOTED_IDENTIFIER  OFF    SET ANSI_NULLS  ON 
