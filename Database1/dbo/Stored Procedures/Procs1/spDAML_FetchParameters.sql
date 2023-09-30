Create Procedure dbo.spDAML_FetchParameters
    @ParmId 	  	 INT = NULL,
    @ParmType 	 VARCHAR(50) = NULL,
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
-- Parameters have no special security requirements
SET @SecurityClause = ' WHERE p.system = 0 '
-- Only one of the following id values, if any, is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@ParmId<>0 AND @ParmId IS NOT NULL) THEN 'AND p.Parm_Id = ' + CONVERT(VARCHAR(10),@ParmId)
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
IF (@ParmType<>'' AND @ParmType IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @ParmType)=0 AND CHARINDEX('_', @ParmType)=0 )
      SET @OptionsClause = @OptionsClause + ' AND pt.Parm_Type_Desc = ''' + CONVERT(VARCHAR(50),@ParmType) + ''' '
   ELSE
      SET @OptionsClause = @OptionsClause + ' AND pt.Parm_Type_Desc LIKE ''' + CONVERT(VARCHAR(50),@ParmType) + ''' '
END 
-- The Parameters have no TimeClause
SET @TimeClause = ''
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
SET @SelectClause =
'SELECT 	  	 ParameterId 	  	 = 	 p.Parm_Id,
 	  	  	 ParameterName 	 = 	 p.Parm_Name,
 	  	  	 Description 	  	 = 	 IsNull(p.Parm_Long_Desc,''''),
 	  	  	 CategoryId 	  	 =   IsNull(p.Parameter_Category_Id, 0),
 	  	  	 Category 	  	 = 	 IsNull(pc.Parameter_Category_Desc,''''),
 	  	  	 ParameterTypeId = 	 IsNull(p.Parm_Type_Id,0),
 	  	  	 ParameterType 	 = 	 IsNull(pt.Parm_Type_Desc,''''),
 	  	  	 FieldTypeId 	  	 = 	 p.Field_Type_Id,
 	  	  	 FieldType 	  	 = 	 IsNull(ft.Field_Type_Desc,'''')
 	 FROM 	  	  	 Parameters p
 	 LEFT 	 JOIN 	 ED_FieldTypes ft 	  	 ON 	  	 ft.ED_Field_Type_Id = p.Field_Type_Id
 	 LEFT 	 JOIN 	 Parameter_Categories pc 	 ON 	  	 pc.Parameter_Category_Id = p.Parameter_Category_Id
 	 LEFT 	 JOIN 	 Parameter_Types pt 	 ON 	  	 pt.Parm_Type_Id = p.Parm_Type_Id'
-- order clause
SET @OrderClause = ' ORDER BY p.Parm_Name '
--SELECT sc = @SelectClause, wc = @WhereClause, oc = @OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause)
