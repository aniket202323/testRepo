CREATE PROCEDURE dbo.spSDK_QueryPathInputs
 	 @LineMask  	  	  	 nvarchar(50) 	 = NULL,
 	 @UnitMask  	  	  	 nvarchar(50) 	 = NULL,
 	 @InputMask 	  	  	 nvarchar(50) 	 = NULL,
 	 @UserId 	  	  	  	 INT 	  	  	  	 = NULL
AS
SELECT 	 @LineMask = REPLACE(COALESCE(@LineMask, '*'), '*', '%')
SELECT 	 @LineMask = REPLACE(REPLACE(@LineMask, '?', '_'), '[', '[[]')
SELECT 	 @UnitMask = REPLACE(COALESCE(@UnitMask, '*'), '*', '%')
SELECT 	 @UnitMask = REPLACE(REPLACE(@UnitMask, '?', '_'), '[', '[[]')
SELECT 	 @InputMask = REPLACE(COALESCE(@InputMask, '*'), '*', '%')
SELECT 	 @InputMask = REPLACE(REPLACE(@InputMask, '?', '_'), '[', '[[]')
SELECT 	 PathInputId = pei.PEI_Id, 
 	  	  	 DepartmentName = d.Dept_Desc,
 	  	  	 LineName = pl.PL_Desc, 
 	  	  	 UnitName = pu.PU_Desc, 
 	  	  	 InputName = pei.Input_Name, 
 	  	  	 EventSubType = es.Event_Subtype_Desc
 	 FROM 	  	  	 Departments d
 	 JOIN 	  	  	 Prod_Lines pl 	  	  	 ON 	  	 d.Dept_Id = pl.Dept_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pl.PL_Desc LIKE @LineMask
 	 JOIN 	  	  	 Prod_Units pu  	  	  	 ON 	  	 pl.PL_Id = pu.PL_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Desc LIKE @UnitMask 
 	 JOIN 	  	  	 PrdExec_Inputs pei 	 ON 	  	 pu.PU_Id = pei.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pei.Input_Name LIKE @InputMask 
 	 JOIN 	  	  	 Event_SubTypes es 	  	 ON  	 pei.Event_Subtype_Id = es.Event_SubType_Id
 	 LEFT JOIN 	 User_Security pls 	  	 ON  	 pl.Group_Id = pls.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pls.User_Id = @UserId
 	 LEFT JOIN 	 User_Security pus 	  	 ON  	 pu.Group_Id = pus.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pus.User_Id = @UserId 	 
 	 WHERE 	 COALESCE(pus.Access_Level, COALESCE(pls.Access_Level, 3)) >= 2
 	 ORDER BY d.Dept_Desc ASC, pl.PL_Desc, COALESCE(pu.PU_Order, 99999999), pei.Input_Order, pei.Input_Name
