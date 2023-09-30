Create Procedure dbo.spDAML_FetchPropertySpecifications
    @SpecId 	  	 INT = NULL,
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
SET @SecurityClause = ' WHERE COALESCE(pps.Access_Level, ss.Access_Level, 3) >= 2 '
--   The Id clause part of the where clause limits by either variable, department, line, unit, or nothing
SELECT @IdClause = 
CASE WHEN (@SpecId<>0 AND @SpecId IS NOT NULL) THEN 'AND s.Spec_Id = ' + CONVERT(VARCHAR(10),@SpecId) 
   WHEN (@PropId<>0 AND @PropId IS NOT NULL) THEN 'AND s.Prop_Id = ' + CONVERT(VARCHAR(10),@PropId) 
   ELSE ''
END
-- specifications have no options clause
SET @OptionsClause = ''
-- specifications have no time clause
SET @TimeClause = ''
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
SET @SelectClause =
 	 'SELECT 	 PropertySpecificationId = s.Spec_Id, 	  	 
 	  	  	 PropertySpecificationName = s.Spec_Desc,
 	  	  	 PropertyId = s.Prop_Id,
 	  	  	 PropertyName = pp.Prop_Desc,
 	  	  	 DataTypeId = s.Data_Type_Id,
 	  	  	 DataType = dt.Data_Type_Desc, 
 	  	  	 SpecPrecision = IsNull(s.Spec_Precision, 0),
 	  	  	 EngineeringUnits = IsNull(s.Eng_Units, ''''),
 	  	  	 Tag = IsNull(s.Tag, ''''),
 	  	  	 ExtendedInfo = IsNull(s.Extended_Info,''''),
 	  	  	 CommentId = IsNull(s.Comment_Id,0)
 	 FROM 	 Product_Properties pp
 	  	  	 JOIN 	 Specifications s 	  	 ON 	  	 pp.Prop_Id = s.Prop_Id 
 	  	  	 JOIN 	 Data_Type dt 	  	  	 ON 	  	 s.Data_Type_Id = dt.Data_Type_Id
 	  	  	 LEFT JOIN 	 User_Security pps 	 ON 	  	 pp.Group_Id = pps.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pps.User_Id = ' + CONVERT(VARCHAR(10), @UserId) +
 	  	 ' 	 LEFT JOIN 	 User_Security ss 	 ON 	  	 s.Group_Id = ss.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 ss.User_Id = ' + CONVERT(VARCHAR(10), @UserId)
-- order clause
SET @OrderClause = ' ORDER BY pp.Prop_Desc, s.Spec_Order'
-- SELECT sc = @SelectClause, wc = @WhereClause, oc = @OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause)
