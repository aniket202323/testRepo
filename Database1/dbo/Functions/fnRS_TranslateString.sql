/*
Example Call
select dbo.fnRS_TranslateString(2, 'Production Event')
select dbo.fnRS_TranslateString(2, 'Back')
select * from sysobjects where xtype = 'U' and name like '%lang%' order by name
select * from languages
*/
CREATE FUNCTION dbo.fnRS_TranslateString(@Language_Id INT, @Prompt_String VARCHAR(7000))
returns VarChar(8000)
as
BEGIN
  DECLARE @Prompt_Number Int
  DECLARE @LocalString VarChar(8000)
  Select @Prompt_Number = Prompt_Number from language_data where prompt_string = @Prompt_String
  if @Prompt_Number Is Not Null
    Begin
 	  Select @LocalString = Prompt_String From Language_Data Where Prompt_Number = @Prompt_Number and Language_Id = @Language_Id
 	  If @LocalString Is Null
        Select @LocalString = @Prompt_String
    End
  Else
    Select @LocalString = @Prompt_String
  RETURN @LocalString
END
