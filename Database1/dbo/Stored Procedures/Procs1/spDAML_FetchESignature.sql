Create Procedure dbo.spDAML_FetchESignature
 	 @ESignatureId INT = NULL,
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
CASE WHEN (@ESignatureId<>0 AND @ESignatureId IS NOT NULL) THEN ' AND s.Signature_Id = ' + CONVERT(VARCHAR(10),@ESignatureId) 
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
SET @SelectClause = 	 'SELECT 	 ESignatureId = s.Signature_Id,
  OperatorId = IsNull(s.Perform_User_Id,0),
  Operator = IsNull(opu.Username,''''),
  OperatorLocation = IsNull(s.Perform_Node,''''),
  OperatorTime = CASE WHEN s.Perform_Time Is Null Then ' + @MaxTime +
 	            ' ELSE dbo.fnServer_CmnConvertFromDbTime(s.Perform_Time,''UTC'')  ' +
               ' END,
  OperatorCommentId = IsNull(s.Perform_Comment_Id,0),
  OperatorComment = IsNull(opc.Comment,''''),
  ApproverId = IsNull(s.Verify_User_Id,0),
  Approver = IsNull(apu.Username,''''),
  ApproverLocation = IsNull(s.Verify_Node,''''),
  ApproverTime = CASE WHEN s.Verify_Time Is Null Then ' + @MaxTime +
 	            ' ELSE dbo.fnServer_CmnConvertFromDbTime(s.Verify_Time,''UTC'')  ' + 
               ' END,
  ApproverCommentId = IsNull(s.Verify_Comment_Id,0),
  ApproverComment = IsNull(apc.Comment,''''),
  ExtendedInfo = IsNull(s.Extended_Info,'''')
FROM ESignature s 
  LEFT JOIN Users opu ON opu.User_Id = s.Perform_User_Id
  LEFT JOIN Comments opc ON opc.Comment_Id = s.Perform_Comment_Id
  LEFT JOIN Users apu ON apu.User_Id = s.Verify_User_Id
  LEFT JOIN Comments apc ON apc.Comment_Id = s.Verify_Comment_Id '
-- order clause
SET @OrderClause = ' ORDER BY ESignatureId '
--SELECT sc = @SelectClause, wc = @WhereClause, oc = @OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause)
