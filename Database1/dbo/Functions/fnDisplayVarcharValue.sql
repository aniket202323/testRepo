create function dbo.fnDisplayVarcharValue(@DataTypeId INT, @Value nVarChar(25))
returns SQL_Variant
as
BEGIN
IF @DataTypeId Is Null
  If IsNumeric(@Value) = 1
    Return Cast(@Value As Float)
  Else If IsDate(@Value) = 1
    Return Cast(@Value As DateTime)
  Else
    Return @Value
IF @DataTypeId = 2
  RETURN CAST(@Value AS FLOAT)
ELSE
  RETURN @Value
RETURN NULL
END
