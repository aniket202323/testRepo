Create Procedure dbo.spDBR_GetColumns
@ColumnVisibility text = NULL
AS
if (not @ColumnVisibility like '%<Root></Root>%'and not @ColumnVisibility is NULL)
begin
  if (not @ColumnVisibility like '%<Root>%')
  begin
    declare @Text nvarchar(4000)
    select @Text = N'Prompt,ColumnName;' + Convert(nvarchar(4000), @ColumnVisibility)
    EXECUTE spDBR_Prepare_Table @Text
  end
  else
  begin
    EXECUTE spDBR_Prepare_Table @ColumnVisibility
  end
end
