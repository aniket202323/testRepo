create function dbo.fnIsNull(@Val1 SQL_Variant, @Val2 SQL_Variant)
  returns SQL_Variant
as
BEGIN
Return Case
   When (@Val1 Is Not Null) Then @Val1
   When (@Val2 Is Not Null) Then @Val2
   ELSE NULL
End
Return Null
END
