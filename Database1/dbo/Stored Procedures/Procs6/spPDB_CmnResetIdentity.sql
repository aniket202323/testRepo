CREATE PROC dbo.spPDB_CmnResetIdentity
  @prevident int
AS
DECLARE @SQL AS varchar(100)
IF (IsNumeric(@prevident) = 1)
BEGIN 
  if (@prevident <>  @@identity)
  begin
    SELECT @SQL =
      'SELECT IDENTITY(int, ' + CAST(@prevident as varchar) + ', 1) AS ident ' + 'INTO #TmpIdent'
    EXEC(@SQL)
  end
END
