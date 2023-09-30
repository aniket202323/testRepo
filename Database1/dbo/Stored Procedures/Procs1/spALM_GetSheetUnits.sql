CREATE PROCEDURE dbo.spALM_GetSheetUnits
@Sheet_Id int,
@SheetUnits nvarchar(255) OUTPUT
as
Declare @PU_Id int
Declare SheetUnitsCursor INSENSITIVE CURSOR
  For select distinct v.pu_id from variables v
    join sheet_variables sv on sv.var_id = v.var_id
    join sheets s on s.sheet_id = sv.sheet_id
    where s.sheet_id = @Sheet_Id
  For Read Only
  Open SheetUnitsCursor  
SheetUnitsLoop:
  Fetch Next From SheetUnitsCursor Into @PU_Id
  If (@@Fetch_Status = 0)
    Begin
      if @PU_Id > 0
        Begin
          select @SheetUnits = LTrim(RTrim(Convert(nvarchar(10), @PU_Id))) + '\'
        End
      Goto SheetUnitsLoop
    End
Close SheetUnitsCursor
Deallocate SheetUnitsCursor
