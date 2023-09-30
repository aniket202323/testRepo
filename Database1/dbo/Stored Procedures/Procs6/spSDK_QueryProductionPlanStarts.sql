CREATE PROCEDURE dbo.spSDK_QueryProductionPlanStarts
 	 @ProdLine 	  	  	  	 nvarchar(50) 	  	 = NULL,
 	 @ProdUnit 	  	  	  	 nvarchar(50) 	  	 = NULL,
 	 @StartTime 	  	  	 DATETIME 	  	  	 = NULL,
 	 @EndTime 	  	  	  	 DATETIME 	  	  	 = NULL,
 	 @UserId 	  	  	  	 INT 	  	  	  	 = NULL
AS
IF @EndTime IS NULL
BEGIN
 	 IF @StartTime IS NULL
 	 BEGIN
 	  	 SELECT 	 @EndTime = dbo.fnServer_CmnGetDate(getUTCdate())
 	 END ELSE
 	 BEGIN
 	  	 SELECT 	 @EndTime = DATEADD(DAY, 1, @StartTime)
 	 END
END
IF @StartTime IS NULL
BEGIN
 	 SELECT 	 @StartTime = DATEADD(DAY, -1, @EndTime)
END
IF 	 @ProdLine IS NOT NULL
BEGIN
 	 SELECT 	 @ProdLine = 	 REPLACE(COALESCE(@ProdLine, '*'), '*', '%')
 	 SELECT 	 @ProdLine = 	 REPLACE(REPLACE(@ProdLine, '?', '_'), '[', '[[]')
END
IF @ProdUnit IS NULL
BEGIN
 	 SELECT 	 @ProdUnit = 	 REPLACE(COALESCE(@ProdUnit, '*'), '*', '%')
 	 SELECT 	 @ProdUnit = 	 REPLACE(REPLACE(@ProdUnit, '?', '_'), '[', '[[]')
END
DECLARE @ProductionPlanStarts Table 
(PPStartId int, DepartmentName nvarchar(50), PathCode nvarchar(50), LineName nvarchar(50), UnitName nvarchar(50), 
 ProcessOrder nvarchar(50),StartTime datetime, EndTime datetime, CommentId int,PatternCode nvarchar(25))
 	  	 Insert Into @ProductionPlanStarts
 	  	  	 (PPStartId, DepartmentName, PathCode, LineName, UnitName, ProcessOrder, 
 	  	  	 StartTime, EndTime,  CommentId,PatternCode)
 	  	  	 SELECT  	 PPStartId = pps.PP_Start_Id, 
 	  	  	  	  	 DepartmentName = d.Dept_Desc, 
 	  	  	  	  	 PathCode = pep.Path_Code,
 	  	  	  	  	 LineName = pl.PL_Desc, 
 	  	  	  	  	 UnitName = pu.PU_Desc, 
 	  	  	  	  	 ProcessOrder = pp.Process_Order, 
 	  	  	  	  	 StartTime = pps.Start_Time, 
 	  	  	  	  	 EndTime = pps.End_Time, 
 	  	  	  	  	 CommentId = pps.Comment_Id,
  	  	  	  	  	 PatternCode = ppsu.Pattern_Code
 	  	  	  	 FROM 	 Production_Plan_Starts pps
 	  	  	  	 JOIN Prod_Units pu 	 ON pu.PU_Id = pps.PU_Id
 	  	  	  	 JOIN 	 Prod_Lines pl 	 ON pl.PL_Id = pu.PL_Id
 	  	  	  	 JOIN 	 Departments d 	 ON d.Dept_Id = pl.Dept_Id
 	  	  	  	 JOIN 	 Production_Plan pp 	 ON pp.PP_Id = pps.PP_Id
 	  	  	  	 Left Join PrdExec_Paths pep on pep.Path_Id = pp.Path_Id 	 
 	  	  	  	 Left Join Production_Setup ppsu on ppsu.PP_Setup_Id = pps.PP_Setup_Id
 	  	  	  	 LEFT JOIN 	 User_Security pls ON pl.Group_Id = pls.Group_Id AND pls.User_Id = @UserId
 	  	  	  	 LEFT JOIN 	 User_Security pus ON pu.Group_Id = pus.Group_Id AND pus.User_Id = @UserId
 	  	  	  	 WHERE (pps.Start_Time > @StartTime AND (pps.End_Time < @EndTime or pps.End_Time is null))
 	  	  	  	 AND   pu.PU_Desc LIKE @ProdUnit and pl.PL_Desc LIKE @ProdLine
 	  	  	  	 AND 	 COALESCE(pus.Access_Level, COALESCE(pls.Access_Level, 3)) >= 2
SELECT PPStartId, DepartmentName, PathCode, LineName, UnitName, ProcessOrder, StartTime, EndTime,  CommentId,PatternCode
 FROM @ProductionPlanStarts
ORDER BY StartTime
