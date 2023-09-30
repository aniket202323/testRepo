CREATE PROCEDURE dbo.spCC_LookupView
  @View_Desc nvarchar(50),
  @Create int, 
  @UserId int, 
  @Toolbar_Version nvarchar(15),
  @Group_Id int,
  @View_Id int OUTPUT
 AS 
Declare @Id int, @Sql nvarchar(1000)
If @Group_Id = 0 Select @Group_Id = Null --Default Group
If @View_Desc > '' 
BEGIN
  Select @Id = View_Id 
    From Views 
    Where View_Desc = @View_Desc
END
If Not @Id Is NULL and Not @Toolbar_Version Is NULL
BEGIN
  Update Views
    Set Toolbar_Version = @ToolBar_Version, Group_Id = @Group_Id
      Where View_Id = @Id
END
IF @Id IS NULL 
BEGIN
  IF @Create = 1 and @View_Desc > ''
  BEGIN
 	   Select @Group_Id = isnull(@Group_Id,1)  -- Default administrator group on new create
 	   If Exists (select * from dbo.syscolumns where name = 'View_Desc_Local' and id =  object_id(N'[Views]'))
 	  	 Select @Sql =  'INSERT INTO Views(View_Desc_Local, Toolbar_Version, Group_Id)'
 	   Else
 	  	 Select @Sql =  'INSERT INTO Views(View_Desc, Toolbar_Version, Group_Id)'
    Select @Sql = @Sql + ' VALUES(''' + replace(@View_Desc,'''','''''') + ''',''' + @Toolbar_Version + ''',' + Convert(nvarchar(10), @Group_Id) + ')'
 	   Execute(@Sql)
    SELECT @View_Id = View_Id FROM Views WHERE View_Desc = @View_Desc
    If @View_Id IS NULL
      Return(1)
  END
END
ELSE
  SELECT @View_Id = @Id
--IF @@ERROR > 0 RETURN (0)
--RETURN(1)
