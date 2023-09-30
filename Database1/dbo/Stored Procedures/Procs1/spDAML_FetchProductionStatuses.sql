Create Procedure dbo.spDAML_FetchProductionStatuses
    @StatusId 	  	 INT = NULL,
    @StatusName 	  	 VARCHAR(50) = NULL
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
-- Production status has no special security
SET @SecurityClause = ' WHERE 1=1 '
-- One and only one of the following id values is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@StatusId<>0 AND @StatusId IS NOT NULL) THEN 'AND ps.ProdStatus_Id = ' + CONVERT(VARCHAR(10), @StatusId)
   ELSE ''
END
-- All of the following are optional and some or none can apply
SET @OptionsClause = ''
IF (@StatusName<>'' AND @StatusName IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @StatusName)=0 AND CHARINDEX('_', @StatusName)=0 )
     SET @OptionsClause = @OptionsClause + ' AND ps.ProdStatus_Desc = ''' + CONVERT(VARCHAR(50),@StatusName) + ''' '
   ELSE
      SET @OptionsClause = @OptionsClause + ' AND ps.ProdStatus_Desc LIKE ''' + CONVERT(VARCHAR(50),@StatusName) + ''' '
END   
-- Production status has no time clause
SET @TimeClause = ''
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
SET @SelectClause =
 	 'SELECT 	 ProductionStatusId 	 = 	 ps.ProdStatus_Id,
            StatusName 	  	  	 =   ps.ProdStatus_Desc,
 	  	  	 ColorId 	  	  	  	 = 	 IsNull(ps.Color_Id,0),
            ColorName 	  	  	 =   IsNull(c.Color_Desc,''''),
 	  	  	 ColorNumber 	  	  	 = 	 IsNull(c.Color,0),
 	  	  	 CountForInventory 	 = 	 ps.Count_For_Inventory,
 	  	  	 CountForProduction 	 = 	 ps.Count_For_Production,
 	  	  	 StatusValidForInput 	 = 	 IsNull(ps.Status_Valid_For_Input,0)
 	 FROM 	 Production_Status ps
 	 INNER 	 JOIN 	 Colors c 	 ON 	  	 ps.Color_Id = c.Color_Id'
-- no special order clause
SET @OrderClause = ' ORDER BY ps.ProdStatus_Desc '
--SELECT sc = @SelectClause, wc = @WhereClause, oc = @OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause)
