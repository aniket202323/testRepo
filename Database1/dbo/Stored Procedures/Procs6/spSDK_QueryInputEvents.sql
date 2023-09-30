CREATE PROCEDURE dbo.spSDK_QueryInputEvents
 	 @LineMask  	  	  	 nvarchar(50) = NULL,
 	 @UnitMask  	  	  	 nvarchar(50) = NULL,
 	 @InputMask 	  	  	 nvarchar(50) = NULL,
 	 @PositionMask 	  	 nvarchar(50) = NULL,
 	 @UserId 	  	  	  	 INT 	  	  	 = NULL
AS
SELECT 	 @LineMask = REPLACE(COALESCE(@LineMask, '*'), '*', '%')
SELECT 	 @LineMask = REPLACE(REPLACE(@LineMask, '?', '_'), '[', '[[]')
SELECT 	 @UnitMask = REPLACE(COALESCE(@UnitMask, '*'), '*', '%')
SELECT 	 @UnitMask = REPLACE(REPLACE(@UnitMask, '?', '_'), '[', '[[]')
SELECT 	 @InputMask = REPLACE(COALESCE(@InputMask, '*'), '*', '%')
SELECT 	 @InputMask = REPLACE(REPLACE(@InputMask, '?', '_'), '[', '[[]')
SELECT 	 @PositionMask = REPLACE(COALESCE(@PositionMask, '*'), '*', '%')
SELECT 	 @PositionMask = REPLACE(REPLACE(@PositionMask, '?', '_'), '[', '[[]')
--Mask For Name Has Been Specified
SELECT 	 InputId = pei.PEI_Id,
 	  	  	 DepartmentName = d.Dept_Desc,
 	  	  	 LineName = pl.PL_Desc, 
 	  	  	 UnitName = pu.PU_Desc, 
 	  	  	 InputName = pei.Input_Name, 
 	  	  	 Position = peip.PEIP_Desc, 
 	  	  	 SourceDepartmentName = srcd.Dept_Desc,
 	  	  	 SourceLineName = srcpl.PL_Desc, 
 	  	  	 SourceUnitName = srcpu.PU_Desc, 
 	  	  	 SourceEventName = e.Event_Num, 
 	  	  	 Timestamp = peie.TimeStamp, 
 	  	  	 DimensionX = peie.Dimension_X, 
 	  	  	 DimensionY = peie.Dimension_Y, 
 	  	  	 DimensionZ = peie.Dimension_Z, 
 	  	  	 DimensionA = peie.Dimension_A,
 	  	  	 Unloaded = peie.Unloaded,
 	  	  	 CommentId = peie.Comment_Id
 	 FROM 	  	  	 Departments d
 	 JOIN 	  	  	 Prod_Lines pl 	  	  	  	  	  	 ON  	 d.Dept_Id = pl.Dept_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pl.PL_Desc LIKE @LineMask
 	 JOIN 	  	  	 Prod_Units pu  	  	  	  	  	  	 ON  	 pl.PL_Id = pu.PL_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Desc LIKE @UnitMask
 	 JOIN 	  	  	 PrdExec_Inputs pei  	  	  	  	 ON  	 pu.PU_Id = pei.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pei.Input_Name LIKE @InputMask
 	 JOIN 	  	  	 PrdExec_Input_Positions peip  	 ON 	  	 peip.PEIP_Desc LIKE @PositionMask
 	 LEFT JOIN 	 PrdExec_Input_Event peie  	  	 ON  	 pei.PEI_Id = peie.PEI_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 peip.PEIP_Id = peie.PEIP_Id
 	 LEFT JOIN 	 Events e  	  	  	  	  	  	  	 ON 	  	 peie.Event_Id = e.Event_Id
 	 LEFT JOIN 	 Prod_Units srcpu  	  	  	  	  	 ON 	  	 e.PU_Id = srcpu.PU_Id
 	 LEFT JOIN 	 Prod_Lines srcpl  	  	  	  	  	 ON 	  	 srcpu.PL_Id = srcpl.PL_Id
 	 LEFT JOIN 	 Departments srcd 	  	  	  	  	 ON 	  	 srcpl.Dept_Id = srcd.Dept_Id
 	 LEFT JOIN 	 User_Security pls 	  	  	  	  	 ON 	  	 pl.Group_Id = pls.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pls.User_Id = @UserId
 	 LEFT JOIN 	 User_Security pus 	  	  	  	  	 ON 	  	 pu.Group_Id = pus.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pus.User_Id = @UserId 	 
 	 WHERE 	 COALESCE(pus.Access_Level, COALESCE(pls.Access_Level, 3)) >= 2
 	 ORDER BY pl.PL_Desc, pu.PU_Order, pei.Input_Order, peip.PEIP_Desc
