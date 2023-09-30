create procedure dbo.spSupport_VerifyDB_Key
@TableName varchar(100),
@TrueKeyType varchar(50),
@TrueKeyname varchar(100),
@TrueClusterType varchar(50),
@TrueColName1 varchar(1000),
@TrueColName2 varchar(100) = '',
@TrueColName3 varchar(100) = '',
@TrueColName4 varchar(100) = '',
@TrueColName5 varchar(100) = '',
@TrueColName6 varchar(100) = '',
@TrueColName7 varchar(100) = '',
@TrueColName8 varchar(100) = '',
@TrueColName9 varchar(100) = '',
@TrueColName10 varchar(100) = '',
@TrueUniqueType varchar(20) = ''
AS
Declare
  @TableId int,
  @KeyName varchar(100),
  @Msg varchar(1000),
  @ClusterType varchar(50),
  @IsDesc Int,
  @KeyType varchar(50),
  @Indid int,
  @Pos int,
  @ColName varchar(100),
  @ColName1 varchar(1000),
  @ColName2 varchar(100),
  @ColName3 varchar(100),
  @ColName4 varchar(100),
  @ColName5 varchar(100),
  @ColName6 varchar(100),
  @ColName7 varchar(100),
  @ColName8 varchar(100),
  @ColName9 varchar(100),
  @ColName10 varchar(100),
  @DropNeeded int,
  @AddNeeded int,
  @Statement varchar(3000),
  @xType varchar(30),
  @TableName2 varchar(100),
  @KeyName2 varchar(100),
  @DBVersion int,
  @TestsOldClusteredIndex bit,
  @DBMC_Id int,
  @DBMCGroup 	 Int,
  @Command varchar(2000),
  @HasClustered 	 Int
DECLARE @Cnt int,@totalCnt int,@PublicationName varchar(100),@IsReplicationPresent Int,@CntPublication Int,@DropArticleSQL varchar(MAX),@AddArticleSQL Varchar(max)
CREATE TABLE #tmpPublications(publication_name varchar(100),SerialNo Int Identity(1, 1))
CREATE TABLE #ArticleList(publication nvarchar(256),article nvarchar(256),source_owner nvarchar(256),source_object nvarchar(256))
SET @DropArticleSQL ='' 
IF @TableName = 'CXS_Leaf'
Begin
 	 IF EXISTS(SELECT 1 FROM master.sys.sysdatabases WHERE name='distribution') 
 	 BEGIN
 	  	 INSERT INTO #tmpPublications(publication_name)
 	  	 SELECT 
 	  	  	 DISTINCT p.publication publication_name
 	  	 FROM 
 	  	  	 distribution..MSArticles a
 	  	  	 JOIN distribution..MSpublications p ON a.publication_id = p.publication_id
 	  	 SET @totalCnt = @@ROWCOUNT
 	  	 INSERT INTO #ArticleList
 	  	 SELECT 
 	  	  	 p.name,
 	  	  	 A.name,
 	  	  	 A.dest_owner,
 	  	  	 A.dest_table
 	  	 FROM dbo.sysarticles A
 	  	 JOIN dbo.syspublications P ON P.pubid= A.pubid 
 	  	 WHere A.dest_table = @TableName
 	 END
 	 SELECT @CntPublication = count(0) FROM #tmpPublications
 	 SELECT @IsReplicationPresent = CASE WHEN EXISTS (SELECT 1 FROM master.sys.sysdatabases WHERE name='distribution') THEN 1 ELSE 0 END
 	 IF @IsReplicationPresent = 1 AND @CntPublication >0 
 	 BEGIN
 	  	 SELECT @DropArticleSQL = COALESCE(@DropArticleSQL+'', '')+ '
 	  	  	 EXEC sp_dropsubscription @publication = @PublicationName, @article = '''+[Article]+''' ,@subscriber = ''all'';
 	  	  	 EXEC sp_droparticle @publication = @PublicationName, @article = '''+[Article]+''',@force_invalidate_snapshot = 1;
 	  	  	 '
 	  	 FROM
 	  	 (SELECT DISTINCT [Article] FROM #ArticleList S WHERE source_object = 'CXS_Leaf')T
 	  	 SELECT @DropArticleSQL = 
 	  	 '
 	  	 Declare @Cnt int,@PublicationName varchar(200)
 	  	 SELECT @Cnt =1,@PublicationName=''''
 	  	 While @Cnt <='+Cast(@CntPublication AS varchar)+'
 	  	 Begin
 	  	  	 Select @PublicationName=  publication_name from #tmpPublications where SerialNo = @Cnt;
 	  	  	 '+ @DropArticleSQL+'
 	  	  	 EXEC sp_changepublication @publication = @PublicationName, @property = N''allow_anonymous'',@value = ''FALSE'';
 	  	  	 EXEC sp_changepublication @publication = @PublicationName,@property = N''immediate_sync'',@value = ''FALSE'';
 	  	  	 SET @Cnt = @Cnt+1
 	  	 End
 	  	 ' EXEC(@DropArticleSQL) 
 	 END
End
Select @HasClustered = 0
Select @DropNeeded = 0
Select @ColName1 = ''
Select @ColName2 = ''
Select @ColName3 = ''
Select @ColName4 = ''
Select @ColName5 = ''
Select @ColName6 = ''
Select @ColName7 = ''
Select @ColName8 = ''
Select @ColName9 = ''
Select @ColName10 = ''
SELECT @TableName = 'dbo.' + @TableName
Select @TableId = NULL
Select @TableId = object_id(@TableName) 
If (@TableId Is NULL)
  Begin
    Select @Msg = '-- Warning: Could Not Add [' + @TrueKeyType + '] [' + @TrueKeyName + '] Table [' + @TableName + '] Missing'
    Print @Msg
    Return
  End
IF (@TrueKeyName LIKE '%History_PK_Id') AND (@TrueKeyType = 'Primary Key')
BEGIN
 	 IF Not EXISTS(SELECT 1 FROM sys.syscolumns WHERE id = @TableId and name = @TrueColName1)
 	 RETURN
END
If (@TrueKeyType = 'Check Constraint')
  Begin
 	  	 DECLARE @dboTrueKeyName VarChar(110)
 	  	 SELECT @dboTrueKeyName = 'dbo.' + @TrueKeyName
    Select @Indid = NULL
 	  	 Select @Indid = object_id(@dboTrueKeyName) 
  End
Else
  Begin
    Select @Indid = NULL
    Select @Indid = Indid From sys.sysindexes where (Id = @TableId) And (Name = @TrueKeyName) And (IndId <> 255) And (IndId <> 0) And (substring(name,1,1) <> '_')
  End
If (@Indid Is Not NULL) And (@TrueKeyType = 'Check Constraint')
  Begin
    Select @ColName1 = text From sys.syscomments Where (Id = @Indid)
    If (Replace(@ColName1,' ','') = Replace(@TrueColName1,' ','')) or (Replace(Replace(Replace(@ColName1 ,' ',''),'(',''),')','') = Replace(Replace(Replace(@TrueColName1 ,' ',''),'(',''),')',''))
      Return
    Select @DropNeeded = 1
  End
If (@Indid Is Not NULL) And (@TrueKeyType <> 'Check Constraint')
  Begin
    Create Table #KeyColumns (ColumnName varchar(100), Pos int,IsDesc Int)
    Select @ClusterType = Case @Indid When 1 Then 'Clustered' Else 'NonClustered' End
    Select @xType = NULL
    Select @xType = xType From sys.sysobjects Where (Name = @TrueKeyName)
    Select @KeyType = 
      Case 
        When @xType Is NULL Then 'Index' 
        When @xType = 'PK' Then 'Primary Key' 
        When @xType = 'UQ' Then 'Unique Constraint' 
        Else 'Error' 
      End 
    Insert Into #KeyColumns (ColumnName,Pos,IsDesc)
 	  	 Select b.Name,a.Keyno,indexkey_property(c.id, a.indid, a.keyno, 'isdescending')
 	  	 from sys.sysindexkeys a
 	  	 Join sys.syscolumns b on (b.ColId = a.ColId) And (b.Id = @TableId)
   	  	 Join sys.sysindexes c on (c.id = a.id) and (c.indid = a.indid) and (c.Id > 255)
 	  	 where (a.id = @TableId) And (a.Indid = @Indid)
    Declare Col_Cursor INSENSITIVE CURSOR
      For (Select ColumnName,Pos,IsDesc From #KeyColumns)
      For Read Only
      Open Col_Cursor  
      Col_Loop:
        Fetch Next From Col_Cursor Into @ColName,@Pos,@IsDesc
        If (@@Fetch_Status = 0)
          Begin
 	  	  	  	 If @IsDesc = 1
 	  	  	  	  	 Select @ColName = @ColName + ' Desc'
            If (@Pos = 1) Select @ColName1 = @ColName
            If (@Pos = 2) Select @ColName2 = @ColName
            If (@Pos = 3) Select @ColName3 = @ColName
            If (@Pos = 4) Select @ColName4 = @ColName
            If (@Pos = 5) Select @ColName5 = @ColName
            If (@Pos = 6) Select @ColName6 = @ColName
            If (@Pos = 7) Select @ColName7 = @ColName
            If (@Pos = 8) Select @ColName8 = @ColName
            If (@Pos = 9) Select @ColName9 = @ColName
            If (@Pos = 10) Select @ColName10 = @ColName
            Goto Col_Loop
          End
    Close Col_Cursor 
    Deallocate Col_Cursor
    Drop Table #KeyColumns
    If (@TrueKeyType = @KeyType) And (@TrueClusterType = @ClusterType) And (@TrueColName1 = @ColName1) And (@TrueColName2 = @ColName2) And (@TrueColName3 = @ColName3) And (@TrueColName4 = @ColName4) And (@TrueColName5 = @ColName5) And (@TrueColName6 = @ColName6) And (@TrueColName7 = @ColName7) And (@TrueColName8 = @ColName8) And (@TrueColName9 = @ColName9) And (@TrueColName10 = @ColName10)
      Return
    Select @DropNeeded = 1
  End
Select @KeyName = @TrueKeyName
If (@DropNeeded <> 1)
  If (@TrueKeyType = 'Primary Key')
    Begin
      Select @Indid = NULL
      Select @Indid = Id, @KeyName = Name From sys.sysobjects where (Parent_Obj = @TableId) And (xType = 'PK')
      If (@Indid Is Not Null)
        Select @DropNeeded = 1
    End
--See if there is any maintenance scheduled for this key
Select @DBMC_Id = NULL,@DBMCGroup = Null
Select @DBMC_Id = DBMC_Id,@DBMCGroup = DBMC_Group
  From DB_Maintenance_Commands 
  Where DBMC_Type_Id = 1 and Object_Name = @KeyName and Executed_On is NULL and Pending_Check = 0
If @DBMC_Id is NOT NULL  
  Begin
  	  If (@DropNeeded = 1)
 	  	 Begin
 	  	   -- We know the current key doesn't match the proposed one BUT is this key in the DBMaint Table with an override? 
 	  	   -- if so, execute the old override. 
 	  	   if (Select count(*) From DB_Maintenance_Commands Where DBMC_Id = @DBMC_Id and Command_Override is NOT NULL) > 0
 	  	     Begin
 	  	       --Set this flag so we don't get caught in a loop
 	  	       Update DB_Maintenance_Commands Set Pending_Check = 1 Where DBMC_Id = @DBMC_Id
 	  	       Select @Command = REPLACE(Command_Override,'~','''') from DB_Maintenance_Commands Where DBMC_Id = @DBMC_Id
 	  	       Execute (@Command)
 	  	       Update DB_Maintenance_Commands Set Pending_Check = 0 Where DBMC_Id = @DBMC_Id
 	  	       Return
 	  	     End
 	  	 End
    else
      Begin
 	  	  Select  @HasClustered = OBJECTPROPERTY(@TableId,'TableHasClustIndex')
 	  	   If @HasClustered = 0 or  (@HasClustered = 1 and @TrueClusterType <>'Clustered') -- maintenance = clustered but have a clustered - leave in maintenance
 	  	    	  	 Update DB_Maintenance_Commands Set Executed_On = GETDATE() Where DBMC_Group = @DBMCGroup
 	  	 End
  End
IF @TrueKeyName = 'Test_UC_VaridResultonEventid'
BEGIN
 	 Select  @HasClustered = OBJECTPROPERTY(@TableId,'TableHasClustIndex')
 	 IF @HasClustered = 1
 	 BEGIN
 	  	 Select @Msg = '-- Warning: Could Not Add [' + @TrueKeyType + '] [' + @TrueKeyName + '] INDEX will not be canged on an upgrade'
 	  	 Print @Msg
 	  	 Return
 	 END
END
-- Check To See if a key exists but with a different name 
--  If so, rename the key and set @AddNeeded = 0
Declare @Computed Int
Select @Computed = iscomputed From sys.syscolumns where id = @TableId and name = @TrueColName1
If @Computed = 0 and (@TrueColName2 <> '')  Select @Computed = iscomputed From sys.syscolumns where id = @TableId and name = @TrueColName2
If @Computed = 0 and (@TrueColName3 <> '')  Select @Computed = iscomputed From sys.syscolumns where id = @TableId and name = @TrueColName3
If @Computed = 0 and (@TrueColName4 <> '')  Select @Computed = iscomputed From sys.syscolumns where id = @TableId and name = @TrueColName4
If @Computed = 0 and (@TrueColName5 <> '')  Select @Computed = iscomputed From sys.syscolumns where id = @TableId and name = @TrueColName5
If @Computed = 0 and (@TrueColName6 <> '')  Select @Computed = iscomputed From sys.syscolumns where id = @TableId and name = @TrueColName6
If @Computed = 0 and (@TrueColName7 <> '')  Select @Computed = iscomputed From sys.syscolumns where id = @TableId and name = @TrueColName7
If @Computed = 0 and (@TrueColName8 <> '')  Select @Computed = iscomputed From sys.syscolumns where id = @TableId and name = @TrueColName8
If @Computed = 0 and (@TrueColName9 <> '')  Select @Computed = iscomputed From sys.syscolumns where id = @TableId and name = @TrueColName9
If @Computed = 0 and (@TrueColName10 <> '') Select @Computed = iscomputed From sys.syscolumns where id = @TableId and name = @TrueColName10
if @Computed = 1 select @DropNeeded = 0
If (@DropNeeded = 1)
  Begin
       Declare fkCursor Cursor
 	   For select s1.name,s.Name from sys.sysobjects s
 	    Join sys.sysobjects s1 On S1.Id = s.parent_obj
 	    where s.id in (select distinct constid from sys.sysforeignkeys where  rkeyid  = @TableId)
           For Read Only
 	    OPEN fkCursor
         Loop:
   	  FETCH NEXT FROM fkCursor INTO @TableName2,@KeyName2
 	  If @@Fetch_Status = 0
            Begin
 	       Select @Statement = 'ALTER TABLE dbo.' + @TableName2 + ' DROP CONSTRAINT ' + @KeyName2
 	       Execute(@Statement)
 	       Goto Loop
 	     End
 	 Close fkCursor
 	 Deallocate fkCursor
    If (@KeyType = 'Index')
  	 Select @Statement = 'DROP Index ' + @TableName + '.' + @TrueKeyName
    Else
      Select @Statement = 'ALTER TABLE ' + @TableName + ' DROP CONSTRAINT ' + @KeyName
    Execute (@Statement)
    Select @Msg = 'Dropped [' + @KeyType + '] [' + @KeyName + '] [' + @TableName + ']'
    Print @Msg
  End
Select @AddNeeded = 1
if @Computed = 1 select @AddNeeded = 0
If (@AddNeeded = 1)
  Begin
    Select @Statement = ''
    If (@TrueKeyType = 'Primary Key')
      Select @Statement = 'Alter Table ' + @Tablename + ' WITH NOCHECK ADD CONSTRAINT ' + @TrueKeyName + ' PRIMARY KEY ' + @TrueClusterType + ' ('
    If (@TrueKeyType = 'Index')
      Select @Statement = 'Create ' + @TrueUniqueType + ' ' + @TrueClusterType + ' INDEX ' + @TrueKeyName + ' ON ' + @TableName + ' ('
    If (@TrueKeyType = 'Unique Constraint')
      Select @Statement = 'Alter Table ' + @Tablename + ' WITH NOCHECK ADD CONSTRAINT ' + @TrueKeyName + ' UNIQUE ' + @TrueClusterType + ' ('
    If (@TrueKeyType = 'Check Constraint')
      Select @Statement = 'Alter Table ' + @Tablename + ' WITH NOCHECK ADD CONSTRAINT ' + @TrueKeyName + ' CHECK ' + @TrueColName1
    If (@Statement <> '')
      Begin
        If (@TrueKeyType <> 'Check Constraint')
          Begin
            Select @Statement = @Statement + @TrueColName1
            If (@TrueColName2 <> '') Select @Statement = @Statement + ',' + @TrueColName2
            If (@TrueColName3 <> '') Select @Statement = @Statement + ',' + @TrueColName3
            If (@TrueColName4 <> '') Select @Statement = @Statement + ',' + @TrueColName4
            If (@TrueColName5 <> '') Select @Statement = @Statement + ',' + @TrueColName5
            If (@TrueColName6 <> '') Select @Statement = @Statement + ',' + @TrueColName6
            If (@TrueColName7 <> '') Select @Statement = @Statement + ',' + @TrueColName7
            If (@TrueColName8 <> '') Select @Statement = @Statement + ',' + @TrueColName8
            If (@TrueColName9 <> '') Select @Statement = @Statement + ',' + @TrueColName9
            If (@TrueColName10 <> '') Select @Statement = @Statement + ',' + @TrueColName10
            Select @Statement = @Statement + ')'
          End
 	  	  	 Select  @HasClustered = OBJECTPROPERTY(@TableId,'TableHasClustIndex')
 	  	  	 If @HasClustered = 0 or @TrueClusterType <> 'Clustered' -- do not try to add a second clustered index
 	  	  	   Begin
         	  	 Execute (@Statement)
         	  	 Select @Msg = 'Added [' + @TrueKeyType + '] [' + @TrueKeyName + '] [' + @TableName + ']'
         	  	 Print @Msg
 	  	  	   End
      End
    Else
      Begin
        Select @Msg = 'Invalid Key Type [' + @TrueKeyType + '] [' + @TrueKeyName + '] [' + @TableName + ']'
        Print @Msg
      End
  End
IF @IsReplicationPresent = 1 AND @CntPublication >0 AND EXISTS(select 1 from #ArticleList Where source_owner+'.'+source_object =@TableName)
Begin
 	 SELECT @AddArticleSQL = COALESCE(@AddArticleSQL+'', '')+ 'EXEC sp_addarticle @publication =@PublicationName1, @article = '''+[Article]+''' ,@source_object =N'''+[Table]+''',@source_owner = N'''+[Schema]+''', @destination_owner = N'''+[Schema]+''',@destination_table = N'''+[Table]+''',@force_invalidate_snapshot=1'
 	 FROM
 	 (
 	  	 SELECT 
 	  	  	 DISTINCT A.[name] [Table],
 	  	  	 c.[name] [Schema],
 	  	  	 [Article],
 	  	  	 publication
 	  	 FROM 
 	  	  	 sys.tables A
 	  	  	 JOIN sys.schemas c ON c.schema_id = A.schema_id
 	  	  	 JOIN #ArticleList S ON S.source_object= A.[name]
 	  	  	 AND S.source_owner = c.[name]
 	 )T
 	 WHERE 
 	  	 T.[Schema]+'.'+T.[Table] =  @TableName
 	 SELECT @AddArticleSQL= 
 	 '
 	 Declare @Cnt1 int,@PublicationName1 varchar(200)
 	 SELECT @Cnt1 =1,@PublicationName1=''''
 	 While @Cnt1 <='+Cast(@CntPublication AS varchar)+'
 	 Begin
 	  	  	 Select @PublicationName1=  publication_name from #tmpPublications where SerialNo = @Cnt1
 	  	  	 '+@AddArticleSQL+'
 	  	  	 EXEC sp_refreshsubscriptions @publication = @PublicationName1
 	  	  	 EXEC sp_changepublication @publication = @PublicationName1,@property = N''immediate_sync'',@value = ''TRUE''
 	  	  	 EXEC sp_changepublication @publication = @PublicationName1,@property = N''allow_anonymous'',@value = ''TRUE''
 	  	 SET @Cnt1 = @Cnt1+1
 	 End' 
 	 EXEC (@AddArticleSQL)
End
Drop table #tmpPublications;
Drop TABLE #ArticleList;
