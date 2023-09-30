Create Procedure dbo.spSDK_QueryPathSourceUnits
 	 @LineMask  	  	  	 nvarchar(50) 	 = NULL,
 	 @UnitMask  	  	  	 nvarchar(50) 	 = NULL,
 	 @InputMask 	  	  	 nvarchar(50) 	 = NULL,
 	 @SourceUnitMask 	 nvarchar(50) 	 = NULL,
 	 @UserId 	  	  	  	 INT 	  	  	 = NULL
AS
SELECT 	 @LineMask = REPLACE(COALESCE(@LineMask, '*'), '*', '%')
SELECT 	 @LineMask = REPLACE(REPLACE(@LineMask, '?', '_'), '[', '[[]')
SELECT 	 @UnitMask = REPLACE(COALESCE(@UnitMask, '*'), '*', '%')
SELECT 	 @UnitMask = REPLACE(REPLACE(@UnitMask, '?', '_'), '[', '[[]')
SELECT 	 @InputMask = REPLACE(COALESCE(@InputMask, '*'), '*', '%')
SELECT 	 @InputMask = REPLACE(REPLACE(@InputMask, '?', '_'), '[', '[[]')
SELECT 	 @SourceUnitMask = REPLACE(COALESCE(@SourceUnitMask, '*'), '*', '%')
SELECT 	 @SourceUnitMask = REPLACE(REPLACE(@SourceUnitMask, '?', '_'), '[', '[[]')
--Mask For Name Has Been Specified
SELECT 	 DISTINCT 
 	  	  	 ProductionUnitId = pu.PU_Id,
 	  	  	 DeptName = d.Dept_Desc,
 	  	  	 UnitName = pu.pu_desc,
 	  	  	 LineName = pl.pl_desc, 
 	  	  	 MasterUnitName = pu.PU_Desc,
 	  	  	 IsMasterUnit = 	 1,
 	  	  	 HasProductionEvents = (SELECT COUNT(EC_Id) FROM Event_Configuration WHERE PU_Id = pu.pu_id and et_id = 1),
 	  	  	 CommentId = pu.Comment_Id,
 	  	  	 ExtendedInfo = pu.Extended_Info
 	 FROM 	  	  	 Departments id
 	 JOIN 	  	  	 Prod_Lines ipl 	  	  	  	  	 ON 	  	 id.Dept_Id = ipl.Dept_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 ipl.PL_Desc LIKE @LineMask
 	 JOIN 	  	  	 Prod_Units ipu  	  	  	  	 ON 	  	 ipl.PL_Id = ipu.PL_Id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 ipu.PU_Desc LIKE @UnitMask
 	 LEFT JOIN 	 User_Security ipls 	  	  	 ON 	  	 ipl.Group_Id = ipls.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 ipls.User_Id = @UserId
 	 LEFT JOIN 	 User_Security ipus 	  	  	 ON 	  	 ipu.Group_Id = ipus.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 ipus.User_Id = @UserId
 	 JOIN 	  	  	 PrdExec_Inputs pei  	  	  	 ON 	  	 ipu.PU_Id = pei.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	   	 AND 	 pei.Input_Name LIKE @InputMask
 	 JOIN 	  	  	 PrdExec_Input_Sources peis 	 ON 	  	 pei.PEI_Id = peis.PEI_Id
 	 JOIN 	  	  	 Prod_Units pu  	  	  	  	  	 ON 	  	 pu.PU_Id = peis.PU_Id
 	 JOIN 	  	  	 Prod_Lines pl  	  	  	  	  	 ON 	  	 pl.PL_Id = pu.pL_Id
 	 JOIN 	  	  	 Departments d 	  	  	  	  	 ON 	  	 pl.Dept_Id = d.Dept_Id
 	 LEFT JOIN 	 User_Security pls 	  	  	  	 ON 	  	 pl.Group_Id = pls.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pls.User_Id = @UserId
 	 LEFT JOIN 	 User_Security pus 	  	  	  	 ON  	 pu.Group_Id = pus.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pus.User_Id = @UserId
 	 WHERE 	 pu.PU_Desc LIKE @SourceUnitMask
 	 AND 	 COALESCE(pus.Access_Level, COALESCE(pls.Access_Level, 3)) >= 2
 	 AND 	 COALESCE(ipus.Access_Level, COALESCE(ipls.Access_Level, 3)) >= 2
