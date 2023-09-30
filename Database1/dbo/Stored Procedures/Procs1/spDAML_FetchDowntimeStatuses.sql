Create Procedure dbo.spDAML_FetchDowntimeStatuses
    @StatusId 	  	 INT = NULL,
    @LineId         INT = NULL,
    @UnitId         INT = NULL,
    @StatusName 	  	 VARCHAR(100) = NULL,
    @StatusValue 	 VARCHAR(25) = NULL,
 	 @UserId 	  	  	 INT 	 = NULL
AS
-- Local variables
DECLARE 	 
    @SecurityClause VARCHAR(100),
    @IdClause 	  	 VARCHAR(50),
    @OptionsClause  VARCHAR(1000),
    @TimeClause 	  	 VARCHAR(500),
 	 @WhereClause 	 VARCHAR(2000),
    @SelectClause   VARCHAR(4000),
 	 @OrderClause 	 VARCHAR(500)
-- The production unit and production line have security levels
SET @SecurityClause = ' WHERE COALESCE(pus.Access_Level, pls.Access_Level, 3) >= 2 '
-- One and only one of the following id values is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@StatusId<>0 AND @StatusId IS NOT NULL) THEN 'AND ds.TEStatus_Id = ' + CONVERT(VARCHAR(10), @StatusId) 
   WHEN (@UnitId<>0 AND @UnitId IS NOT NULL) THEN 'AND pu.PU_Id = ' + CONVERT(VARCHAR(10),@UnitId)
   WHEN (@LineId<>0 AND @LineId IS NOT NULL) THEN 'AND pl.PL_Id = ' + CONVERT(VARCHAR(10),@LineId)
   ELSE ''
END
-- All of the following are optional and some or none can apply
-- All will use LIKE if a mask is present
SET @OptionsClause = ''
IF (@StatusName<>'' AND @StatusName IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @StatusName)=0 AND CHARINDEX('_', @StatusName)=0 )
     SET @OptionsClause = @OptionsClause + ' AND ds.TEStatus_Name = ''' + CONVERT(VARCHAR(100),@StatusName) + ''' '
   ELSE
      SET @OptionsClause = @OptionsClause + ' AND ds.TEStatus_Name LIKE ''' + CONVERT(VARCHAR(100),@StatusName) + ''' '
END   
IF (@StatusValue<>'' AND @StatusValue IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @StatusValue)=0 AND CHARINDEX('_', @StatusValue)=0 )
     SET @OptionsClause = @OptionsClause + ' AND ds.TEStatus_Value = ''' + CONVERT(VARCHAR(25),@StatusValue) + ''' '
   ELSE
      SET @OptionsClause = @OptionsClause + ' AND ds.TEStatus_Value LIKE ''' + CONVERT(VARCHAR(25),@StatusValue) + ''' '
END 
-- Downtime status has no time clause
SET @TimeClause = ''
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
SET @SelectClause =
 	 'SELECT 	 DowntimeStatusId 	 = 	 ds.TEStatus_Id,
            DowntimeStatusName 	 =   ds.TEStatus_Name,
            DowntimeStatusValue 	 =   ds.TEStatus_Value,
 	  	  	 ProductionUnitId 	 =   ds.PU_Id,
 	  	  	 ProductionUnit 	  	 = 	 pu.PU_Desc,
 	  	  	 ProductionLineId 	 = 	 pl.PL_Id,
 	  	  	 ProductionLine 	  	 = 	 pl.PL_Desc,
 	  	  	 DepartmentId 	  	 = 	 d.Dept_Id,
 	  	  	 Department 	  	  	 = 	 d.Dept_Desc
 	 FROM 	 Timed_Event_Status ds
 	 INNER JOIN 	 Prod_Units pu 	 ON 	 ds.PU_ID = pu.PU_Id
    INNER JOIN 	 Prod_Lines pl 	 ON 	 pu.PL_Id = pl.PL_Id
    INNER JOIN 	 Departments d 	 ON 	 d.Dept_Id = pl.Dept_Id 
 	 LEFT JOIN 	 User_Security pls 	  	 ON 	  	 pl.Group_Id = pls.Group_Id 	 
 	  	  	  	  	  	  	  	  	  	  	  	 AND pls.User_Id = ' + CONVERT(VARCHAR(10),@UserId) + 	  	  	 
  ' LEFT JOIN 	 User_Security pus 	  	 ON 	  	 pu.Group_Id = pus.Group_Id 
 	  	  	  	  	  	  	  	  	  	  	     AND pus.User_Id = ' + CONVERT(VARCHAR(10),@UserId)
-- Downtime Status has no order clause
SET @OrderClause = ' ORDER BY ds.TEStatus_Name '
--SELECT sc = @SelectClause, wc = @WhereClause, oc = @OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause)
