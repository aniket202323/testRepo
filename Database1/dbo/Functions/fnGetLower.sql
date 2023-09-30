create function dbo.[fnGetLower](@Val1 SQL_Variant, @Val2 SQL_Variant)
  returns SQL_Variant
as
BEGIN
Return Case
 	  When @Val1 Is Null And @Val2 Is Null Then Null
 	  When @Val1 Is Null Then @Val2
 	  When @Val2 Is Null Then @Val1
   When @Val1 >= @Val2 Then @Val2
   When @Val2 > @Val1 Then @Val1
   ELSE NULL
End
Return Null
END
