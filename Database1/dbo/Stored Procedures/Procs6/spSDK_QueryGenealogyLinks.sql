CREATE PROCEDURE dbo.spSDK_QueryGenealogyLinks
 	 @LineName 	 nvarchar(50),
 	 @UnitName 	 nvarchar(50),
 	 @EventName 	 nvarchar(50),
 	 @Levels 	  	 TINYINT,
 	 @Direction 	 TINYINT,
 	 @UserId 	  	 INT 	  	  	  	 = NULL,
 	 @QueryType 	 INT 	  	  	  	 = NULL
AS
DECLARE @LineId int
DECLARE @UnitId int
DECLARE @EventId int
DECLARE @CurrentLevel int
IF @Levels = 0 	 SELECT @Levels = 200
SELECT 	 @LineId = PL_Id 
 	 FROM 	 Prod_Lines 
 	 WHERE PL_Desc = @LineName
SELECT 	 @UnitId = pu_id
 	 FROM 	 Prod_Units 
 	 WHERE PU_Desc = @UnitName
 	 AND  	 PL_Id = @LineId
SELECT 	 @EventId = Event_Id 
 	 FROM 	 Events 
 	 WHERE 	 PU_Id = @UnitId
 	 AND  	 Event_Num = @EventName
DECLARE @ResultComponents TABLE (
 	 Component_Id 	 INT,
 	 Event_id 	  	  	 INT,
 	 LevelNumber 	  	 INT
)
DECLARE @SearchEvents TABLE (
 	 Event_Id 	  	  	 INT
)
INSERT INTO 	 @SearchEvents (Event_Id)
 	 VALUES 	 (@EventId)
SELECT @CurrentLevel = 1
--Search Forward In Genealogy
IF @Direction IN (0,1)
BEGIN
 	 WHILE (SELECT COUNT(*) FROM @SearchEvents) > 0 AND @CurrentLevel <= @Levels
 	 BEGIN
 	  	 INSERT INTO 	 @ResultComponents (Component_id, Event_Id, LevelNumber)
 	  	  	 SELECT 	 Component_Id, Event_Id, @CurrentLevel 
 	  	  	  	 FROM 	 Event_Components
 	  	  	  	 WHERE Source_Event_Id IN (SELECT Event_Id FROM @SearchEvents)
 	  	 
 	  	 DELETE FROM @SearchEvents
 	  	 
 	  	 INSERT INTO 	 @SearchEvents (Event_id)
 	  	  	 SELECT 	 Event_id 
 	  	  	  	 FROM 	 @ResultComponents 
 	  	  	  	 WHERE 	 LevelNumber = @CurrentLevel
 	  	 
 	  	 SELECT @CurrentLevel = @CurrentLevel + 1
 	 END  
END
DELETE 	 @SearchEvents
INSERT INTO 	 @SearchEvents (Event_Id)
 	 VALUES 	 (@EventId)
SELECT 	 @CurrentLevel = -1
--Search Backward In Genealogy
IF 	 @Direction IN (0,2)
BEGIN
 	 WHILE (SELECT COUNT(*) FROM @SearchEvents) > 0 AND @CurrentLevel >= (@Levels * -1)
 	 BEGIN
 	  	 INSERT INTO @ResultComponents (Component_id, Event_Id, LevelNumber)
 	  	  	 SELECT 	 Component_Id, Source_Event_Id, @CurrentLevel 
 	  	  	  	 FROM 	 Event_Components
 	  	  	  	 WHERE 	 Event_Id IN (SELECT Event_Id FROM @SearchEvents)
 	  	 
 	  	 DELETE FROM 	 @SearchEvents
 	  	 
 	  	 INSERT INTO 	 @SearchEvents (Event_id)
 	  	  	 SELECT 	 Event_Id 
 	  	  	  	 FROM 	 @ResultComponents 
 	  	  	  	 WHERE 	 LevelNumber = @CurrentLevel
 	  	 
 	  	 SELECT 	 @CurrentLevel = @CurrentLevel - 1
 	 END  
END
IF @QueryType = 0 OR @QueryType IS NULL
BEGIN
 	  	 --Return Results
 	  	 SELECT 	 GenealogyLinkId = ec.Component_Id,
 	  	  	  	  	 ParentDepartmentName = d1.Dept_Desc,
 	  	  	  	  	 ParentLineName = pl1.pl_desc,
 	  	  	  	  	 ParentUnitName = pu1.pu_desc, 
 	  	  	  	  	 ParentEventName = e1.Event_Num, 
 	  	  	  	  	 ParentEventType = es1.Event_Subtype_Desc, 
 	  	  	  	  	 ChildDepartmentName = d2.Dept_Desc,
 	  	  	  	  	 ChildLineName = pl2.pl_desc,
 	  	  	  	  	 ChildUnitName = pu2.pu_desc, 
 	  	  	  	  	 ChildEventName = e2.Event_Num, 
 	  	  	  	  	 ChildEventType = es2.Event_Subtype_Desc,
 	  	  	  	  	 DimensionX = SUM(ec.Dimension_X), 
 	  	  	  	  	 DimensionY = SUM(ec.Dimension_Y),
 	  	  	  	  	 DimensionZ = SUM(ec.Dimension_Z),
 	  	  	  	  	 DimensionA = SUM(ec.Dimension_A),
 	  	  	  	  	 LevelNumber = rc.LevelNumber,
 	  	  	  	  	 ExtendedInfo = NULL,
 	  	  	  	  	 StartCoordinateX = NULL,
 	  	  	  	  	 StartCoordinateY = NULL,
 	  	  	  	  	 StartCoordinateZ = NULL,
 	  	  	  	  	 StartCoordinateA = NULL,
 	  	  	  	  	 StartTime = MIN(ec.Start_Time),
 	  	  	  	  	 EndTime = MAX(ec.Timestamp),
 	  	  	  	  	 ParentComponentId = NULL,
                                        SignatureId = ec.Signature_Id
 	  	  	 FROM 	 @ResultComponents rc
 	  	  	  	  	 JOIN 	  	  	 Event_Components ec 	  	 ON  	 ec.Component_Id =  rc.Component_Id
 	  	  	  	  	 JOIN 	  	  	 Events e1 	  	  	  	  	 ON  	 e1.Event_id = ec.Source_Event_id 	 
 	  	  	  	  	 LEFT JOIN 	 Event_Configuration ec1 	 ON  	 e1.PU_Id = ec1.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 ec1.ET_Id = 1
 	  	  	  	  	 LEFT JOIN 	 Event_SubTypes es1 	  	 ON 	  	 ec1.Event_Subtype_Id = es1.Event_Subtype_Id
 	  	  	  	  	 JOIN 	  	  	 Prod_Units pu1  	  	  	 ON 	  	 pu1.PU_id = e1.PU_Id
 	  	  	  	  	 JOIN 	  	  	 Prod_Lines pl1  	  	  	 ON 	  	 pl1.pl_id = pu1.PL_Id
 	  	  	  	  	 JOIN 	  	  	 Departments d1 	  	  	  	 ON 	  	 pl1.Dept_Id = d1.Dept_Id
 	  	  	  	  	 JOIN 	  	  	 Events e2 	  	  	  	  	 ON 	  	 e2.Event_id = ec.Event_id
 	  	  	  	  	 LEFT JOIN 	 Event_Configuration ec2 	 ON 	  	 e2.PU_Id = ec2.PU_Id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 ec2.ET_Id = 1
 	  	  	  	  	 LEFT JOIN 	 Event_SubTypes es2 	  	 ON 	  	 ec2.Event_Subtype_Id = es2.Event_Subtype_Id
 	  	  	  	  	 JOIN 	  	  	 Prod_Units pu2 	  	  	  	 ON 	  	 pu2.PU_id = e2.PU_Id
 	  	  	  	  	 JOIN 	  	  	 Prod_Lines pl2 	  	  	  	 ON 	  	 pl2.PL_Id = pu2.PL_Id
 	  	  	  	  	 JOIN 	  	  	 Departments d2 	  	  	  	 ON 	  	 pl2.Dept_Id = d2.Dept_Id
 	  	  	  	  	 LEFT JOIN 	 User_Security pls 	  	  	 ON 	  	 pl1.Group_Id = pls.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pls.User_Id = @UserId
 	  	  	  	  	 LEFT JOIN 	 User_Security pus 	  	  	 ON 	  	 pu1.Group_Id = pus.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pus.User_Id = @UserId 	 
 	  	  	 WHERE rc.Event_Id <> @EventId AND
 	  	  	  	  	 COALESCE(pus.Access_Level, COALESCE(pls.Access_Level, 3)) >= 2
 	  	  	 GROUP BY 	 ec.Component_Id, d1.Dept_Desc, pl1.pl_desc, pu1.pu_desc, e1.Event_Num, es1.Event_Subtype_Desc, 
 	  	  	  	  	  	 d2.Dept_Desc, pl2.pl_desc, pu2.pu_desc, e2.Event_Num, es2.Event_Subtype_Desc, rc.LevelNumber, ec.Signature_Id
END ELSE
BEGIN
 	  	 --Return Results
 	  	 SELECT 	 GenealogyLinkId = ec.Component_Id,
 	  	  	  	  	 ParentDepartmentName = d1.Dept_Desc,
 	  	  	  	  	 ParentLineName = pl1.pl_desc,
 	  	  	  	  	 ParentUnitName = pu1.pu_desc, 
 	  	  	  	  	 ParentEventName = e1.Event_Num, 
 	  	  	  	  	 ParentEventType = es1.Event_Subtype_Desc, 
 	  	  	  	  	 ChildDepartmentName = d2.Dept_Desc,
 	  	  	  	  	 ChildLineName = pl2.pl_desc,
 	  	  	  	  	 ChildUnitName = pu2.pu_desc, 
 	  	  	  	  	 ChildEventName = e2.Event_Num, 
 	  	  	  	  	 ChildEventType = es2.Event_Subtype_Desc,
 	  	  	  	  	 DimensionX = ec.Dimension_X, 
 	  	  	  	  	 DimensionY = ec.Dimension_Y,
 	  	  	  	  	 DimensionZ = ec.Dimension_Z,
 	  	  	  	  	 DimensionA = ec.Dimension_A,
 	  	  	  	  	 LevelNumber = rc.LevelNumber,
 	  	  	  	  	 ExtendedInfo = ec.Extended_Info,
 	  	  	  	  	 StartCoordinateX = ec.Start_Coordinate_X,
 	  	  	  	  	 StartCoordinateY = ec.Start_Coordinate_Y,
 	  	  	  	  	 StartCoordinateZ = ec.Start_Coordinate_Z,
 	  	  	  	  	 StartCoordinateA = ec.Start_Coordinate_A,
 	  	  	  	  	 StartTime = ec.Start_Time,
 	  	  	  	  	 EndTime = ec.Timestamp,
 	  	  	  	  	 ParentComponentId = ec.Parent_Component_Id,
                                        SignatureId = ec.Signature_Id
 	  	  	 FROM 	 @ResultComponents rc
 	  	  	  	  	 JOIN 	  	  	 Event_Components ec 	  	 ON  	 ec.Component_Id =  rc.Component_Id
 	  	  	  	  	 JOIN 	  	  	 Events e1 	  	  	  	  	 ON  	 e1.Event_id = ec.Source_Event_id 	 
 	  	  	  	  	 LEFT JOIN 	 Event_Configuration ec1 	 ON  	 e1.PU_Id = ec1.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 ec1.ET_Id = 1
 	  	  	  	  	 LEFT JOIN 	 Event_SubTypes es1 	  	 ON 	  	 ec1.Event_Subtype_Id = es1.Event_Subtype_Id
 	  	  	  	  	 JOIN 	  	  	 Prod_Units pu1  	  	  	 ON 	  	 pu1.PU_id = e1.PU_Id
 	  	  	  	  	 JOIN 	  	  	 Prod_Lines pl1  	  	  	 ON 	  	 pl1.pl_id = pu1.PL_Id
 	  	  	  	  	 JOIN 	  	  	 Departments d1 	  	  	  	 ON 	  	 pl1.Dept_Id = d1.Dept_Id
 	  	  	  	  	 JOIN 	  	  	 Events e2 	  	  	  	  	 ON 	  	 e2.Event_id = ec.Event_id
 	  	  	  	  	 LEFT JOIN 	 Event_Configuration ec2 	 ON 	  	 e2.PU_Id = ec2.PU_Id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 ec2.ET_Id = 1
 	  	  	  	  	 LEFT JOIN 	 Event_SubTypes es2 	  	 ON 	  	 ec2.Event_Subtype_Id = es2.Event_Subtype_Id
 	  	  	  	  	 JOIN 	  	  	 Prod_Units pu2 	  	  	  	 ON 	  	 pu2.PU_id = e2.PU_Id
 	  	  	  	  	 JOIN 	  	  	 Prod_Lines pl2 	  	  	  	 ON 	  	 pl2.PL_Id = pu2.PL_Id
 	  	  	  	  	 JOIN 	  	  	 Departments d2 	  	  	  	 ON 	  	 pl2.Dept_Id = d2.Dept_Id
 	  	  	  	  	 LEFT JOIN 	 User_Security pls 	  	  	 ON 	  	 pl1.Group_Id = pls.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pls.User_Id = @UserId
 	  	  	  	  	 LEFT JOIN 	 User_Security pus 	  	  	 ON 	  	 pu1.Group_Id = pus.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pus.User_Id = @UserId 	 
 	  	  	 WHERE rc.Event_Id <> @EventId AND
 	  	  	  	  	 COALESCE(pus.Access_Level, COALESCE(pls.Access_Level, 3)) >= 2
END
