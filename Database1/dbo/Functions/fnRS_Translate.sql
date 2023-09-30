/*
Example Call
select dbo.fnRS_Translate(35153, 0, 'bob')
*/
CREATE FUNCTION dbo.fnRS_Translate(@Report_Id INT, @PromptId INT, @DefaultString VARCHAR(8000))
returns VarChar(8000)
as
BEGIN
  DECLARE @OwnerId Int
  DECLARE @LangId Int
  DECLARE @LocalString VarChar(8000)
  Select @OwnerId = OwnerId From Report_Definitions Where Report_Id = @Report_Id
  If @OwnerId Is Null
    Select @OwnerId = 1 -- ComXClient
  Select @LangId = Convert(int, value) from User_Parameters where user_Id = @OwnerId and Parm_Id = 8
  If @LangId Is Null
    Select @LangId = 0
  -- Call to Jason's translate function
  Select @LocalString = dbo.fnTranslate(@LangId, @PromptId, @DefaultString)
  RETURN @LocalString
END
