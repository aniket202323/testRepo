CREATE Function  dbo.fnSDK_DEI_GetDisplayOptionValue(
@DisplayOptionDesc VarChar(1000),
@SheetType Int,
@SheetId Int,
@DisplayOptionCategory Int
)
Returns VarChar(1000)
AS
begin
DECLARE @Disp_Opt_Id Int
DECLARE @SheetTypeOption Int
DECLARE @ReturnValue VarChar(1000) 
IF @DisplayOptionCategory IS NOT NULL
 	 SELECT @Disp_Opt_Id = a.Display_Option_Id 
 	 FROM Display_Options a
 	 WHERE a.Display_Option_Desc = @DisplayOptionDesc and a.Display_Option_Category_Id = @DisplayOptionCategory
ELSE
 	 SELECT @Disp_Opt_Id = Min(a.Display_Option_Id) 
 	 FROM Display_Options a
 	 WHERE a.Display_Option_Desc = @DisplayOptionDesc
 	 
IF @SheetId IS Null 	 
 	 SELECT @ReturnValue = b.Display_Option_Default
 	  	 FROM Sheet_Type_Display_Options b
 	  	 WHERE b.Display_Option_Id = @Disp_Opt_Id and b.Sheet_Type_Id = @SheetType 
ELSE
 	 SELECT @ReturnValue = Coalesce(c.value,b.Display_Option_Default)
 	  	 FROM Sheet_Type_Display_Options b
 	  	 LEFT Join Sheet_Display_Options c  on c.Display_Option_Id = b.Display_Option_Id and c.Sheet_Id = @SheetId
 	  	 WHERE b.Display_Option_Id = @Disp_Opt_Id and b.Sheet_Type_Id = @SheetType 
return @ReturnValue
 	 
end
