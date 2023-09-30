Create Procedure [dbo].[spRS_IEScriptReportWebPage]
 	 @RWP_Id int
AS
-------------------
-- Local Variables
-------------------
Declare @File_Name VarChar(255)
Declare @MaxIdentity int
Declare @MyId int
Declare @RP_Name  varchar(50) -- Report Parameter Name
--------------------
-- Initialize
--------------------
Select @MaxIdentity = 23
Select @File_Name = File_Name From Report_Webpages Where RWP_Id = @RWP_Id
Create Table #t(
 	 Id int NOT NULL IDENTITY (1, 1),
 	 Data varchar(8000)
)
/*
NOTE: The Report_Parameters used by this web page must already be in place on the target system!
*/
If @RWP_Id <= @MaxIdentity
 	 Begin
 	  	 Insert Into #t(Data) Values('If (Select Count(RWP_ID) From Report_WebPages Where File_Name = ' + '''' + @File_Name + '''' + ') = 0 ')
 	  	 Insert Into #t(Data) Values('  Begin')
 	  	 Insert Into #t(Data) Values('    Set Identity_Insert Report_WebPages On')
 	  	 Insert Into #t(Data)
 	  	 Select '    Insert Into Report_WebPages(RWP_Id, File_Name, Title, Version, Detail_Desc, Tab_Title, Comment_Id, Prompt1, Prompt2, Prompt3, Prompt4, Prompt5) Values(' +
 	  	  	 Convert(VarChar(5), RWP_Id) + ', ' +
 	  	  	 '''' + File_Name + '''' + ', ' +
 	  	  	 '''' + Title + '''' + ', ' +
 	  	  	 Case when Version is null then ' null' else convert(varchar(255), + '''' + Version + '''') end + ',' +
 	  	  	 Case when Detail_Desc is null then ' null' else convert(varchar(255), + '''' + Detail_Desc + '''') end + ',' +
 	  	  	 Case when Tab_Title is null then ' null' else convert(varchar(255), + '''' + Tab_Title + '''') end +  ',' +
 	  	  	 Case when Comment_Id is null then ' null' else convert(varchar(255), + '''' + Comment_Id + '''') end + ',' +
 	  	  	 Case when Prompt1 is null then ' null' else convert(varchar(255), + '''' + Prompt1 + '''') end + ',' +
 	  	  	 Case when Prompt2 is null then ' null' else convert(varchar(255), + '''' + Prompt2 + '''') end + ',' +
 	  	  	 Case when Prompt3 is null then ' null' else convert(varchar(255), + '''' + Prompt3 + '''') end + ',' +
 	  	  	 Case when Prompt4 is null then ' null' else convert(varchar(255), + '''' + Prompt4 + '''') end + ',' +
 	  	  	 Case when Prompt5 is null then ' null' else convert(varchar(255), + '''' + Prompt5 + '''') end + ')'
 	  	  	 From Report_WebPages
 	  	  	 Where RWP_Id = @RWP_Id
 	  	 Insert Into #t(Data) Values('    Set Identity_Insert Report_WebPages Off')
 	  	 Insert Into #t(Data) Values('  END') 	  	 
 	  	 Insert Into #t(Data) Values('ELSE') 	  	 
 	  	 Insert Into #t(Data) Values('  BEGIN') 	  	 
 	  	 Insert Into #t(Data)
 	  	 Select '    Update Report_WebPages Set ' +
 	  	  	 'File_Name = ' + '''' + File_Name + '''' + ', ' +
 	  	  	 'Title = ' + '''' + Title + '''' + ', ' +
 	  	  	 'Version = ' + Case when Version is null then ' null' else convert(varchar(255), + '''' + Version + '''') end + ', ' +
 	  	  	 'Detail_Desc = ' + Case when Detail_Desc is null then ' null' else convert(varchar(255), + '''' + Detail_Desc + '''') end + ', ' +
 	  	  	 'Tab_Title = ' + Case when Tab_Title is null then ' null' else convert(varchar(255), + '''' + Tab_Title + '''') end +  ', ' +
 	  	  	 'Comment_Id = ' + Case when Comment_Id is null then ' null' else convert(varchar(255), + '''' + Comment_Id + '''') end + ', ' +
 	  	  	 'Prompt1 = ' + Case when Prompt1 is null then ' null' else convert(varchar(255), + '''' + Prompt1 + '''') end + ', ' +
 	  	  	 'Prompt2 = ' + Case when Prompt2 is null then ' null' else convert(varchar(255), + '''' + Prompt2 + '''') end + ', ' +
 	  	  	 'Prompt3 = ' + Case when Prompt3 is null then ' null' else convert(varchar(255), + '''' + Prompt3 + '''') end + ', ' +
 	  	  	 'Prompt4 = ' + Case when Prompt4 is null then ' null' else convert(varchar(255), + '''' + Prompt4 + '''') end + ', ' +
 	  	  	 'Prompt5 = ' + Case when Prompt5 is null then ' null' else convert(varchar(255), + '''' + Prompt5 + '''') end + ' ' +
 	  	  	 'Where File_Name = ' + '''' + @File_Name + ''''
 	  	  	 From Report_WebPages
 	  	  	 Where RWP_Id = @RWP_Id
 	  	 Insert Into #t(Data) Values('  END')
 	 End
Else
 	 Begin
 	  	 Insert Into #t(Data)
 	  	 Select 'If (Select Count(RWP_ID) From Report_WebPages Where File_Name = ' + '''' + @File_Name + '''' + ') = 0 ' +
 	  	 'BEGIN ' + 
 	  	  	 'Insert Into Report_WebPages(File_Name, Title, Version, Detail_Desc, Tab_Title, Comment_Id, Prompt1, Prompt2, Prompt3, Prompt4, Prompt5) Values(' +
 	  	  	 '''' + File_Name + '''' + ', ' +
 	  	  	 '''' + Title + '''' + ', ' +
 	  	  	 Case when Version is null then ' null' else convert(varchar(255), + '''' + Version + '''') end + ',' +
 	  	  	 Case when Detail_Desc is null then ' null' else convert(varchar(255), + '''' + Detail_Desc + '''') end + ',' +
 	  	  	 Case when Tab_Title is null then ' null' else convert(varchar(255), + '''' + Tab_Title + '''') end +  ',' +
 	  	  	 Case when Comment_Id is null then ' null' else convert(varchar(255), + '''' + Comment_Id + '''') end + ',' +
 	  	  	 Case when Prompt1 is null then ' null' else convert(varchar(255), + '''' + Prompt1 + '''') end + ',' +
 	  	  	 Case when Prompt2 is null then ' null' else convert(varchar(255), + '''' + Prompt2 + '''') end + ',' +
 	  	  	 Case when Prompt3 is null then ' null' else convert(varchar(255), + '''' + Prompt3 + '''') end + ',' +
 	  	  	 Case when Prompt4 is null then ' null' else convert(varchar(255), + '''' + Prompt4 + '''') end + ',' +
 	  	  	 Case when Prompt5 is null then ' null' else convert(varchar(255), + '''' + Prompt5 + '''') end + 
 	  	  	 ') END ELSE BEGIN '  +
 	  	  	 ' UPDATE Report_WebPages SET ' + 
 	  	  	 ' Title = ' + '''' + Title + '''' + ', ' +
 	  	  	 ' Version = ' + Case when Version is null then ' null' else convert(varchar(255), + '''' + Version + '''') end + ',' +
 	  	  	 ' Detail_Desc = ' + Case when Detail_Desc is null then ' null' else convert(varchar(255), + '''' + Detail_Desc + '''') end + ',' +
 	  	  	 ' Tab_Title = ' + Case when Tab_Title is null then ' null' else convert(varchar(255), + '''' + Tab_Title + '''') end +  ',' +
 	  	  	 ' Comment_Id = ' + Case when Comment_Id is null then ' null' else convert(varchar(255), + '''' + Comment_Id + '''') end + ',' +
 	  	  	 ' Prompt1 = ' + Case when Prompt1 is null then ' null' else convert(varchar(255), + '''' + Prompt1 + '''') end + ',' +
 	  	  	 ' Prompt2 = ' + Case when Prompt2 is null then ' null' else convert(varchar(255), + '''' + Prompt2 + '''') end + ',' +
 	  	  	 ' Prompt3 = ' + Case when Prompt3 is null then ' null' else convert(varchar(255), + '''' + Prompt3 + '''') end + ',' +
 	  	  	 ' Prompt4 = ' + Case when Prompt4 is null then ' null' else convert(varchar(255), + '''' + Prompt4 + '''') end + ',' +
 	  	  	 ' Prompt5 = ' + Case when Prompt5 is null then ' null' else convert(varchar(255), + '''' + Prompt5 + '''') end + 
 	  	  	 ' WHERE File_Name = ' + '''' + @File_Name + '''' +
 	  	  	 ' END'
 	  	   FROM Report_WebPages RP Where RP.File_Name = @File_Name
 	 End
------------------------------------'
-- Verifying Webpage Parameters'
------------------------------------'
Insert Into #t(Data) Select '------------------------------------'
Insert Into #t(Data) Select '-- Verifying Webpage Parameters'
Insert Into #t(Data) Select '------------------------------------'
Declare ParameterCursor INSENSITIVE CURSOR
  For (
 	  	 Select rwp.rp_Id, rp.rp_Name from report_webpage_parameters rwp
 	  	 Join report_Parameters rp on rp.rp_Id = rwp.rp_Id
 	  	 where rwp.rwp_Id = @RWP_Id
      )
  For Read Only
  Open ParameterCursor  
BeginLoopParameters:
  Fetch Next From ParameterCursor Into @MyId, @RP_Name
  If (@@Fetch_Status = 0)
    Begin 
        Insert Into #t(Data)
 	  	 Select 'Exec spRS_IEAddWebPageParameter ' + '''' + @File_Name + '''' + ', ' + '''' + @RP_Name + ''''
      Goto BeginLoopParameters
    End 
  Else 
    goto EndLoopParameters
EndLoopParameters:
Close ParameterCursor
Deallocate ParameterCursor
------------------------------------'
-- Verifying Webpage Dependencies'
------------------------------------'
Insert Into #t(Data) Select '------------------------------------'
Insert Into #t(Data) Select '-- Verifying Webpage Dependencies'
Insert Into #t(Data) Select '------------------------------------'
Declare @RDT_Id 	 int
Declare @Value varchar(255)
Declare DependencyCursor INSENSITIVE CURSOR
  For (
 	  	 Select RDT_Id, Value From Report_WebPage_Dependencies 
 	  	 Where rwp_Id = @RWP_Id
      )
  For Read Only
  Open DependencyCursor  
BeginLoopDependency:
  Fetch Next From DependencyCursor Into @RDT_Id, @Value
  If (@@Fetch_Status = 0)
    Begin 
        Insert Into #t(Data)
 	  	 Select 'Exec spRS_IEAddWebPageDependency ' + '''' + @File_Name + '''' + ', ' + '''' + @Value + '''' + ', ' +  Convert(Varchar(2), @RDT_Id) 
      Goto BeginLoopDependency
    End 
  Else 
    goto EndLoopDependency
EndLoopDependency:
Close DependencyCursor
Deallocate DependencyCursor
Select Data From #t order by id
Drop Table #t
