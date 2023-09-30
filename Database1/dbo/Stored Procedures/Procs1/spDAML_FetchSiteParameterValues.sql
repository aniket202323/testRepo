Create Procedure dbo.spDAML_FetchSiteParameterValues
    @ParmId 	  	 INT = NULL,
 	 @ParmName 	 VARCHAR(50) = NULL
AS
-- Local variables
DECLARE 	 
    @SecurityClause VARCHAR(100),
    @IdClause 	  	 VARCHAR(50),
    @OptionsClause  VARCHAR(1000),
    @TimeClause 	  	 VARCHAR(500),
 	 @WhereClause 	 VARCHAR(1000),
    @SelectClause   VARCHAR(4000),
 	 @OrderClause 	 VARCHAR(500)
-- Parameter Values have no security, but we do not show system parameters
SET @SecurityClause = ' WHERE p.System = 0 '
-- One and only one of the following id values is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@ParmId<>0 AND @ParmId IS NOT NULL) THEN ' AND p.Parm_Id = ' + CONVERT(VARCHAR(10), @ParmId) + ' '
   ELSE ''
END
-- All of the following are optional and some or none can apply
SET @OptionsClause = ''
IF (@ParmName<>'' AND @ParmName IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @ParmName)=0 AND CHARINDEX('_', @ParmName)=0 )
      SET @OptionsClause = @OptionsClause + ' AND p.Parm_Name = ''' + CONVERT(VARCHAR(50),@ParmName) + ''' '
   ELSE
      SET @OptionsClause = @OptionsClause + ' AND p.Parm_Name LIKE ''' + CONVERT(VARCHAR(50),@ParmName) + ''' '
END 
-- Parameter Values have no TimeClause
SET @TimeClause = ''
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
SET @SelectClause =
 	 'SELECT 	 ParameterId 	  	  	 = 	 p.Parm_Id,
 	  	  	 ParameterName 	  	 = 	 IsNull(p.Parm_Name,''''),
 	  	  	 HostName 	  	  	 =   sp.HostName,
 	  	  	 Value 	  	  	  	 = 	 sp.Value,
 	  	  	 MinValue 	  	  	 = 	 IsNull(p.Parm_Min,0),
 	  	  	 MaxValue 	  	  	 = 	 IsNull(p.Parm_Max,0)
 	 FROM 	 Parameters p
 	 INNER JOIN 	 Site_Parameters sp 	 ON 	 sp.Parm_Id = p.Parm_Id '
-- no order clause
SET @OrderClause = ' ORDER BY p.Parm_Name '
-- SELECT sc = @SelectClause, wc = @WhereClause, oc = @OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause)
