CREATE FUNCTION dbo.fnServer_DBMgrUpdGetExclusiveLock()
RETURNS BIT
--WITH EXECUTE AS CALLER
AS
BEGIN
/*
  declare @x tinyint
  IF 1 = (SELECT Lock FROM dbo.CXSMarshal WITH (NOLOCK) WHERE CXSMarshalId = 1 )
    BEGIN
      SELECT @x = CXSMarshalId FROM dbo.CXSMarshal WITH (TabLockX, HoldLock)
    END
*/
  RETURN(1)
END
