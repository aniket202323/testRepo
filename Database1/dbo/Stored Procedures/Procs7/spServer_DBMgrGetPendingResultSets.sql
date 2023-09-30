CREATE PROCEDURE dbo.spServer_DBMgrGetPendingResultSets
@MaxCount int = 100
AS
Declare @Count int
Declare @XMLResultSet XML
declare @SQL nvarchar(max)
declare @RowName nVarChar(100) = 'row'
Declare @RSId BigInt
Set @Count = 0
while (@Count < @MaxCount)
Begin
  	  Set @RSId = null
  	  Select Top 1 @RSId = RS_Id, @XMLResultSet = RS_Value from Pending_ResultSets where Processed = 0 order by RS_Id
  	  -- no rows to process
  	  if (@RSId is null)
  	    	  break
  	  -- Build a dynamic SQL statement which contains the column names from the original sql
  	  Set @SQL = null
  	  --select @SQL = 'select ' + stuff(
  	  --  (
  	  --  select ',T.N.value('''+T.N.value('local-name(.)', 'sysname')+'[1]'', ''nVarChar(max)'') as '+T.N.value('local-name(.)', 'sysname')
  	  --  from @XMLResultSet.nodes('/rows/*[local-name(.)=sql:variable("@RowName")]/*') as T(N)
  	  --  for xml path(''), type
  	  --  ).value('.', 'nvarchar(max)'), 1, 1, '')+
  	  --  ' from @XML.nodes(''/rows/*[local-name(.)=sql:variable("@RowName")]'') as T(N)'
 	    ;WITH S AS (   
  	  SELECT  	  
 	 T.N.value('local-name(.)', 'nVARCHAR(MAX)') attributeName,
    T.N.value('.', 'nVARCHAR(MAX)') attributeValue
FROM @XMLResultSet.nodes('/rows/row/*')as T(N))
Select @SQL =COALESCE(@SQL+',','')+ ''''+attributeValue+'''  as ['+attributeName+']' from S 
 	 Select @SQL=' SELECT '+@SQL
 	  
  	  -- execute the dynamic sql
  	  if (@SQL is not null)
  	    	  begin
  	    	    	  --exec sp_executesql @SQL, N'@XML xml, @RowName nVarChar(100)', @XML = @XMLResultSet, @RowName = @RowName
 	  	  	  EXEC (@SQL)
  	    	    	  Delete from Pending_ResultSets where RS_Id = @RSId
  	    	  end
  	  else
  	    	  -- Error processing this one, so mark it processed and do not delete it
  	    	  begin
  	    	    	  update Pending_ResultSets set Processed = 1 where RS_Id = @RSId
  	    	  end
  	  Set @Count = @Count + 1
End
