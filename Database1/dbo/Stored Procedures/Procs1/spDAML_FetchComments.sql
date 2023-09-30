Create Procedure dbo.spDAML_FetchComments
 	 @CommentId 	 INT = NULL,
    @UTCOffset VARCHAR(30) = NULL
AS
-- Local variables
DECLARE 	 
  @SecurityClause VARCHAR(100),
  @IdClause 	  	 VARCHAR(500),
  @OptionsClause  VARCHAR(1000),
  @TimeClause 	  	 VARCHAR(500),
  @WhereClause 	 VARCHAR(2000),
  @SelectClause   VARCHAR(4000),
  @OrderClause 	 VARCHAR(500),
  @MinTime  VARCHAR(25),
  @MaxTime  VARCHAR(25)
-- The minimum time in SQL 2005
SET @MinTime = '''1/1/1753'''
SET @MaxTime = '''12/31/9999'''
-- product families have security
SET @SecurityClause = ' WHERE 1=1 '
-- Only one of the following id values, if any, is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause =
CASE WHEN (@CommentId<>0 AND @CommentId IS NOT NULL) 
   THEN ' AND (c.Comment_Id = ' + CONVERT(VARCHAR(10),@CommentId) +
        ' OR c.TopOfChain_Id = ' + CONVERT(VARCHAR(10),@CommentId) + ') '
   ELSE ''
END
-- Product families have no options clause
SET @OptionsClause = ''
-- Product families have no time clause
SET @TimeClause = ''
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
--   All DATES are converted to UTC
SET @SelectClause = 	 'SELECT 	 CommentId = c.Comment_Id,
 	  	  	 RTFComment = IsNull(c.Comment,''''),
 	  	  	 TextComment = IsNull(c.Comment_Text,''''),
 	  	  	 EntryOn = CASE WHEN c.Entry_On Is Null Then ' + @MaxTime +
 	                 ' ELSE dbo.fnServer_CmnConvertFromDbTime(c.Entry_On,''UTC'')  ' + 
                    ' END,
 	  	  	 ExtendedInfo = IsNull(c.Extended_Info,''''),
 	  	  	 TopOfChainCommentId = IsNull(c.TopOfChain_Id,0)
 	 FROM Comments c '
-- order clause
SET @OrderClause = ' ORDER BY CommentId '
--SELECT sc = @SelectClause, wc = @WhereClause, oc = @OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause)
