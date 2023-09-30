create procedure dbo.spSupport_VerifyDB_Rule
@Rulename varchar(100),
@CreateStatement varchar(1000)
AS
Declare
  @RuleId int,
  @Statement varchar(2000)
SELECT @Rulename = 'dbo.' + @Rulename
Select @RuleId = NULL
Select @RuleId = object_id(@Rulename)
If (@RuleId Is NULL)
  Begin
    Select @Statement = @CreateStatement
    Execute (@Statement)
    Select @Statement = '-- Added Rule [' + @RuleName + ']'
    Print @Statement
    Return
  End
