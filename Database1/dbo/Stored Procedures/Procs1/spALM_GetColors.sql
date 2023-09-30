CREATE PROCEDURE dbo.spALM_GetColors
@Color_Id int = NULL
as
if @Color_Id is NULL
  Begin
   select * from colors
    order by color_desc
  End
else
  Begin
    select Color from Colors where Color_Id = @Color_Id
  End
