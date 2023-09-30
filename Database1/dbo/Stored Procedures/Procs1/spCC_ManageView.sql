Create Procedure dbo.spCC_ManageView
  @Action int,
  @View_Desc nvarchar(50),
  @ViewToolbarVersion nvarchar(15), 
  @UserId  Int = Null,
  @View_Id int OUTPUT 
 AS 
Declare 
 @Err int, 
 @NewView_Id int,
 @Sql nvarchar(1000)
DECLARE @Insert_Id integer 
  --
  -- Return Codes:
  --
  --   0 = Success
  --
Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,Coalesce(@UserId,3),'spCC_ManageView', 
 	 convert(nvarchar(10),@Action) + ','  +  
 	 @View_Desc + ','  +  
 	 Coalesce(convert(nvarchar(10),@UserId),'null') ,getdate())
Select @Insert_Id = Scope_Identity()
-- Actions
-- 0 = Delete
-- 1 = Rename
-- 2 = Copy
IF @Action = 0 
BEGIN
  --DELETE User_View_Data WHERE View_Id = @View_Id
  DELETE Views Where View_Id = @View_Id
  SELECT @Err = @@ERROR  
END
ELSE IF @Action = 1 
BEGIN
  If Exists (select * from dbo.syscolumns where name = 'View_Desc_Local' and id =  object_id(N'[Views]'))
 	 Select @Sql =  'Update Views Set View_Desc_Local = ''' + replace(@View_Desc,'''','''''') + ''' Where View_Id = ' + Convert(nvarchar(10),@View_Id)
  Else
 	 Select @Sql =  'Update Views Set View_Desc = ''' + replace(@View_Desc,'''','''''') + ''' Where View_Id = ' + Convert(nvarchar(10),@View_Id)
  Execute(@Sql)
  SELECT @Err = @@ERROR  
END
ELSE IF @Action = 2
BEGIN
  If Exists (select * from dbo.syscolumns where name = 'View_Desc_Local' and id =  object_id(N'[Views]'))
 	 Select @Sql =  'INSERT INTO Views(View_Desc_Local, View_Data, ToolBar_Data, Group_Id, View_Group_Id, Toolbar_Version)'
  Else
 	 Select @Sql =  'INSERT INTO Views(View_Desc, View_Data, ToolBar_Data, Group_Id, View_Group_Id, Toolbar_Version)'
  Select @Sql =  @Sql +  ' SELECT ''' + @View_Desc + ''', View_Data, ToolBar_Data, Group_Id, View_Group_Id, Toolbar_Version FROM Views WHERE View_Id = ' + Convert(nvarchar(10),@View_Id)
  Execute(@Sql)
  SELECT @Err = @@ERROR  
  IF @Err = 0 
  BEGIN 
 	 Create Table #T(View_Id Int)
    If Exists (select * from dbo.syscolumns where name = 'View_Desc_Local' and id =  object_id(N'[Views]'))
      Select @Sql = 'SELECT View_Id FROM Views WHERE View_Desc_Local = ''' + @View_Desc + ''''
    Else
      Select @Sql = 'SELECT View_Id FROM Views WHERE View_Desc = ''' +  @View_Desc + ''''
 	 Insert Into #T 	 Execute (@Sql)
    SELECT @Err = @@ERROR
    SELECT @View_Id = View_Id From #T
  END
END
IF @Err > 0 RETURN (0)
RETURN(1)
