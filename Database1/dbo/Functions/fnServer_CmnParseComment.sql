CREATE FUNCTION dbo.fnServer_CmnParseComment(
@largeComment varchar (7000)
) 
  Returns VarChar(7000)
AS 
begin
  Declare @End Int
  SET @end = CHARINDEX('\par',@largeComment,DataLength(@largeComment) - 10)
  IF @end = 0 
    Return @largeComment
  SET @largeComment = SUBSTRING(@largeComment,1,@end-1)
  WHILE  SUBSTRING(@largeComment,DataLength(@largeComment),1) = ' '
    BEGIN
      SET @largeComment = SUBSTRING(@largeComment,1,DataLength(@largeComment)-1)
    END
  SET @end = DataLength(@largeComment)
  WHILE @end > 1
    BEGIN
      IF SUBSTRING(@largeComment,@end,1) = '\'
        BEGIN
          SET @largeComment = SUBSTRING(@largeComment,CHARINDEX(' ',@largeComment,@end),DataLength(@largeComment)- @end)
          SET @end = 0
        END
      SET @end = @end -1
    END
  WHILE  SUBSTRING(@largeComment,1,1) = ' '
    BEGIN
      SET @largeComment = SUBSTRING(@largeComment,2,DataLength(@largeComment))
    END
  RETURN @largeComment
END
