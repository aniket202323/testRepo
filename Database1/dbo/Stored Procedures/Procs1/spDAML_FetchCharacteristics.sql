Create Procedure dbo.spDAML_FetchCharacteristics
    @CharId 	  	 INT = NULL,
 	 @PropId 	  	 INT = NULL,
 	 @UserId 	  	 INT 	 = NULL
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
-- All queries check user security
SET @SecurityClause = ' WHERE COALESCE(c1s.Access_Level, pps.Access_Level, 3) >= 2 '
-- Only one of the following id values, if any, is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@CharId<>0 AND @CharId IS NOT NULL) THEN 'AND c1.Char_Id = ' + CONVERT(VARCHAR(10),@CharId) 
   WHEN (@PropId<>0 AND @PropId IS NOT NULL) THEN 'AND c1.Prop_Id = ' + CONVERT(VARCHAR(10),@PropId) 
   ELSE ''
END
-- Characteristics have no options clause
SET @OptionsClause = ''
-- Characteristics have no time clause
SET @TimeClause = ''
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
SET @SelectClause =
   'SELECT 	 DISTINCT
 	  	  	 CharacteristicId = c1.Char_Id,
 	  	  	 CharacteristicName = IsNull(c1.Char_Desc,''''),
 	  	  	 PropertyId = pp.Prop_Id,
 	  	  	 PropertyName = pp.Prop_Desc,  	  	 
 	  	  	 ParentCharacteristicId = IsNull(c1.Derived_From_Parent,0),
 	  	  	 ParentCharacteristic = IsNull(c2.Char_Desc, ''''),
 	  	  	 CommentId = IsNull(c1.Comment_Id,0),
 	  	  	 ExtendedInfo = IsNull(c1.Extended_Info,'''')
 	 FROM 	 Product_Properties pp
 	 JOIN 	 Characteristics c1 	  	  	 ON 	  	 pp.Prop_Id = c1.Prop_Id
 	 LEFT JOIN 	 Characteristics c2 	  	 ON 	  	 c2.Char_Id = c1.Derived_From_Parent
 	 LEFT JOIN 	 User_Security pps 	  	 ON 	  	 pp.Group_Id = pps.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pps.User_Id = ' + CONVERT(VARCHAR(10), @UserId) +
  ' LEFT JOIN 	 User_Security c1s 	  	 ON 	  	 c1.Group_Id = c1s.Group_Id 
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 c1s.User_Id = ' + CONVERT(VARCHAR(10), @UserId)
-- Order clause
SET @OrderClause = ' ORDER BY CharacteristicName'
-- SELECT sc = @SelectClause, wc = @WhereClause, oc = @OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause)
