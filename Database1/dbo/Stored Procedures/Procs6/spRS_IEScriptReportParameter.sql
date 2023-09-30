Create Procedure [dbo].[spRS_IEScriptReportParameter]
 	 @RP_Id int
AS
Declare @MaxIdentity int
Select @MaxIdentity = 72
/*
-- Input Stuff
Declare @RP_Id int
Declare @Identity bit
Select @RP_Id = -17
Select @Identity = 1
*/
------------------------
-- Local Vars
Declare @RP_Name VarChar(50)
Select @RP_Name = RP_Name From Report_Parameters Where RP_Id = @RP_Id
Create Table #t(
 	 Id int NOT NULL IDENTITY (1, 1),
 	 Data varchar(8000)
)
 	  	  	  	  	   
If @RP_Id <= @MaxIdentity
 	 Begin
 	  	 Insert Into #t(Data)
 	  	 Select 'If (Select Count(RP_ID) From Report_Parameters Where RP_Id = ' + convert(varchar(3), @RP_Id) + ') = 0 ' 
 	  	 
 	  	 Insert Into #t(Data) Values('  BEGIN ')
 	  	 Insert Into #t(Data) Values('    Set Identity_Insert Report_Parameters On')
 	  	 Insert Into #t(Data) 
 	  	  	 Select
 	  	  	 '      Insert Into Report_Parameters (RP_Id, RP_Name, RPT_Id, RPG_Id, Description, Default_Value, Is_Default, spName, MultiSelect) values (' + 
 	  	  	 CONVERT(varchar(5), RP_Id) + ', ' +
 	  	  	 '''' + RP_Name + '''' + ',' + 
 	  	  	 CONVERT(varchar(5), RPT_Id) + ',' +
 	  	  	 CASE WHEN RPG_Id IS NULL THEN ' NULL' ELSE CONVERT(varchar(5), RPG_Id) END + ',' +
 	  	  	 CASE WHEN Description IS NULL THEN ' NULL' ELSE CONVERT(varchar(255), '''' + Description + '''') END + ',' +
 	  	  	 CASE WHEN Default_Value IS NULL THEN ' NULL' ELSE CONVERT(varchar(255), '''' + Default_Value + '''') END + ',' +
 	  	  	 CONVERT(varchar(5), Is_Default) + ',' +  
 	  	  	 CASE WHEN spName IS NULL THEN ' NULL' ELSE CONVERT(varchar(50), '''' + spName + '''') END + ',' +
 	  	  	 CASE WHEN MultiSelect IS NULL THEN ' NULL' ELSE CONVERT(varchar(5), MultiSelect) END + ')'
 	  	   FROM report_parameters RP Where RP.RP_Id = @RP_Id
 	  	 Insert Into #t(Data) Values('    Set Identity_Insert Report_Parameters Off')
 	  	 Insert Into #t(Data) Select ('  END ')
 	  	 Insert Into #t(Data) Select ('ELSE ')
 	  	 Insert Into #t(Data) Select ('  BEGIN ')
 	  	 Insert Into #t(Data) 
 	  	  	 Select
 	  	  	 '    UPDATE Report_Parameters SET ' + 
 	  	  	 ' RPT_Id = ' + CONVERT(varchar(5), RPT_Id) + ',' +
 	  	  	 ' RPG_id = ' + CASE WHEN RPG_id IS NULL THEN ' NULL' ELSE CONVERT(varchar(5),RPG_id) END + ',' +
 	  	  	 ' Description = ' + CASE WHEN Description IS NULL THEN ' NULL' ELSE CONVERT(varchar(255), '''' + Description + '''') END + ',' +
 	  	  	 ' Default_Value = ' + CASE WHEN Default_Value IS NULL THEN ' NULL' ELSE CONVERT(varchar(255), '''' + Default_Value + '''') END + ',' +
 	  	  	 ' Is_Default = ' + CONVERT(varchar(5), Is_Default) + ',' +  
 	  	  	 ' spName = ' + CASE WHEN spName IS NULL THEN ' NULL' ELSE CONVERT(varchar(50), '''' + spName + '''') END + ',' +
 	  	  	 ' MultiSelect = ' + CASE WHEN MultiSelect IS NULL THEN ' NULL' ELSE CONVERT(varchar(5), MultiSelect) END +
 	  	  	 ' WHERE RP_ID = ' + CONVERT(VARCHAR(5), @RP_Id)
 	  	   FROM report_parameters RP Where RP.RP_Id = @RP_Id
 	  	 Insert Into #t(Data) Select ('  END ')
 	 End
Else
 	 Begin
 	  	 Insert Into #t(Data)
 	  	 Select 'If (Select Count(RP_ID) From Report_Parameters Where RP_Name = ' + '''' + @RP_Name + '''' + ') = 0 '
 	  	 Insert Into #t(Data) Values('  BEGIN ')
 	  	 Insert Into #t(Data)
 	  	 SELECT '    Insert Into Report_Parameters (RP_Name, RPT_Id, RPG_Id, Description, Default_Value, Is_Default, spName, MultiSelect) Values (' + 
 	  	  	 '''' + RP_Name + '''' + ',' + 
 	  	  	 CONVERT(varchar(5), RPT_Id) + ',' +
 	  	  	 CASE WHEN RPG_Id IS NULL THEN ' NULL' ELSE CONVERT(varchar(5), RPG_Id) END + ',' +
 	  	  	 CASE WHEN Description IS NULL THEN ' NULL' ELSE CONVERT(varchar(255), '''' + Description + '''') END + ',' +
 	  	  	 CASE WHEN Default_Value IS NULL THEN ' NULL' ELSE CONVERT(varchar(255), '''' + Default_Value + '''') END + ',' +
 	  	  	 CONVERT(varchar(5), Is_Default) + ',' +  
 	  	  	 CASE WHEN spName IS NULL THEN ' NULL' ELSE CONVERT(varchar(50), '''' + spName + '''') END + ',' +
 	  	  	 CASE WHEN MultiSelect IS NULL THEN ' NULL' ELSE CONVERT(varchar(5), MultiSelect) END + ')'
        FROM report_parameters RP Where RP.RP_Id = @RP_Id
 	  	 Insert Into #t(Data) Values('  END ')
 	  	 Insert Into #t(Data) Values('ELSE ')
 	  	 Insert Into #t(Data) Values('  BEGIN ')
 	  	 Insert Into #t(Data) 
 	  	 SELECT 	 '    UPDATE Report_Parameters SET ' + 
 	  	  	 ' RPT_Id = ' + CONVERT(varchar(5), RPT_Id) + ',' +
 	  	  	 ' RPG_id = ' + CASE WHEN RPG_id IS NULL THEN ' NULL' ELSE CONVERT(varchar(5),RPG_id) END + ',' +
 	  	  	 ' Description = ' + CASE WHEN Description IS NULL THEN ' NULL' ELSE CONVERT(varchar(255), '''' + Description + '''') END + ',' +
 	  	  	 ' Default_Value = ' + CASE WHEN Default_Value IS NULL THEN ' NULL' ELSE CONVERT(varchar(255), '''' + Default_Value + '''') END + ',' +
 	  	  	 ' Is_Default = ' + CONVERT(varchar(5), Is_Default) + ',' +  
 	  	  	 ' spName = ' + CASE WHEN spName IS NULL THEN ' NULL' ELSE CONVERT(varchar(50), '''' + spName + '''') END + ',' +
 	  	  	 ' MultiSelect = ' + CASE WHEN MultiSelect IS NULL THEN ' NULL' ELSE CONVERT(varchar(5), MultiSelect) END +
 	  	  	 ' WHERE RP_Name = ' + '''' + @RP_Name + ''''
 	  	   FROM report_parameters RP Where RP.RP_Id = @RP_Id
 	  	 Insert Into #t(Data) Values('  END ')
 	 End
Insert Into #t(Data) Select ('  ---------- ')
Select Data From #t order by id
Drop Table #t
