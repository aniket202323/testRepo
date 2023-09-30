Create Procedure dbo.spDBR_Get_Translation
@LanguageID int = 0, 
@PromptId int = 38083,
@default varchar(8000) = ''
AS
declare @cmd nvarchar(4000)
select @cmd = 'select dbo.fnDBTranslate(' + convert(nvarchar(50),@LanguageID) + ', ' + convert(nvarchar(50),@PromptID) + ', ''' + @default + ''')'
execute sp_executesql @cmd
