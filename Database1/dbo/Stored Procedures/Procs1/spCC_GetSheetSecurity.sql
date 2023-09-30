Create Procedure dbo.spCC_GetSheetSecurity
  @User_Id int = NULL,
  @Sheet_Desc nvarchar(50),
  @AccessLevel int Output
 AS 
Declare @GroupId int
Declare @AdminToAdmin int
Select @AccessLevel = 0 --Default to no access
Select @AdminToAdmin = Count(*) from User_Security where User_Id = @User_Id and Group_Id = 1 and Access_Level = 4
if @AdminToAdmin = 1
  Begin
    Select @AccessLevel = 4 --Admin level
    Return(0)
  End
Select @GroupId = coalesce(s.Group_Id, sg.Group_Id)
  From Sheets s
    Left Outer Join Sheet_Groups sg on sg.Sheet_Group_Id = s.Sheet_Group_Id
    Where Sheet_Desc = @Sheet_Desc
if @GroupId = 0 or @GroupId is NULL --Sheet not assigned or not found
  Begin
    Select @AccessLevel = 4 --Admin level
    Return(0)
  End
Select @AccessLevel = Coalesce(Access_Level, 0)
  From User_Security where User_Id = @User_Id and Group_Id = @GroupId
Return(0)
