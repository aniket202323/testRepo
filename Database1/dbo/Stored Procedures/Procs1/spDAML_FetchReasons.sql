Create Procedure dbo.spDAML_FetchReasons
 	 @ReasonId 	 INT = NULL,
 	 @ReasonName 	 VARCHAR(100)= NULL,
 	 @ReasonCode VARCHAR(10) = NULL,
 	 @UserId 	  	 INT = NULL
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
-- reasons have security
SET @SecurityClause = ' WHERE (COALESCE(ers.Access_Level, 3) >= 2) '
-- Only one of the following id values, if any, is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause =
CASE WHEN (@ReasonId<>0 AND @ReasonId IS NOT NULL) THEN ' AND er.Event_Reason_Id = ' + CONVERT(VARCHAR(10),@ReasonId)
   ELSE ''
END
-- All of the following are optional and some or none can apply
SET @OptionsClause = ''
IF (@ReasonName<>'' AND @ReasonName IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @ReasonName)=0 AND CHARINDEX('_', @ReasonName)=0 )
      SET @OptionsClause = @OptionsClause + ' AND (er.Event_Reason_Name = ''' + CONVERT(VARCHAR(100),@ReasonName) + ''') '
   ELSE
 	   SET @OptionsClause = @OptionsClause + ' AND (er.Event_Reason_Name LIKE ''' + CONVERT(VARCHAR(100),@ReasonName) + ''') '
END
IF (@ReasonCode<>'' AND @ReasonCode IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @ReasonCode)=0 AND CHARINDEX('_', @ReasonCode)=0 )
      SET @OptionsClause = @OptionsClause + ' AND (er.Event_Reason_Code = ''' + CONVERT(VARCHAR(10),@ReasonCode) + ''') '
   ELSE
 	   SET @OptionsClause = @OptionsClause + ' AND (er.Event_Reason_Code LIKE ''' + CONVERT(VARCHAR(10),@ReasonCode) + ''') '
END
-- Reasonss have no time clause
SET @TimeClause = ''
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
--   All DATES are converted to UTC
SET @SelectClause =
 	 'Select ReasonId = Event_Reason_Id, 
 	  	  	 ReasonName = Event_Reason_Name, 
 	  	  	 ReasonCode = IsNull(Event_Reason_Code,''''),
 	  	  	 CommentId = IsNull(Comment_Id,0),
 	  	  	 ExtendedInfo = IsNull(External_Link,'''')
 	 FROM 	 Event_Reasons er
 	 LEFT JOIN 	 User_Security ers 	 ON  	 er.Group_Id = ers.Group_Id
 	  	  	  	  	  	  	  	  	 AND 	 ers.User_Id = ' + CONVERT(VARCHAR(10), @UserId)
-- order clause
SET @OrderClause = ' ORDER BY er.Event_Reason_Name '
-- SELECT sc = @SelectClause, wc = @WhereClause, oc = @OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause)
