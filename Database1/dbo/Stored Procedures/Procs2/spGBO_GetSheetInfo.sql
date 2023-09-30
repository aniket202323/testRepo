Create Procedure dbo.spGBO_GetSheetInfo 
  @SheetName nvarchar(50),
  @GroupId int Output,
  @DisplayHyperLinks int Output,
  @UseWebApp int Output     AS
  Declare @Sheet_Id int,
          @Sheet_Type int
  Select @GroupId = coalesce(s.Group_Id, sg.Group_Id), @Sheet_Id = Sheet_Id, @Sheet_Type = Sheet_Type From Sheets s
    Left Outer Join Sheet_Groups sg on sg.Sheet_Group_Id = s.Sheet_Group_Id
    Where Sheet_Desc = @SheetName
  Select @GroupId = coalesce(@GroupId, 0)
  Select @DisplayHyperLinks = coalesce(Value, 0) from Sheet_Display_Options
    Where Sheet_Id = @Sheet_Id and Display_Option_Id = 229
  If @DisplayHyperLinks is NULL 
    Begin
      Select @DisplayHyperLinks = Display_Option_Default from Sheet_Type_Display_Options Where Display_Option_Id = 229 and Sheet_Type_Id = @Sheet_Type
    End
  Select @UseWebApp = coalesce(Value, 0) from Sheet_Display_Options
    Where Sheet_Id = @Sheet_Id and Display_Option_Id = 228
  If @UseWebApp is NULL 
    Begin
      Select @UseWebApp = Display_Option_Default from Sheet_Type_Display_Options Where Display_Option_Id = 228 and Sheet_Type_Id = @Sheet_Type
    End
