-- spEM_IEGetExportData 'DisplayPaths',0
CREATE PROCEDURE [dbo].[spEM_IEGetExportData_Bak_177] 
  @DataType    nVarChar(100),
  @QueryType Int = 1,
  @Id 	  	  Int = null,
  @StartTime DateTime = null,
  @EndTime 	  DateTime = null,
  @SearchString nvarchar(1000) = N''
  AS
IF @DataType != 'UserDefinedProperty'
BEGIN
 	 If @SearchString = '*'
 	   SELECT @SearchString = ''
 	 SELECT @SearchString = replace(@SearchString,'*','%')
 	 If @SearchString <> '' and charindex(@SearchString,'%') = 0
 	  	 SELECT @SearchString = '%' + @SearchString + '%'
END
SELECT @QueryType = coalesce(@QueryType,1)
Declare @Comment nvarchar(255),
 	  	 @CommentPart nVarChar(100),
 	  	 @SQL 	 varchar(max),
 	  	 @Now 	 nvarchar(25),
 	  	 @PreFixLen varchar(5)
SELECT @Now = '''' + Convert(nvarchar(25),dbo.fnServer_CmnGetDate(getUTCdate()),120) + ''''
Create Table #ExportColumnNames(Column_Name nVarChar(100),Comment nvarchar(1000),Trans Bit,firstcol Int,Is_Text tinyint,ExcelDateFormat nVarChar(25), SerialNo Int )
INSERT INTO #ExportColumnNames(Column_Name,Comment,Trans,firstcol,Is_Text,ExcelDateFormat,SerialNo)  	 Execute spEM_IEGetColumnData @DataType
SELECT Column_Name,Comment,Trans,firstcol,Is_Text,ExcelDateFormat FROM #ExportColumnNames Order by SerialNo
drop table #ExportColumnNames
If @DataType = 'Variables' /*ECR #28428  add child variable data */
BEGIN  /***** Variables_Base   *****/
 	 SELECT @SQL = '
CREATE TABLE #Vars([Var_Id] [int]   NULL ,[ArrayStatOnly] [tinyint] NULL,[Calculation_Id] [int] NULL,[Comment_Id] [int] NULL,[Comparison_Operator_Id] [int] NULL,[Comparison_Value] [varchar](50) NULL,[CPK_SubGroup_Size] [int] NULL,[Data_Type_Id] [int]  NULL ,[Debug] [bit] NULL,[DQ_Tag] [nvarchar](255) NULL,[DS_Id] [int]  NULL ,[Eng_Units] [varchar](15) NULL,[Esignature_Level] [int] NULL,[Event_Dimension] [tinyint] NULL,[Event_Subtype_Id] [int] NULL,[Event_Type] [tinyint]  NULL ,[Extended_Info] [nvarchar](255) NULL,[Extended_Test_Freq] [int] NULL,[External_Link] [nvarchar](255) NULL,[Force_Sign_Entry] [tinyint] NULL,[Group_Id] [int] NULL,[Ignore_Event_Status] [tinyint] NULL,[Input_Tag] [nvarchar](255) NULL,[Input_Tag2] [nvarchar](255) NULL,[Is_Active] [bit] NULL,[Is_Conformance_Variable] [bit]  NULL ,[LEL_Tag] [nvarchar](255) NULL,[LRL_Tag] [nvarchar](255) NULL,[LUL_Tag] [nvarchar](255) NULL,[LWL_Tag] [nvarchar](255) NULL,[Max_RPM] [float] NULL,[Output_DS_Id] [int] NULL,[Output_Tag] [nvarchar](255) NULL,[PEI_Id] [int] NULL,[Perform_Event_Lookup] [tinyint] NULL,[ProdCalc_Type] [tinyint] NULL,[PU_Id] [int]  NULL ,[PUG_Id] [int]  NULL ,[PUG_Order] [int]  NULL ,[PVar_Id] [int] NULL,[Rank] [smallint]   NULL ,[ReadLagTime] [int] NULL,[Reload_Flag] [tinyint] NULL,[Repeat_Backtime] [int] NULL,[Repeating] [tinyint] NULL,[Reset_Value] [float] NULL,[Retention_Limit] [int] NULL,[SA_Id] [tinyint]  NULL ,[Sampling_Interval] [smallint] NULL,[Sampling_Offset] [smallint] NULL,[Sampling_Reference_Var_Id] [int] NULL,[Sampling_Type] [tinyint] NULL,[Sampling_Window] [int] NULL,[ShouldArchive] [tinyint] NULL,[SPC_Calculation_Type_Id] [int] NULL,[SPC_Group_Variable_Type_Id] [int] NULL,[Spec_Id] [int] NULL,[String_Specification_Setting] [tinyint] NULL,[System] [tinyint] NULL,[Tag] [varchar](50) NULL,[Target_Tag] [nvarchar](255) NULL,[Test_Name] [varchar](50) NULL,[TF_Reset] [tinyint] NULL,[Tot_Factor] [real] NULL,[UEL_Tag] [nvarchar](255) NULL,[Unit_Reject] [bit]  NULL ,[Unit_Summarize] [bit]  NULL ,[URL_Tag] [nvarchar](255) NULL,[User_Defined1] [nvarchar](255) NULL,[User_Defined2] [nvarchar](255) NULL,[User_Defined3] [nvarchar](255) NULL,[UUL_Tag] [nvarchar](255) NULL,[UWL_Tag] [nvarchar](255) NULL,[Var_Desc] [nvarchar](255)  NULL ,[Var_Desc_Global] [varchar](50) NULL,[Var_Precision] [tinyint] NULL,[Var_Reject] [bit]  NULL ,[Write_Group_DS_Id] [int] NULL,Pu_desc nvarchar(50), pl_desc nvarchar(50), dept_Desc nvarchar(50),DS_Desc nvarchar(50), Ds_Desc1 nvarchar(50), Pu_Order Int, Group_Desc nvarchar(50),SPC_Calculation_Type_Desc nvarchar(50),ED_Desc nvarchar(50),Event_Subtype_Desc nvarchar(50),SPC_Group_Variable_Type_Desc nvarchar(50),Input_Name nvarchar(50))  
CREATE TABLE #PVars([Var_Id] [int]   NULL ,[Var_Desc] [nvarchar](255)  NULL ,[PU_Id] [int]  NULL,[Write_Group_DS_Id] [int] NULL,Pu_desc nvarchar(50), pl_desc nvarchar(50), dept_Desc nvarchar(50))  
CREATE TABLE #SVars([Var_Id] [int]  NULL ,[Var_Desc] [nvarchar](255)  NULL ,[PU_Id] [int]  NULL,Pu_desc nvarchar(50), pl_desc nvarchar(50), dept_Desc nvarchar(50))  
;WITH CTE_Vars As(Select * from Variables_Base Where PVar_Id Is null and Pu_Id <> 0 And Isnull(system,0) =0'
 	 If @QueryType = 2 /* By Group */
 	  	 SELECT @SQL = @SQL + ' And PUG_Id = ' + Convert(nVarChar(10),@Id)
 	 ELSE If @QueryType = 3 /* By Unit */
 	  	 SELECT @SQL = @SQL + ' And PU_Id = ' + Convert(nVarChar(10),@Id)
Select @SQL = @SQL + '
UNION
Select * from Variables_Base a Where PVar_Id Is NOT null and Pu_Id <> 0 And Isnull(system,0) =0 AND Exists(Select 1 from Variables_Base Where Var_Id = a.PVar_Id)
'
  	  If @QueryType = 2 /* By Group */
  	    	  SELECT @SQL = @SQL + ' And PUG_Id = ' + Convert(nVarChar(10),@Id)
  	  ELSE If @QueryType = 3 /* By Unit */
  	    	  SELECT @SQL = @SQL + ' And PU_Id = ' + Convert(nVarChar(10),@Id)
 	 SELECT @SQL = @SQL + ')'
 	 SELECT @SQL = @SQL + '
INSERT INTO #Vars  (Var_Id, 	 ArrayStatOnly, 	 Calculation_Id, 	 Comment_Id, 	 Comparison_Operator_Id, 	 Comparison_Value, 	 CPK_SubGroup_Size, 	 Data_Type_Id, 	 Debug, 	 DQ_Tag, 	 DS_Id, 	 Eng_Units, 	 Esignature_Level, 	 Event_Dimension, 	 Event_Subtype_Id, 	 Event_Type, 	 Extended_Info, 	 Extended_Test_Freq, 	 External_Link, 	 Force_Sign_Entry, 	 Group_Id, 	 Input_Tag, 	 Input_Tag2, 	 Is_Active, 	 Is_Conformance_Variable, 	 LEL_Tag, 	 LRL_Tag, 	 LUL_Tag, 	 LWL_Tag, 	 Max_RPM, 	 Output_DS_Id, 	 Output_Tag, 	 PEI_Id, 	 Perform_Event_Lookup, 	 ProdCalc_Type, 	 PU_Id, 	 PUG_Id, 	 PUG_Order, 	 PVar_Id, 	 Rank, 	 ReadLagTime, 	 Reload_Flag, 	 Repeat_Backtime, 	 Repeating, 	 Reset_Value, 	 Retention_Limit, 	 SA_Id, 	 Sampling_Interval, 	 Sampling_Offset, 	 Sampling_Reference_Var_Id, 	 Sampling_Type, 	 Sampling_Window, 	 ShouldArchive, 	 SPC_Calculation_Type_Id, 	 SPC_Group_Variable_Type_Id, 	 Spec_Id, 	 String_Specification_Setting, 	 System, 	 Tag, 	 Target_Tag, 	 Test_Name, 	 TF_Reset, 	 Tot_Factor, 	 UEL_Tag, 	 Unit_Reject, 	 Unit_Summarize, 	 URL_Tag, 	 User_Defined1, 	 User_Defined2, 	 User_Defined3, 	 UUL_Tag, 	 UWL_Tag, 	 Var_Desc, 	 Var_Desc_Global, 	 Var_Precision, 	 Var_Reject, 	 Write_Group_DS_Id, 	 Ignore_Event_Status)
SELECT  Var_Id, 	 ArrayStatOnly, 	 v.Calculation_Id, 	 v.Comment_Id, 	 v.Comparison_Operator_Id, 	 Comparison_Value, 	 CPK_SubGroup_Size, 	 Data_Type_Id, 	 Debug, 	 DQ_Tag, 	 DS_Id, 	 Eng_Units, 	 Esignature_Level, 	 Event_Dimension, 	 Event_Subtype_Id, 	 Event_Type, 	 v.Extended_Info, 	 Extended_Test_Freq, 	 v.External_Link, 	 Force_Sign_Entry, 	 v.Group_Id, 	 Input_Tag, 	 Input_Tag2, 	 Is_Active, 	 Is_Conformance_Variable, 	 LEL_Tag, 	 LRL_Tag, 	 LUL_Tag, 	 LWL_Tag, 	 Max_RPM, 	 Output_DS_Id, 	 Output_Tag, 	 PEI_Id, 	 Perform_Event_Lookup, 	 ProdCalc_Type, 	 v.PU_Id, 	 PUG_Id, 	 PUG_Order, 	 PVar_Id, 	 Rank, 	 ReadLagTime, 	 Reload_Flag, 	 Repeat_Backtime, 	 Repeating, 	 Reset_Value, 	 Retention_Limit, 	 SA_Id, 	 Sampling_Interval, 	 Sampling_Offset, 	 Sampling_Reference_Var_Id, 	 Sampling_Type, 	 Sampling_Window, 	 ShouldArchive, 	 SPC_Calculation_Type_Id, 	 SPC_Group_Variable_Type_Id, 	 Spec_Id, 	 String_Specification_Setting, 	 System, 	 v.Tag, 	 Target_Tag, 	 Test_Name, 	 TF_Reset, 	 Tot_Factor, 	 UEL_Tag, 	 Unit_Reject, 	 Unit_Summarize, 	 URL_Tag, 	 v.User_Defined1, 	 v.User_Defined2, 	 v.User_Defined3, 	 UUL_Tag, 	 UWL_Tag, 	 Var_Desc, 	 Var_Desc_Global, 	 Var_Precision, 	 Var_Reject, 	 Write_Group_DS_Id, 	 Ignore_Event_Status
FROM CTE_Vars v'
 	 IF @QueryType in (4,5) 
 	  	 SELECT @SQL = @SQL + ' Join Prod_Units_Base pu On pu.PU_Id = v.PU_Id Join Prod_Lines_Base pl On Pl.PL_Id = pu.PL_Id'
 	 If @QueryType = 4 /* By Line */
 	  	 SELECT @SQL = @SQL + ' And pl.PL_Id = ' + Convert(nVarChar(10),@Id)
 	 If @QueryType = 5 /* By Department */
 	  	 SELECT @SQL = @SQL + ' Join Departments_Base d On d.Dept_Id = pl.Dept_Id And d.Dept_Id = ' + Convert(nVarChar(10),@Id)
 	 SELECT @SQL = @SQL + ' Left Join Calculations c On c.Calculation_Id = v.Calculation_Id'
 	 SELECT @SQL = @SQL + ' WHERE ((c.Calculation_Desc  Not In (''MSI_Calc_Downtime'',''MSI_Calc_Waste'',''MSI_Calc_Efficiency'',''MSI_Calc_Production'')) or c.Calculation_Desc is null )'
 	 --If @QueryType = 2 /* By Group */
 	 -- 	 SELECT @SQL = @SQL + ' And v.PUG_Id = ' + Convert(nVarChar(10),@Id)
 	 --ELSE If @QueryType = 3 /* By Unit */
 	 -- 	 SELECT @SQL = @SQL + ' And v.PU_Id = ' + Convert(nVarChar(10),@Id)
 	 --ELSE If @QueryType = 4 /* By Line */
 	 -- 	 SELECT @SQL = @SQL + ' And pl.PL_Id = ' + Convert(nVarChar(10),@Id)
 	 --ELSE If @QueryType = 5 /* By Department */
 	 -- 	 SELECT @SQL = @SQL + ' And d.Dept_Id = ' + Convert(nVarChar(10),@Id)
 	 SELECT @SQL = @SQL + '
Insert Into #PVars(Var_Id, Var_desc) Select Var_Id, Var_Desc from Variables_Base T Where exists (Select 1  From #Vars Where PVar_Id = T.Var_Id)  
Insert Into #SVars(Var_Id, Var_Desc,Pu_Id) Select Var_Id, Var_Desc,Pu_Id from Variables_Base T Where exists (Select 1  From #Vars Where Sampling_Reference_Var_Id = T.Var_Id);  
;WITH CTE_Prod_Units as (Select Pu_Id, pu.Pl_Id,Pu_Desc, ISNULL(Pu_Order,255) Pu_Order,Pl.Pl_desc, d.Dept_Desc from Prod_Units_Base Pu Join Prod_Lines_base Pl On Pl.Pl_id = Pu.pl_Id  join Departments_Base d on d.Dept_Id = Pl.Dept_Id )
UPDATE V SET V.Dept_Desc = C.Dept_Desc, V.PL_Desc = C.PL_Desc, V.Pu_desc = C.PU_Desc, V.Pu_Order  =  C.Pu_Order
FROM #Vars V Join CTE_Prod_Units C On C.Pu_Id =  V.Pu_Id
UPDATE V
SET V.Ds_desc = ds.DS_Desc
FROM #Vars V join Data_Source ds on ds.DS_Id = v.DS_Id
UPDATE V
SET V.Ds_desc1 = ds.DS_Desc
FROM #Vars V join Data_Source ds on ds.DS_Id = v.Write_Group_DS_Id
UPDATE V
SET V.Group_Desc = sg.Group_Desc
FROM #Vars V join Security_Groups sg on sg.Group_Id = v.Group_Id 
;WITH CTE_Prod_Units as (Select Pu_Id, pu.Pl_Id,Pu_Desc, ISNULL(Pu_Order,255) Pu_Order,Pl.Pl_desc, d.Dept_Desc from Prod_Units_Base Pu Join Prod_Lines_base Pl On Pl.Pl_id = Pu.pl_Id  join Departments_Base d on d.Dept_Id = Pl.Dept_Id )
UPDATE V SET V.Dept_Desc = C.Dept_Desc, V.PL_Desc = C.PL_Desc, V.Pu_desc = C.PU_Desc 
FROM #SVars V Join CTE_Prod_Units C On C.Pu_Id =  V.Pu_Id
UPDATE V
SET V.ED_Desc = ed.ED_Desc
FROM #Vars V
JOIN Event_Dimensions ed
ON ed.ED_Id = v.Event_Dimension
UPDATE V
SET V.Event_Subtype_Desc = es.Event_Subtype_Desc
FROM #Vars V
JOIN Event_Subtypes es
ON es.Event_Subtype_Id = v.Event_Subtype_Id
AND es.ET_Id = v.Event_Type
UPDATE V
SET V.SPC_Calculation_Type_Desc = sp.SPC_Calculation_Type_Desc
FROM #Vars V
JOIN SPC_Calculation_Types sp
ON sp.SPC_Calculation_Type_Id = v.SPC_Calculation_Type_Id
UPDATE V
SET V.SPC_Group_Variable_Type_Desc = sp2.SPC_Group_Variable_Type_Desc
FROM #Vars V
JOIN SPC_Group_Variable_Types sp2
ON sp2.SPC_Group_Variable_Type_Id = v.SPC_Group_Variable_Type_Id
UPDATE V
SET V.Input_Name = pi.Input_Name
FROM #Vars V
JOIN PrdExec_Inputs pi
ON pi.PEI_Id = v.PEI_Id
'
 	 
 	 --SELECT @SQL = @SQL + ' INSERT INTO @Vars(Var_Id,pug_Order)'
 	 --SELECT @SQL = @SQL + ' SELECT  v1.var_id,v2.pug_Order'
 	 --SELECT @SQL = @SQL + ' FROM Variables_Base   v1'
 	 --SELECT @SQL = @SQL + ' Join Variables_Base   v2 on v2.var_Id = v1.pvar_id'
 	 --SELECT @SQL = @SQL + ' Left Join Prod_Units_Base    pu On pu.PU_Id = v1.PU_Id'
 	 --SELECT @SQL = @SQL + ' Left Join Prod_Lines_Base pl On Pl.PL_Id = pu.PL_Id'
 	 --SELECT @SQL = @SQL + ' Left Join  Departments_Base  d On d.Dept_Id = pl.Dept_Id'
 	 --SELECT @SQL = @SQL + ' Left Join Calculations c On c.Calculation_Id = v1.Calculation_Id'
 	 --SELECT @SQL = @SQL + ' Where v1.PVar_Id is Not Null And v1.PU_Id <> 0 And (v1.system = 0 or v1.system Is Null) and ((c.Calculation_Desc  Not In (''MSI_Calc_Downtime'',''MSI_Calc_Waste'',''MSI_Calc_Efficiency'',''MSI_Calc_Production'')) or c.Calculation_Desc is null )'
 	 --If @QueryType = 2 /* By Group */
 	 -- 	 SELECT @SQL = @SQL + ' And v1.PUG_Id = ' + Convert(nVarChar(10),@Id)
 	 --ELSE If @QueryType = 3 /* By Unit */
 	 -- 	 SELECT @SQL = @SQL + ' And v1.PU_Id = ' + Convert(nVarChar(10),@Id)
 	 --ELSE If @QueryType = 4 /* By Line */
 	 -- 	 SELECT @SQL = @SQL + ' And pl.PL_Id = ' + Convert(nVarChar(10),@Id)
 	 --ELSE If @QueryType = 5 /* By Department */
 	 -- 	 SELECT @SQL = @SQL + ' And d.Dept_Id = ' + Convert(nVarChar(10),@Id)
 	 SELECT @SQL = @SQL + ' SELECT V.Dept_Desc,V.PL_Desc,V.PU_Desc,pug.PUG_Desc,v.Var_Desc,V.DS_Desc,V.DS_Desc1 DS_Desc,v.Eng_Units,et.ET_desc,dt.Data_Type_Desc,v.Sampling_Interval,'
 	 SELECT @SQL = @SQL + 'v.Sampling_Offset,st.ST_Desc,sa.SA_Desc,v.Var_Precision,CASE WHEN ISNULL(v.Output_Tag,'''') = '''' THEN v.Output_Tag ELSE dbo.fnEM_ConvertVarIdToTag(v.Output_Tag) END, 	 CASE WHEN ISNULL(v.Input_Tag,'''') = '''' THEN v.Input_Tag ELSE dbo.fnEM_ConvertVarIdToTag(v.Input_Tag) END, 	 CASE WHEN ISNULL(v.Input_Tag2,'''') = '''' THEN v.Input_Tag2 ELSE dbo.fnEM_ConvertVarIdToTag(v.Input_Tag2) END, 	 CASE WHEN ISNULL(v.DQ_Tag,'''') = '''' THEN v.DQ_Tag ELSE dbo.fnEM_ConvertVarIdToTag(v.DQ_Tag) END,'
 	 SELECT @SQL = @SQL +  ' 	 CASE WHEN ISNULL(v.URL_Tag,'''') = '''' THEN v.URL_Tag ELSE dbo.fnEM_ConvertVarIdToTag(v.URL_Tag) END, 	 CASE WHEN ISNULL(v.UWL_Tag,'''') = '''' THEN v.UWL_Tag ELSE dbo.fnEM_ConvertVarIdToTag(v.UWL_Tag) END, 	 CASE WHEN ISNULL(v.Target_Tag,'''') = '''' THEN v.Target_Tag ELSE dbo.fnEM_ConvertVarIdToTag(v.Target_Tag) END, 	 CASE WHEN ISNULL(v.LWL_Tag,'''') = '''' THEN v.LWL_Tag ELSE dbo.fnEM_ConvertVarIdToTag(v.LWL_Tag) END, 	 CASE WHEN ISNULL(v.LRL_Tag,'''') = '''' THEN v.LRL_Tag ELSE dbo.fnEM_ConvertVarIdToTag(v.LRL_Tag) END,v.Extended_Info,v.User_Defined1,v.User_Defined2,v.User_Defined3,pp.Prop_Desc + ''/'' + s.Spec_Desc,'
 	 -- ECR #29571 DQ Comparison Exports its ID instead of its description
 	 SELECT @SQL = @SQL + 'v.Sampling_Window,swt.Sampling_Window_Type_Name,v.Tot_Factor,co.Comparison_Operator_Value,v.Comparison_Value,'
 	 SELECT @SQL = @SQL + ' 	 CASE WHEN ISNULL(v.UEL_Tag,'''') = '''' THEN v.UEL_Tag ELSE dbo.fnEM_ConvertVarIdToTag(v.UEL_Tag) END, 	 CASE WHEN ISNULL(v.UUL_Tag,'''') = '''' THEN v.UUL_Tag ELSE dbo.fnEM_ConvertVarIdToTag(v.UUL_Tag) END, 	 CASE WHEN ISNULL(v.LUL_Tag,'''') = '''' THEN v.LUL_Tag ELSE dbo.fnEM_ConvertVarIdToTag(v.LUL_Tag) END, 	 CASE WHEN ISNULL(v.LEL_Tag,'''') = '''' THEN v.LEL_Tag ELSE dbo.fnEM_ConvertVarIdToTag(v.LEL_Tag) END,convert(bit,coalesce(v.Repeating,0)),v.Sampling_Interval,'
 	 SELECT @SQL = @SQL + 'v.TF_Reset,etf.Ext_Test_Freq_Desc,v.External_Link,V.Group_Desc,v.ShouldArchive,v.Max_RPM,v.Reset_Value,v.Is_Conformance_Variable,v.Esignature_Level,v.Event_Subtype_Desc,v.ED_Desc,'
 	 SELECT @SQL = @SQL + 'v.Input_Name,v.SPC_Calculation_Type_Desc,v.SPC_Group_Variable_Type_Desc,V1.PL_Desc,V1.PU_Desc,v1.Var_Desc, '
 	 SELECT @SQL = @SQL + 'v2.Var_Desc,v.Repeat_Backtime,convert(bit,coalesce(v.Force_Sign_Entry,0)),v.Test_Name,convert(bit,coalesce(v.ArrayStatOnly,0)),v.Rank,v.Unit_Reject,v.Unit_Summarize,v.Var_Reject, '
 	 SELECT @SQL = @SQL + 'Convert(Int,IsNull(v.CPK_SubGroup_Size,1)), String_Spec_Setting = Case When v.String_Specification_Setting = 1 Then ' + '''Not Equal'''
 	 SELECT @Sql = @Sql + ' When v.String_Specification_Setting = 2 THEN ' + '''Phrase Order''' 
 	 SELECT @Sql = @Sql + ' ELSE ' + '''Equal''' + ' END,v.ReadLagTime,convert(bit,coalesce(v.Perform_Event_Lookup,0)),convert(bit,coalesce(v.Ignore_Event_Status,0))'
 	 SELECT @SQL = @SQL + ' FROM #Vars   v'
 	 --SELECT @SQL = @SQL + ' Left Join Prod_Units_Base    pu On pu.PU_Id = v.PU_Id'
 	 SELECT @SQL = @SQL + ' Left Join PU_Groups pug On Pug.PUG_Id = v.PUG_Id'
 	 --SELECT @SQL = @SQL + ' Left Join Prod_Lines_Base pl On Pl.PL_Id = pu.PL_Id'
 	 --SELECT @SQL = @SQL + ' Left Join  Departments_Base  d On d.Dept_Id = pl.Dept_Id'
 	 SELECT @SQL = @SQL + ' Left Join Data_Type dt on dt.Data_Type_Id = v.Data_Type_Id'
 	 -- ECR #29571 DQ Comparison Exports its ID instead of its description
 	 SELECT @SQL = @SQL + ' Left Join Comparison_Operators co on co.Comparison_Operator_Id = v.Comparison_Operator_Id'
 	 SELECT @SQL = @SQL + ' Left Join Event_types et on et.ET_Id = v.Event_Type'
 	 --SELECT @SQL = @SQL + ' Left Join Data_Source ds on ds.DS_Id = v.DS_Id'
 	 SELECT @SQL = @SQL + ' Left Join Specifications s on s.Spec_Id = v.Spec_Id'
 	 SELECT @SQL = @SQL + ' Left Join Product_Properties pp on pp.Prop_Id = s.Prop_Id'
 	 SELECT @SQL = @SQL + ' Left Join Spec_Activations sa on sa.SA_Id = v.SA_Id'
 	 SELECT @SQL = @SQL + ' Left Join Extended_Test_Freqs etf on etf.Ext_Test_Freq_Id = v.Extended_Test_Freq'
 	 SELECT @SQL = @SQL + ' Left Join Sampling_Window_Types swt on swt.Sampling_Window_Type_Data = v.Sampling_Window'
 	 SELECT @SQL = @SQL + ' Left Join Sampling_Type st on st.ST_Id = v.Sampling_Type'
    --SELECT @SQL = @SQL + ' Left Join Event_Subtypes es on es.Event_Subtype_Id = v.Event_Subtype_Id and es.ET_Id = v.Event_Type'
 	 --SELECT @SQL = @SQL + ' Left Join Event_Dimensions ed on ed.ED_Id = v.Event_Dimension'
 	 --SELECT @SQL = @SQL + ' Left Join PrdExec_Inputs pi on pi.PEI_Id = v.PEI_Id'
 	 --SELECT @SQL = @SQL + ' Left Join SPC_Calculation_Types sp on sp.SPC_Calculation_Type_Id = v.SPC_Calculation_Type_Id'
 	 --SELECT @SQL = @SQL + ' Left Join SPC_Group_Variable_Types sp2 on sp2.SPC_Group_Variable_Type_Id = v.SPC_Group_Variable_Type_Id'
 	 SELECT @SQL = @SQL + ' Left Join  #SVars   v1 On v1.Var_Id = v.Sampling_Reference_Var_Id'
 	 --SELECT @SQL = @SQL + ' Left Join Prod_Units_Base    pu1 On pu1.PU_Id = v1.PU_Id'
 	 --SELECT @SQL = @SQL + ' Left Join Prod_Lines_Base pl1 On Pl1.PL_Id = pu1.PL_Id'
 	 SELECT @SQL = @SQL + ' Left Join  #PVars   v2 On v2.Var_Id = v.pVar_Id'
 	 --SELECT @SQL = @SQL + ' Left Join Data_Source ds2 on ds2.DS_Id = v.Write_Group_DS_Id'
 	 --SELECT @SQL = @SQL + ' Left Join Security_Groups sg on sg.Group_Id = v.Group_Id'
 	 --SELECT @SQL = @SQL + ' Left Join Calculations c On c.Calculation_Id = v.Calculation_Id'
 	 --SELECT @SQL = @SQL + ' Join @Vars tv on tv.Var_Id = v.Var_Id'
 	 SELECT @SQL = @SQL + ' Order by V.Dept_Desc,V.PL_Desc,V.PU_Order,V.PU_Desc,pug.PUG_Order,pug.PUG_Desc,v.pug_Order,v2.Var_Desc,v.Var_Desc'
 	 --SELECT @SQL
 	 Execute(@SQL)
  END /*****Variables********/
ELSE If @DataType = 'DataTypes'
 	 BEGIN
 	   SELECT Data_Type_Desc,Phrase_Value 
 	  	 FROM Phrase p
 	  	 Join Data_Type d on d.Data_Type_Id = p.Data_Type_Id
 	  	 Order by  Data_Type_Desc,Phrase_Order
 	 END
ELSE If @DataType = 'ProductionStatuses'
 	 BEGIN
 	   SELECT ProdStatus_Desc,Icon_Desc,Color_Desc,convert(bit,coalesce(Status_Valid_For_Input,0)),
 	  	 convert(bit,coalesce(Count_For_Inventory,0)),convert(bit,coalesce(Count_For_Production,0))
 	  	  FROM Production_Status ps
 	  	  Left Join Icons i On i.Icon_Id = ps.Icon_Id
 	  	  Left Join Colors c On c.Color_Id = ps.Color_Id
 	  	  order by  ProdStatus_Desc
 	 END
ELSE If @DataType = 'Users'
 	 BEGIN
 	   SELECT Username,User_Desc,'',Active,View_Desc,WindowsUserInfo,Role_Based_Security,Mixed_Mode_Login,SSOUserId,convert(bit,coalesce(UseSSO,0))
 	  	 FROM Users u
 	  	 Left Join Views v on v.View_Id = u.View_Id
 	    WHERE is_role = 0 and (User_Id > 50 or user_Id = 1) order by  Username
 	 END
ELSE If @DataType = 'UserGroups'
 	 BEGIN
 	   SELECT Group_Desc,Username,AL_Desc
 	  	 FROM User_Security us
 	  	 Left Join Security_Groups sg on sg.Group_Id = us.Group_Id
 	  	 Left Join Users 	 u on u.User_Id = us.User_Id
 	  	 Left Join Access_Level al on al.AL_Id = us.Access_Level
 	  	 Order By Group_Desc
 	 END
ELSE If @DataType = 'SecurityRoles'
 	 BEGIN
 	  	 DECLARE @RoleData Table (UserId Int,Username nvarchar(255),GroupName nvarchar(255),Group_Desc nvarchar(255),
 	  	  	 AL_Desc nvarchar(50),NTGroup Bit,Domain nvarchar(255))
  	  	 IF @QueryType = 2
  	  	  	 INSERT INTO @RoleData(UserId,Username,GroupName,Group_Desc,AL_Desc,NTGroup,Domain)
 	  	  	  	 SELECT u2.user_Id,u2.Username,GroupName,sg.Group_Desc,al.AL_Desc,convert(Bit,Case When urs.User_Id Is Null THEN 1 ELSE 0 END),urs.Domain
 	  	  	  	 FROM User_Role_Security urs 
 	  	  	  	 JOIN Users u2 on u2.user_Id = urs.Role_User_Id
 	  	  	  	 Left Join Users u on u.User_Id = urs.User_Id
 	  	  	  	 Left Join User_Security us on us.User_Id = u2.User_Id
 	  	  	  	 Left Join Security_Groups sg on sg.Group_Id = us.Group_Id
 	  	  	  	 Left Join Access_Level al on al.AL_Id = us.Access_Level
 	  	  	  	 WHERE  urs.Role_User_Id = @Id 
 	  	  	  	 Order by u.Username,GroupName
 	  	 ELSE
  	  	  	 INSERT INTO @RoleData(UserId,Username,GroupName,Group_Desc,AL_Desc,NTGroup,Domain)
 	  	  	  	 SELECT u2.user_Id,u2.Username,GroupName,sg.Group_Desc,al.AL_Desc,convert(Bit,Case When urs.User_Id Is Null THEN 1 ELSE 0 END),urs.Domain
 	  	  	  	 FROM User_Role_Security urs 
 	  	  	  	 JOIN Users u2 on u2.user_Id = urs.Role_User_Id
 	  	  	  	 Left Join Users u on u.User_Id = urs.User_Id
 	  	  	  	 Left Join User_Security us on us.User_Id = u2.User_Id
 	  	  	  	 Left Join Security_Groups sg on sg.Group_Id = us.Group_Id
 	  	  	  	 Left Join Access_Level al on al.AL_Id = us.Access_Level
 	  	  	  	 Order by u2.Username,GroupName
  	  	 INSERT INTO @RoleData(UserId,Username,GroupName,Group_Desc,AL_Desc,NTGroup,Domain)
 	  	  	 SELECT u.User_Id,u.Username,Null,Null,Null,0,Null
 	  	  	 FROM Users u
 	  	  	 Where u.User_Id Not In (SELECT UserId FROM @RoleData) And Is_Role = 1 and system = 0
 	  	  	 
 	  	 SELECT Username,GroupName,Group_Desc,AL_Desc,NTGroup,Domain
 	  	  	 FROM @RoleData 
 	  	  	 ORDER BY Username,GroupName
 	 END
ELSE If @DataType = 'ProdFamily'
 	 BEGIN
 	   SELECT @SQL = 'SELECT p.Prod_Code,p.Prod_Desc,REPLACE(substring(c.Comment_Text,1,1000),char(13) + char(10),char(10)),pf.Product_Family_Desc,REPLACE(substring(c2.Comment_Text,1,1000),char(13) + char(10),char(10)), '
 	   SELECT @Sql = @Sql +'Event_Esignature_Level = Case When p.Event_Esignature_Level = 1 Then ' + '''User Level'''
 	   SELECT @Sql = @Sql + ' When p.Event_Esignature_Level = 2 Then ' + '''Approver Level'''
 	   SELECT @Sql = @Sql + ' ELSE ' + '''Undefined''' + ' END,' 	  
 	   SELECT @Sql = @Sql +'Product_Change_Esignature_Level = Case When p.Product_Change_Esignature_Level = 1 Then ' + '''User Level'''
 	   SELECT @Sql = @Sql + ' When p.Product_Change_Esignature_Level = 2 Then ' + '''Approver Level'''
 	   SELECT @Sql = @Sql + ' ELSE ' + '''Undefined''' + ' END ,ISNULL(ps.isSerialized,0) IsSerialized' 
 	   SELECT @SQL = @SQL + ' FROM Products_Base   p '
 	   SELECT @SQL = @SQL + ' Left Join Product_Family pf on pf.Product_Family_Id = p.Product_Family_Id'
 	   SELECT @SQL = @SQL + ' Left Join Comments c on c.Comment_Id = p.Comment_Id'
 	   SELECT @SQL = @SQL + ' Left Join Comments c2 on c2.Comment_Id = pf.Comment_Id'
 	   SELECT @SQL = @SQL + ' Left Join Product_Serialized ps on ps.product_id = p.Prod_Id'
 	   SELECT @SQL = @SQL + ' WHERE Prod_ID <> 1'
 	   If  @QueryType = 2
 	  	 SELECT @SQL = @SQL + ' and p.Product_Family_Id = ' + Convert(nVarChar(10),@Id) 
 	   SELECT @Sql = @Sql + + ' Order By pf.Product_Family_Desc'
 	   Execute(@SQL)
 	 END
ELSE If @DataType = 'ProductGroups'
 	 BEGIN
 	   SELECT @SQL = 'SELECT pg.Product_Grp_Desc,p.Prod_Code,REPLACE(substring(c.Comment_Text,1,255),char(13) + char(10),char(10))'
 	   SELECT @SQL = @SQL + ' FROM Product_Group_Data pgd '
 	   SELECT @SQL = @SQL + ' Left Join Products_Base   p on p.Prod_Id = pgd.Prod_Id '
 	   SELECT @SQL = @SQL + ' Left Join Product_Groups pg on pg.Product_Grp_Id = pgd.Product_Grp_Id '
 	   SELECT @SQL = @SQL + ' Left Join Comments c on c.Comment_Id = pg.Comment_Id'
 	   If  @QueryType = 2
 	  	 SELECT @SQL = @SQL + ' WHERE pgd.Product_Grp_Id = ' + Convert(nVarChar(10),@Id)
 	   SELECT @Sql = @Sql + + ' Order By pg.Product_Grp_Desc'
 	   Execute(@SQL)
 	 END
ELSE If @DataType = 'Units'
 	 BEGIN
 	  	 SELECT @Sql = 'SELECT d.Dept_Desc,pl.PL_Desc,pu.PU_Desc,pu2.PU_Desc,pu.External_Link,sg.Group_Desc,pu.Extended_Info,convert(bit,isnull(pu.Uses_Start_Time,0))'
 	  	 SELECT @Sql = @Sql + ' FROM Prod_Lines_Base pl'
 	  	 SELECT @SQL = @SQL + ' Left Join  Departments_Base  d On d.Dept_Id = pl.Dept_Id'
 	  	 SELECT @Sql = @Sql + ' Left Join  Prod_Units_Base    pu on pu.PL_Id = pl.PL_Id'
 	  	 SELECT @Sql = @Sql + ' Left Join  Prod_Units_Base    pu2 on pu2.PU_Id = pu.Master_Unit'
 	  	 SELECT @Sql = @Sql + ' Left Join Security_Groups sg on sg.Group_Id = pu.Group_Id'
 	  	 SELECT @SQL = @SQL + ' WHERE pu.PU_Id <> 0 '
 	    	 If  @QueryType = 2
 	  	  	 SELECT @SQL = @SQL + ' And pl.pl_Id = ' + Convert(nVarChar(10),@Id)
 	    	 If  @QueryType = 3
 	  	  	 SELECT @SQL = @SQL + ' And d.Dept_Id = ' + Convert(nVarChar(10),@Id)
 	   	 SELECT @Sql = @Sql + + ' Order By d.Dept_Desc,pl.PL_Desc,Isnull(pu.PU_Order,255),pu.PU_Desc'
 	    	 Execute(@SQL)
 	 END
ELSE If @DataType = 'UnitProperties'
 	 BEGIN
 	  	 SELECT @Sql = 'SELECT pl.PL_Desc,pu.PU_Desc,'
 	  	 SELECT @Sql =  @Sql + 'convert(bit,isnull(pu.Delete_Child_Events,0)),UT_Desc,pu.Equipment_Type,sh.Sheet_desc,pep.Path_Code,'
 	  	 SELECT @Sql = @Sql + 'erc.ERC_Desc,erc1.ERC_Desc,pp.Prop_Desc + ''/'' + s.Spec_Desc,pu.Downtime_Percent_Alarm_Interval,pu.Downtime_Percent_Alarm_Window,'
 	  	 SELECT @Sql = @Sql + 'pl1.PL_Desc,pu1.PU_Desc,v1.Var_Desc,pp1.Prop_Desc + ''/'' + s1.Spec_Desc,pu.Efficiency_Percent_Alarm_Interval ,pu.Efficiency_Percent_Alarm_Window,'
 	  	 SELECT @Sql = @Sql + 'pl2.PL_Desc,pu3.PU_Desc,v2.Var_Desc,erc2.ERC_Desc,pp2.Prop_Desc + ''/'' + s2.Spec_Desc,'
 	  	 SELECT @Sql = @Sql + 'Rate = Case When pu.Production_Rate_TimeUnits = 0 Then ''Hour'' When pu.Production_Rate_TimeUnits = 1 Then ''Minute'' When pu.Production_Rate_TimeUnits = 2 Then ''Second''  When pu.Production_Rate_TimeUnits = 3 Then ''Day'' ELSE '''' END,'
 	  	 SELECT @Sql = @Sql + 'pu.Production_Alarm_Interval,pu.Production_Alarm_Window,'
 	  	 SELECT @Sql = @Sql + 'pp3.Prop_Desc + ''/'' + s3.Spec_Desc,pu.Waste_Percent_Alarm_Interval ,pu.Waste_Percent_Alarm_Window,'
 	  	 SELECT @Sql = @Sql + 'erc3.ERC_Desc,ert.Tree_Name,convert(bit,isnull(pu.Chain_Start_Time,0)),convert(bit,isnull(pu.Timed_Event_Association,0)),'
 	  	 SELECT @Sql = @Sql + 'WEA = Case When pu.Waste_Event_Association = 1 Then ''Event Based'' When pu.Waste_Event_Association = 2 Then ''Time Based''  ELSE '''' END,'
 	  	 SELECT @Sql =  @Sql + 'convert(bit,isnull(pu.Uses_Start_Time,0))'
 	  	 SELECT @Sql = @Sql + ' FROM Prod_Lines_Base pl'
 	  	 SELECT @SQL = @SQL + ' Left Join  Departments_Base  d On d.Dept_Id = pl.Dept_Id'
 	  	 SELECT @Sql = @Sql + ' Left Join Prod_Units_Base    pu on pu.PL_Id = pl.PL_Id'
 	  	 SELECT @Sql = @Sql + ' Left Join Unit_Types ut on ut.Unit_Type_Id = pu.Unit_Type_Id'
 	  	 SELECT @Sql = @Sql + ' Left Join sheets sh on sh.Sheet_Id = pu.Sheet_Id'
 	  	 SELECT @Sql = @Sql + ' Left Join PrdExec_Paths pep on pep.Path_Id = pu.Default_Path_id'
 	  	 SELECT @Sql = @Sql + ' Left Join Event_Reason_Catagories erc on erc.ERC_Id = pu.Downtime_Scheduled_Category'
 	  	 SELECT @Sql = @Sql + ' Left Join Event_Reason_Catagories erc1 on erc1.ERC_Id = pu.Downtime_External_Category'
 	  	 SELECT @SQL = @SQL + ' Left Join Specifications s on s.Spec_Id = pu.Downtime_Percent_Specification'
 	  	 SELECT @SQL = @SQL + ' Left Join Product_Properties pp on pp.Prop_Id = s.Prop_Id'
 	  	 SELECT @Sql = @Sql + ' Left Join Variables_Base   v1 on v1.Var_Id = pu.Efficiency_Variable '
 	  	 SELECT @Sql = @Sql + ' Left Join Prod_Units_Base    pu1 on pu1.PU_Id = v1.PU_Id'
 	  	 SELECT @Sql = @Sql + ' Left Join Prod_Lines_Base pl1 on pl1.PL_Id =  pu1.PL_Id'
 	  	 SELECT @SQL = @SQL + ' Left Join Specifications s1 on s1.Spec_Id = pu.Efficiency_Percent_Specification'
 	  	 SELECT @SQL = @SQL + ' Left Join Product_Properties pp1 on pp1.Prop_Id = s1.Prop_Id'
 	  	 SELECT @Sql = @Sql + ' Left Join Variables_Base   v2 on v2.Var_Id = pu.Production_Variable '
 	  	 SELECT @Sql = @Sql + ' Left Join Prod_Units_Base    pu3 on pu3.PU_Id = v2.PU_Id'
 	  	 SELECT @Sql = @Sql + ' Left Join Prod_Lines_Base pl2 on pl2.PL_Id =  pu3.PL_Id'
 	  	 SELECT @Sql = @Sql + ' Left Join Event_Reason_Catagories erc2 on erc2.ERC_Id = pu.Performance_Downtime_Category'
 	  	 SELECT @SQL = @SQL + ' Left Join Specifications s2 on s2.Spec_Id = pu.Production_Rate_Specification'
 	  	 SELECT @SQL = @SQL + ' Left Join Product_Properties pp2 on pp2.Prop_Id = s2.Prop_Id'
 	  	 SELECT @SQL = @SQL + ' Left Join Specifications s3 on s3.Spec_Id = pu.Waste_Percent_Specification'
 	  	 SELECT @SQL = @SQL + ' Left Join Product_Properties pp3 on pp3.Prop_Id = s3.Prop_Id'
 	  	 SELECT @Sql = @Sql + ' Left Join Event_Reason_Catagories erc3 on erc3.ERC_Id = pu.Non_Productive_Category'
     	  	 SELECT @Sql = @Sql + ' Left Join Event_Reason_Tree ert On ert.Tree_Name_Id = pu.Non_Productive_Reason_Tree'
 	  	 SELECT @SQL = @SQL + ' WHERE pu.PU_Id <> 0 '
 	    	 If  @QueryType = 2
 	  	  	 SELECT @SQL = @SQL + ' And pl.pl_Id = ' + Convert(nVarChar(10),@Id)
 	    	 If  @QueryType = 3
 	  	  	 SELECT @SQL = @SQL + ' And d.Dept_Id = ' + Convert(nVarChar(10),@Id)
 	   	 SELECT @Sql = @Sql + + ' Order By pl.PL_Desc,pu.PU_Desc'
 	    	 Execute(@SQL)
 	 END
ELSE If @DataType = 'Characteristics'
 	 BEGIN
 	   SELECT @SQL = 'SELECT pp.Prop_Desc,c.Char_Desc,c1.Char_Desc,c.Extended_Info,c.External_Link'
 	   SELECT @Sql = @Sql + ' FROM Characteristics c'
 	   SELECT @Sql = @Sql + ' Left Join Product_Properties pp on pp.Prop_Id =  c.Prop_Id '
 	   SELECT @Sql = @Sql + ' Left Join Characteristics c1 on c1.Char_Id = c.Derived_From_Parent'
 	   If  @QueryType = 2
 	  	 SELECT @SQL = @SQL + ' WHERE c.Prop_Id = ' + Convert(nVarChar(10),@Id)
 	   SELECT @Sql = @Sql +  ' Order by  pp.Prop_Desc'
 	   Execute(@SQL)
 	 END
ELSE If @DataType = 'SpecVariables'
 	 BEGIN
 	   SELECT @SQL = 'SELECT pp.Prop_Desc,s.Spec_Desc,dt.Data_Type_Desc,s.Spec_Precision,s.Eng_Units,'
 	   SELECT @Sql = @Sql +  's.Tag,s.Extended_Info,s.External_Link,REPLACE(substring(c.Comment_Text,1,1000),char(13) + char(10),char(10)) '
 	   SELECT @Sql = @Sql +  ' FROM Specifications s '
 	   SELECT @SQL = @SQL +  ' Left Join Comments c on c.Comment_Id = s.Comment_Id'
 	   SELECT @Sql = @Sql +  ' Left Join Data_Type dt on dt.Data_Type_Id =  s.Data_Type_Id'
 	   SELECT @Sql = @Sql +  ' Left Join Product_Properties pp on pp.Prop_Id =  s.Prop_Id '
 	   If  @QueryType = 2
 	  	 SELECT @SQL = @SQL + ' WHERE s.Prop_Id = ' + Convert(nVarChar(10),@Id)
 	   SELECT @Sql = @Sql +  ' Order by  pp.Prop_Desc'
 	   Execute(@SQL)
 	 END
ELSE If @DataType = 'CentralSpecs'
 	 BEGIN
 	   SELECT @Sql = 'SELECT pp.Prop_Desc,s.Spec_Desc,c.Char_Desc,convert(Bit,Case When c.Derived_From_Parent is Null Then 0 ELSE 1 END),'
 	   SELECT @Sql = @Sql + 'a.L_Entry,convert(Bit,Case When Is_Defined & 1 = 1 Then 1 ELSE 0 END),'
 	   SELECT @Sql = @Sql + 'a.L_Reject,convert(Bit,Case When Is_Defined & 2 = 2 Then 1 ELSE 0 END),'
 	   SELECT @Sql = @Sql + 'a.L_Warning,convert(Bit,Case When Is_Defined & 4 = 4 Then 1 ELSE 0 END),'
 	   SELECT @Sql = @Sql + 'a.L_User,convert(Bit,Case When Is_Defined & 8 = 8 Then 1 ELSE 0 END),'
 	   SELECT @Sql = @Sql + 'a.Target,convert(Bit,Case When Is_Defined & 16 = 16 Then 1 ELSE 0 END),'
 	   SELECT @Sql = @Sql + 'a.U_User,convert(Bit,Case When Is_Defined & 32 = 32 Then 1 ELSE 0 END),'
 	   SELECT @Sql = @Sql + 'a.U_Warning,convert(Bit,Case When Is_Defined & 64 = 64 Then 1 ELSE 0 END),'
 	   SELECT @Sql = @Sql + 'a.U_Reject,convert(Bit,Case When Is_Defined & 128 = 128 Then 1 ELSE 0 END),'
 	   SELECT @Sql = @Sql + 'a.U_Entry,convert(Bit,Case When Is_Defined & 256 = 256 Then 1 ELSE 0 END),'
 	   SELECT @Sql = @Sql + 'a.Test_Freq,convert(Bit,Case When Is_Defined & 512 = 512 Then 1 ELSE 0 END),'
 	   SELECT @Sql = @Sql + 'Esignature_Level = Case When a.Esignature_Level = 1 Then ' + '''User Level'''
 	   SELECT @Sql = @Sql + ' When a.Esignature_Level = 2 Then ' + '''Approver Level'''
 	   SELECT @Sql = @Sql + ' ELSE ' + '''Undefined''' + ' END,convert(Bit,Case When Is_Defined & 1024 = 1024 Then 1 ELSE 0 END),'
 	   SELECT @Sql = @Sql + ' L_Control,convert(Bit,Case When Is_Defined & 8192 = 8192 Then 1 ELSE 0 END),'
 	   SELECT @Sql = @Sql + ' T_Control,convert(Bit,Case When Is_Defined & 16384 = 16384 Then 1 ELSE 0 END),'
 	   SELECT @Sql = @Sql + ' U_Control,convert(Bit,Case When Is_Defined & 32768 = 32768 Then 1 ELSE 0 END) '
 	   SELECT @Sql = @Sql + ' FROM Active_Specs a'
 	   SELECT @Sql = @Sql + ' Join Characteristics c on c.Char_Id = a.Char_Id'
 	   SELECT @Sql = @Sql + ' Join Specifications s on s.Spec_Id = a.Spec_Id'
 	   SELECT @Sql = @Sql + ' Join Product_Properties pp on pp.Prop_Id =  s.Prop_Id'
 	   SELECT @Sql = @Sql + ' WHERE (Effective_Date < ' + @Now + ' and (Expiration_Date > ' + @Now + ' or Expiration_Date is null)) '
 	   If  @QueryType = 2
 	  	 BEGIN
 	  	  	 SELECT @Sql = @Sql + ' and pp.Prop_Id = ' + Convert(nVarChar(10),@Id)
 	  	 END
 	   Execute(@Sql)
 	 END
ELSE If @DataType = 'CharacteristicGroups'
 	 BEGIN
 	   SELECT @Sql = 'SELECT pp.Prop_Desc,cg.Characteristic_Grp_Desc,c.Char_Desc'
 	   SELECT @Sql = @Sql + ' FROM Characteristic_Group_Data cgd  '
 	   SELECT @Sql = @Sql + ' Left Join Characteristic_Groups cg on cg.Characteristic_Grp_Id = cgd.Characteristic_Grp_Id '
 	   SELECT @Sql = @Sql + ' Left Join Characteristics c on c.Char_Id = cgd.Char_Id'
 	   SELECT @Sql = @Sql + ' Left Join Product_Properties pp on pp.Prop_Id =  c.Prop_Id '
 	   If  @QueryType = 2
 	  	 BEGIN
 	  	  	 SELECT @Sql = @Sql + ' WHERE c.Prop_Id = ' + Convert(nVarChar(10),@Id)
 	  	 END
 	   SELECT @Sql = @Sql + ' Order by Characteristic_Grp_Desc'
 	   Execute(@Sql)
 	 END
ELSE If @DataType = 'ProductsToUnits'
 	 BEGIN
 	    SELECT @Sql = 'SELECT pl.PL_Desc,pu.PU_Desc,p.Prod_Code,px.Prod_Code_XRef'
 	    SELECT @Sql = @Sql + ' FROM PU_Products pup'
 	    SELECT @Sql = @Sql + ' Left Join Prod_Units_Base    pu on pu.PU_Id = pup.PU_Id'
 	    SELECT @Sql = @Sql + ' Left Join Prod_Lines_Base pl on pl.PL_Id = pu.PL_Id'
 	    SELECT @Sql = @Sql + ' Left Join Products_Base   p On p.Prod_Id = pup.Prod_Id'
 	    SELECT @Sql = @Sql + ' Left Join Prod_XRef px On px.Prod_Id = pup.Prod_Id and px.PU_Id = pup.PU_Id'
 	    If  @QueryType = 1
 	  	 BEGIN
 	  	  	 SELECT @Id = ISNULL(Master_Unit,@Id) FROM Prod_Units_Base    WHERE PU_Id = @Id
 	  	  	 SELECT @Sql = @Sql + ' WHERE pup.PU_Id =  ' + Convert(nVarChar(10),@Id)
 	  	 END
 	    If  @QueryType = 2
 	  	 BEGIN
 	  	   SELECT @Sql = @Sql + ' WHERE pl.PL_Id =  ' + Convert(nVarChar(10),@Id)
 	  	 END
 	   SELECT @Sql = @Sql + ' and pup.Prod_Id <> 1'
 	   SELECT @Sql = @Sql + ' Order by pl.PL_Desc,pu.PU_Desc'
 	   Execute(@Sql)
 	 END
ELSE If @DataType = 'ProductCharacteristics'
 	 BEGIN
 	    SELECT @Id = Coalesce(Master_Unit,@Id) FROM Prod_Units_Base    WHERE PU_Id = @Id 
 	    SELECT pl.PL_Desc,pu.PU_Desc,p.Prod_Code,pp.Prop_Desc,c.Char_Desc
 	  	 FROM PU_Characteristics puc
 	  	 Left Join Prod_Units_Base    pu on pu.PU_Id = puc.PU_Id
 	  	 Left Join Prod_Lines_Base pl on pl.PL_Id = pu.PL_Id
 	  	 Left Join Products_Base   p On p.Prod_Id = puc.Prod_Id
 	  	 Left Join Characteristics c On c.Char_Id = puc.Char_Id
 	  	 Left Join Product_Properties pp on pp.Prop_Id =  puc.Prop_Id
 	  	 WHERE puc.PU_Id =  @Id
 	  	 Order by Prop_Desc
 	 END
ELSE If @DataType = 'EventSubTypes'
 	 BEGIN
 	    SELECT e.ET_Desc,es.Event_Subtype_Desc,es.Event_Mask,es.Dimension_X_Name,
 	  	  	   eu1.Eng_Unit_Code,Convert(bit,coalesce(es.Dimension_Y_Enabled,0)),es.Dimension_Y_Name,
 	  	  	   eu2.Eng_Unit_Code,Convert(bit,coalesce(es.Dimension_Z_Enabled,0)),es.Dimension_Z_Name,
 	  	  	   eu3.Eng_Unit_Code,Convert(bit,coalesce(es.Dimension_A_Enabled,0)),es.Dimension_A_Name,
 	  	  	   eu4.Eng_Unit_Code,es.Ack_Required,es.Duration_Required,es.Cause_Required,ert.Tree_Name,
 	  	  	   er1.Event_Reason_Name, er2.Event_Reason_Name, er3.Event_Reason_Name, er4.Event_Reason_Name,
 	  	  	   Action_Required,ert2.Tree_Name,er5.Event_Reason_Name,er6.Event_Reason_Name,er7.Event_Reason_Name,
 	  	  	   er8.Event_Reason_Name,i.Icon_Desc,REPLACE(substring(c.Comment_Text,1,255),char(13) + char(10),char(10)),
 	  	  	   ESignature_Level = Case When es.ESignature_Level = 1 Then 'User Level'
 	    	  	  	  	  	 When es.ESignature_Level = 2 Then 'Approver Level'
 	    	  	  	  	  	 ELSE 'Undefined' END 
 	   	 FROM Event_Subtypes es
 	  	  Left Join Event_Types e on e.et_Id = es.et_Id
 	  	  Left Join Event_Reason_Tree ert on ert.Tree_Name_Id = es.Cause_Tree_Id
 	  	  Left Join Event_Reason_Tree ert2 on ert.Tree_Name_Id = es.Action_Tree_Id
 	  	  Left Join Event_Reasons er1 on er1.Event_Reason_Id = es.Default_Cause1
 	  	  Left Join Event_Reasons er2 on er2.Event_Reason_Id = es.Default_Cause2
 	  	  Left Join Event_Reasons er3 on er3.Event_Reason_Id = es.Default_Cause3
 	  	  Left Join Event_Reasons er4 on er4.Event_Reason_Id = es.Default_Cause4
 	  	  Left Join Event_Reasons er5 on er5.Event_Reason_Id = es.Default_Action1
 	  	  Left Join Event_Reasons er6 on er6.Event_Reason_Id = es.Default_Action2
 	  	  Left Join Event_Reasons er7 on er7.Event_Reason_Id = es.Default_Action3
 	  	  Left Join Event_Reasons er8 on er8.Event_Reason_Id = es.Default_Action4
 	  	  Left Join Icons i On i.Icon_Id = es.Icon_Id
 	  	  Left Join Comments c on c.Comment_Id = es.Comment_Id
 	  	  Left Join Engineering_Unit eu1 on eu1.Eng_Unit_Id = es.Dimension_X_Eng_Unit_Id
 	  	  Left Join Engineering_Unit eu2 on eu2.Eng_Unit_Id = es.Dimension_Y_Eng_Unit_Id
 	  	  Left Join Engineering_Unit eu3 on eu3.Eng_Unit_Id = es.Dimension_Z_Eng_Unit_Id
 	  	  Left Join Engineering_Unit eu4 on eu4.Eng_Unit_Id = es.Dimension_A_Eng_Unit_Id
 	  	 ORDER BY e.ET_Desc,es.Event_Subtype_Desc
 	 END
ELSE If @DataType = 'VarSpecs'
 	 BEGIN
 	   SELECT @Sql = 'SELECT pl.PL_Desc,pu.PU_Desc,v.Var_Desc,convert(Bit,Case When v.Spec_Id is Null Then 0 ELSE 1 END),p.Prod_Code,'
 	   SELECT @Sql = @Sql + 'vs.L_Entry,convert(Bit,Case When Is_Defined & 1 = 1 Then 1 ELSE 0 END),'
 	   SELECT @Sql = @Sql + 'vs.L_Reject,convert(Bit,Case When Is_Defined & 2 = 2 Then 1 ELSE 0 END),'
 	   SELECT @Sql = @Sql + 'vs.L_Warning,convert(Bit,Case When Is_Defined & 4 = 4 Then 1 ELSE 0 END),'
 	   SELECT @Sql = @Sql + 'vs.L_User,convert(Bit,Case When Is_Defined & 8 = 8 Then 1 ELSE 0 END),'
 	   SELECT @Sql = @Sql + 'vs.Target,convert(Bit,Case When Is_Defined & 16 = 16 Then 1 ELSE 0 END),'
 	   SELECT @Sql = @Sql + 'vs.U_User,convert(Bit,Case When Is_Defined & 32 = 32 Then 1 ELSE 0 END),'
 	   SELECT @Sql = @Sql + 'vs.U_Warning,convert(Bit,Case When Is_Defined & 64 = 64 Then 1 ELSE 0 END),'
 	   SELECT @Sql = @Sql + 'vs.U_Reject,convert(Bit,Case When Is_Defined & 128 = 128 Then 1 ELSE 0 END),'
 	   SELECT @Sql = @Sql + 'vs.U_Entry,convert(Bit,Case When Is_Defined & 256 = 256 Then 1 ELSE 0 END),'
 	   SELECT @Sql = @Sql + 'vs.Test_Freq,convert(Bit,Case When Is_Defined & 512 = 512 Then 1 ELSE 0 END),'
 	   SELECT @Sql = @Sql +'Esignature_Level = Case When vs.Esignature_Level = 1 Then ' + '''User Level'''
 	   SELECT @Sql = @Sql + ' When vs.Esignature_Level = 2 Then ' + '''Approver Level'''
 	   SELECT @Sql = @Sql + ' ELSE ' + '''Undefined''' + ' END,convert(Bit,Case When Is_Defined & 1024 = 1024 Then 1 ELSE 0 END),'
 	   SELECT @Sql = @Sql + ' L_Control,convert(Bit,Case When Is_Defined & 8192 = 8192 Then 1 ELSE 0 END),'
 	   SELECT @Sql = @Sql + ' T_Control,convert(Bit,Case When Is_Defined & 16384 = 16384 Then 1 ELSE 0 END),'
 	   SELECT @Sql = @Sql + ' U_Control,convert(Bit,Case When Is_Defined & 32768 = 32768 Then 1 ELSE 0 END) '
 	   SELECT @Sql = @Sql + ' FROM Var_Specs vs'
 	   SELECT @Sql = @Sql + ' Join Variables_Base   v on v.Var_Id = vs.Var_Id '
 	   SELECT @Sql = @Sql + ' Join Prod_Units_Base    pu on pu.PU_Id = v.PU_Id'
 	   SELECT @Sql = @Sql + ' Join Prod_Lines_Base pl on pl.PL_Id =  pu.PL_Id'
 	   SELECT @Sql = @Sql + ' Join Products_Base   p on p.Prod_Id =  vs.Prod_Id'
 	   SELECT @Sql = @Sql + ' WHERE (Effective_Date < ' + @Now + ' and (Expiration_Date > ' + @Now + ' or Expiration_Date is null)) '
 	 If  @QueryType = 1
 	  	 SELECT @SQL = @SQL + ' and v.PU_Id <> 0'
 	 ELSE If @QueryType = 2 /* By Group */
 	  	  	 BEGIN
 	  	  	   SELECT @SQL = @SQL + ' and v.PUG_Id = ' + Convert(nVarChar(10),@Id)
 	  	  	 END
 	 ELSE If @QueryType = 3 /* By Unit */
 	  	  	 BEGIN
 	  	  	   SELECT @SQL = @SQL + ' and v.PU_Id =  ' + Convert(nVarChar(10),@Id)
 	  	  	 END
 	 ELSE If @QueryType = 4 /* By Line */
 	  	  	 BEGIN
 	  	  	   SELECT @SQL = @SQL + ' and Pl.PL_Id = ' + Convert(nVarChar(10),@Id)
 	  	  	 END
 	 Execute(@SQL)
 	 END
ELSE If @DataType = 'Displays'
 	 BEGIN
 	   SELECT @Sql = 'SELECT sg.Sheet_Group_Desc,s.Sheet_Desc,st.Sheet_Type_Desc,pu.PU_Desc,s.Event_Prompt,s.Interval,s.Offset,'
 	   SELECT @Sql = @Sql + 's.Initial_Count,s.Maximum_Count,s.Max_Edit_Hours,s.Row_Headers,s.Column_Headers,Convert(bit,coalesce(s.Row_Numbering,0)),'
 	   SELECT @Sql = @Sql + 'Convert(bit,coalesce(s.Column_Numbering,0)),Convert(bit,coalesce(s.Display_Spec_Win,0)),Convert(bit,coalesce(s.Display_Spec_Column,0)),Convert(bit,coalesce(s.Display_Comment_Win,0)),s.Display_Event,'
 	   SELECT @Sql = @Sql + 's.Display_Date,s.Display_Time,s.Display_Grade,s.Display_Var_Order,s.Display_Data_Type,s.Display_Data_Source,'
 	   SELECT @Sql = @Sql + 's.Display_Spec,s.Display_Prod_Line,s.Display_Prod_Unit,sec.Group_Desc,s.Display_Description,'
 	   SELECT @Sql = @Sql + 's.Display_EngU,Convert(bit,coalesce(s.Dynamic_Rows,0)),'
 	   SELECT @Sql = @Sql + 'Convert(bit,coalesce(s.Wrap_Product,0)),ps.ProdStatus_Desc,s.Max_Inventory_Days,PL_Desc = Isnull(pl.PL_Desc,pl1.PL_Desc),pie.Input_Name,es.Event_Subtype_Desc'
 	   SELECT @Sql = @Sql + ' FROM Sheets s'
 	   SELECT @Sql = @Sql + ' Left Join Sheet_Groups sg on sg.Sheet_Group_Id = s.Sheet_Group_Id'
 	   SELECT @Sql = @Sql + ' Left Join Sheet_Type st on st.Sheet_Type_Id = s.Sheet_Type'
 	   SELECT @Sql = @Sql + ' Left Join Prod_Units_Base    pu on pu.PU_Id = s.Master_Unit'
 	   SELECT @Sql = @Sql + ' Left Join Security_Groups sec on sec.Group_Id = s.Group_Id'
 	   SELECT @Sql = @Sql + ' Left Join Production_Status ps on ps.ProdStatus_Id = s.Auto_Label_Status'
 	   SELECT @Sql = @Sql + ' Left Join Prod_Lines_Base pl on pl.pl_Id = s.PL_Id'
 	   SELECT @Sql = @Sql + ' Left Join Prod_Lines_Base pl1 on pl1.pl_Id = pu.PL_Id'
 	   SELECT @Sql = @Sql + ' Left Join PrdExec_Inputs pie on pie.PEI_Id = s.PEI_Id'
 	   SELECT @Sql = @Sql + ' Left Join Event_Subtypes es on es.Event_Subtype_Id = s.Event_Subtype_Id'
 	   If @QueryType = 2 /* By Group */
 	  	 SELECT @SQL = @SQL + ' WHERE s.Sheet_Group_Id = ' + Convert(nVarChar(10),@Id)
 	   If @QueryType = 3 /* By Group */
 	  	 SELECT @SQL = @SQL + ' WHERE s.Sheet_Id = ' + Convert(nVarChar(10),@Id)
 	   SELECT @Sql = @Sql + ' Order by sg.Sheet_Group_Desc,s.Sheet_Desc'
 	   Execute(@SQL)
 	 END
ELSE If @DataType = 'DisplayVariables'
 	 BEGIN
 	   SELECT @Sql = 'SELECT s.Sheet_Desc,pl.PL_Desc,pu.PU_Desc,v.Var_Desc,sv.Title,sv.Var_Order,sv.Activity_Order,sv.Execution_Start_Duration,sv.Target_Duration,sv.Activity_Alias,sv.AutoComplete_Duration '
 	   SELECT @Sql = @Sql + ' FROM Sheet_Variables sv'
 	   SELECT @Sql = @Sql + ' Left Join Variables_Base   v on v.Var_Id = sv.Var_Id'
 	   SELECT @Sql = @Sql + ' Left Join Prod_Units_Base    pu on pu.PU_Id = v.PU_Id'
 	   SELECT @Sql = @Sql + ' Left Join Prod_Lines_Base pl on pl.PL_Id =  pu.PL_Id'
 	   SELECT @Sql = @Sql + ' Join Sheets s on s.Sheet_Id = sv.Sheet_Id'
 	   SELECT @Sql = @Sql + ' WHERE (sv.Var_Id > 0 or sv.Var_Id is null) '
 	   If @QueryType = 2 /* By Group */
 	  	 BEGIN
 	  	   SELECT @SQL = @SQL + ' And s.Sheet_Group_Id = ' + Convert(nVarChar(10),@Id)
 	  	 END
 	   If @QueryType = 3 /* By Group */
 	  	 SELECT @SQL = @SQL + ' And s.Sheet_Id = ' + Convert(nVarChar(10),@Id)
 	   SELECT @Sql = @Sql + ' Order by s.Sheet_Desc,sv.Var_Order'
 	   Execute(@SQL)
 	 END
ELSE If @DataType = 'DisplayUnits'
 	 BEGIN
 	   SELECT @Sql = 'SELECT s.Sheet_Desc,pl.PL_Desc,pu.PU_Desc'
 	   SELECT @Sql = @Sql + ' FROM Sheet_Unit su'
 	   SELECT @Sql = @Sql + ' Join Prod_Units_Base    pu on pu.PU_Id = su.PU_Id'
 	   SELECT @Sql = @Sql + ' Join Prod_Lines_Base pl on pl.PL_Id =  pu.PL_Id'
 	   SELECT @Sql = @Sql + ' Join Sheets s on s.Sheet_Id = su.Sheet_Id'
 	   SELECT @Sql = @Sql + ' WHERE su.sheet_Id > 0  '
 	   If @QueryType = 2 /* By Group */
 	  	 BEGIN
 	  	   SELECT @SQL = @SQL + ' And s.Sheet_Group_Id = ' + Convert(nVarChar(10),@Id)
 	  	 END
 	   If @QueryType = 3 /* By Group */
 	  	 SELECT @SQL = @SQL + ' And s.Sheet_Id = ' + Convert(nVarChar(10),@Id)
 	   SELECT @Sql = @Sql + ' Order by s.Sheet_Desc,pl.PL_Desc,pu.PU_Desc'
 	   Execute(@SQL)
 	 END
ELSE If @DataType = 'DisplayPaths'
 	 BEGIN
 	   SELECT @Sql = 'SELECT s.Sheet_Desc,pp.Path_Code'
 	   SELECT @Sql = @Sql + ' FROM Sheet_Paths sp'
 	   SELECT @Sql = @Sql + ' Join Sheets s on s.Sheet_Id = sp.Sheet_Id'
 	   SELECT @Sql = @Sql + ' Join PrdExec_Paths pp on pp.Path_Id = sp.Path_Id'
 	   SELECT @Sql = @Sql + ' WHERE sp.sheet_Id > 0  '
 	   If @QueryType = 2 /* By Group */
 	  	 BEGIN
 	  	   SELECT @SQL = @SQL + ' And s.Sheet_Group_Id = ' + Convert(nVarChar(10),@Id)
 	  	 END
 	   If @QueryType = 3 /* By Group */
 	  	 SELECT @SQL = @SQL + ' And s.Sheet_Id = ' + Convert(nVarChar(10),@Id)
 	   SELECT @Sql = @Sql + ' Order by s.Sheet_Desc,pp.Path_Code'
 	   Execute(@SQL)
 	 END
ELSE If @DataType = 'Events'  -- Exclude Genealogy/Movement models b/c extra stuff required
 	 BEGIN
 	  	 SELECT @Sql =  'SELECT pl.PL_Desc,pu.PU_Desc,et.ET_Desc,isnull(es.Event_Subtype_Desc,es2.Event_Subtype_Desc),'
 	  	 SELECT @Sql = @Sql + 'IsNULL(ec.EC_Desc,ed.Model_Desc),ec.Extended_Info,ec.Exclusions,REPLACE(substring(c.Comment_Text,1,255),char(13) + char(10),char(10)),pei.Input_Name,ed.Model_Num,'
 	  	 SELECT @Sql = @Sql +'Esignature_Level = Case When ec.ESignature_Level = 1 Then ' + '''User Level'''
 	  	 SELECT @Sql = @Sql + ' When ec.ESignature_Level = 2 Then ' + '''Approver Level'''
 	  	 SELECT @Sql = @Sql + ' END, '
 	  	 SELECT @Sql = @Sql + ' ec.External_Time_Zone, ec.Max_Run_Time, ec.Move_EndTime_Interval'
 	  	 SELECT @Sql = @Sql + ' FROM Event_Configuration ec'
 	  	 SELECT @Sql = @Sql + ' Left Join Prod_Units_Base    pu On ec.PU_Id = pu.PU_Id'
 	  	 SELECT @Sql = @Sql + ' Left Join Prod_Lines_Base pl On pu.PL_Id = pl.PL_Id'
 	  	 SELECT @Sql = @Sql + ' Left Join  Departments_Base  d On d.Dept_Id = pl.Dept_Id'
 	  	 SELECT @Sql = @Sql + ' Left Join Event_Types et On ec.ET_Id = et.ET_Id'
 	  	 SELECT @Sql = @Sql + ' Left Join Event_Subtypes es On ec.Event_Subtype_Id = es.Event_Subtype_Id'
 	  	 SELECT @Sql = @Sql + ' Left Join Prdexec_inputs pei on pei.PEI_Id = ec.PEI_Id'
 	  	 SELECT @Sql = @Sql + ' Left Join Event_Subtypes es2 on pei.Event_Subtype_Id = es2.Event_Subtype_Id'
 	  	 SELECT @Sql = @Sql + ' Left Join Comments c on c.Comment_Id = ec.Comment_Id'
 	  	 SELECT @Sql = @Sql + ' Left Join ed_Models ed on ed.ED_Model_Id = ec.ED_Model_Id'
 	  	 If  @QueryType = 1
 	  	  	 SELECT @SQL = @SQL + ' WHERE pu.PU_Id <> 0'
   	 ELSE If  @QueryType = 2
 	  	  	 SELECT @SQL = @SQL + ' WHERE pl.pl_Id = ' + Convert(nVarChar(10),@Id)
 	  	 ELSE If @QueryType = 3 /* By Unit */
 	    	  	 SELECT @SQL = @SQL + ' WHERE pu.PU_Id = ' + Convert(nVarChar(10),@Id)
 	  	 ELSE If @QueryType = 4 /* By Dept */
 	    	  	 SELECT @SQL = @SQL + ' WHERE d.Dept_Id = ' + Convert(nVarChar(10),@Id)
 	  	 SELECT @Sql = @Sql + ' Order by pl.PL_Desc,pu.PU_Desc'
 	   Execute(@SQL)
 	 END
ELSE If @DataType = 'EventConfigurationProperties'
BEGIN
 	 Create  Table #ECP (PL_Desc nvarchar(50),PU_Desc nvarchar(50),ET_desc nvarchar(50),Input_Name nvarchar(50),
 	  	  	  	  	  Model_Num nvarchar(50),ModelDesc nvarchar(255),PU_Des2 nvarchar(50),FieldDesc nVarChar(100),FieldOrder  Int,
 	  	  	  	       FTDesc nvarchar(255),Alias nVarChar(100),MyTrigger Bit,Attribute nVarChar(100),
 	  	  	  	   	  STDesc nVarChar(100),Sampling_Offset Int,Input_Precision Int,Value nvarchar(3000),Value2 nVarChar(100),
 	  	  	  	  	  Value3 nVarChar(100),EC_id Int,Is_UD Bit)
 	 SELECT @PreFixLen = Len(Prefix) + 1 from ED_FieldTypes where ED_Field_Type_Id = 3
 	 SELECT @Sql = 	 'SELECT pl.PL_Desc,pu.PU_Desc,et.ET_desc,pei.Input_Name,ed.Model_Num,Isnull(ec.EC_Desc,ed.Model_Desc),pu2.PU_Desc,edf.Field_Desc,edf.Field_Order,edft.Field_Type_Desc,Alias,' 
 	 SELECT @Sql = @Sql + 'Convert(bit,coalesce(IsTrigger,0)),Attribute_Desc,st.ST_Desc,Sampling_Offset,Input_Precision,'
 	 SELECT @Sql = @Sql + 'Value = Case When edf.ED_Field_Type_Id = 8 Then (SELECT ST_Desc FROM sampling_type WHERE ST_Id = convert(int,Convert(nVarChar(10),value))) '
 	 SELECT @Sql = @Sql + ' 	  	  	  When edf.ED_Field_Type_Id = 9 Then (SELECT Pl_Desc FROM Prod_Units_Base    pu Join Prod_Lines_Base pl On pl.PL_Id = pu.PL_Id  WHERE PU_Id = convert(int,Convert(nVarChar(10),value)))'
 	 SELECT @Sql = @Sql + ' 	  	  	  When edf.ED_Field_Type_Id = 10 Then (SELECT Pl_Desc FROM Variables_Base   v Join Prod_Units_Base    pu On pu.PU_Id = v.PU_Id Join Prod_Lines_Base pl On pl.PL_Id = pu.PL_Id  WHERE Var_Id = convert(int,Convert(nVarChar(10),value)))'
 	 SELECT @Sql = @Sql + ' 	  	  	  When edf.ED_Field_Type_Id = 15 Then (SELECT Event_Reason_Name FROM event_reasons  WHERE Event_Reason_Id = convert(int,Convert(nVarChar(10),value)))'
 	 SELECT @Sql = @Sql + ' 	  	  	  When edf.ED_Field_Type_Id = 16 or edft.ED_Field_Type_Id = 16 Then (SELECT ProdStatus_Desc FROM production_Status  WHERE ProdStatus_Id = convert(int,Convert(nVarChar(10),value)))' 
 	 SELECT @Sql = @Sql + '            	  When edf.ED_Field_Type_Id = 3 Then (Convert(nvarchar(255),dbo.fnEM_ConvertVarIdToTag(Substring(Value, ' + @PreFixLen + ', 1000))))'
 	 SELECT @Sql = @Sql + ' 	  	  	  When value is not null then  Char(1) + convert(nVarChar(10),ecv.ECV_Id) ' 
 	 SELECT @Sql = @Sql + ' 	  	  	 ELSE Convert(nvarchar(255),Value) END,'
 	 SELECT @Sql = @Sql + 'Value2 = Case When edf.ED_Field_Type_Id = 9 Then (SELECT PU_Desc FROM Prod_Units_Base     WHERE PU_Id = convert(int,Convert(nVarChar(10),value)))'
 	 SELECT @Sql = @Sql + ' 	  	  	  When edf.ED_Field_Type_Id = 10 Then (SELECT PU_Desc FROM Variables_Base   v Join Prod_Units_Base    pu On pu.PU_Id = v.PU_Id  WHERE Var_Id = convert(int,Convert(nVarChar(10),value)))'
 	 SELECT @Sql = @Sql + ' 	  	  	 ELSE null  END,'
 	 SELECT @Sql = @Sql + 'Value3 = Case When edf.ED_Field_Type_Id = 10 Then (SELECT Var_Desc FROM Variables_Base    WHERE Var_Id = convert(int,Convert(nVarChar(10),value)))'
 	 SELECT @Sql = @Sql + ' 	  	  	 ELSE null END ,'
 	 SELECT @Sql = @Sql + ' ec.Ec_id,0'
 	 SELECT @Sql = @Sql + ' FROM Event_Configuration_Data ecd'
 	 SELECT @Sql = @Sql + ' Join Event_Configuration ec On ec.Ec_id = ecd.Ec_Id' 
 	 SELECT @Sql = @Sql + ' Left Join Event_Configuration_Values ecv on ecv.ECV_Id = ecd.ECV_Id'
 	 SELECT @Sql = @Sql + ' Left Join Prod_Units_Base    pu on pu.PU_Id = ec.PU_Id'
 	 SELECT @Sql = @Sql + ' Left Join Prod_Units_Base    pu2 on pu2.PU_Id = ecd.PU_Id'
 	 SELECT @Sql = @Sql + ' Left Join Prod_Lines_Base pl on pl.PL_Id = pu.pl_Id'
 	 SELECT @Sql = @Sql + ' Left Join  Departments_Base  d On d.Dept_Id = pl.Dept_Id'
 	 SELECT @Sql = @Sql + ' Left Join Event_types et on et.ET_Id = ec.ET_Id'
 	 SELECT @Sql = @Sql + ' Left Join Prdexec_inputs pei on pei.PEI_Id = ec.PEI_Id'
 	 SELECT @Sql = @Sql + ' Left Join ed_Models ed on ed.ED_Model_Id = ec.ED_Model_Id'
 	 SELECT @Sql = @Sql + ' Left Join ed_Fields edf on edf.ED_Field_Id = ecd.ED_Field_Id'
 	 SELECT @Sql = @Sql + ' Left Join ed_FieldTypes edft on edf.ED_Field_Type_Id = edft.ED_Field_Type_Id'
 	 SELECT @Sql = @Sql + ' Left Join ED_Attributes eda on eda.ED_Attribute_Id = ecd.ED_Attribute_Id'
 	 SELECT @Sql = @Sql + ' Left Join sampling_type st on st.ST_Id = ecd.ST_Id'
 	 SELECT @Sql = @Sql + ' Left Join sampling_type st2 on st2.ST_Id = ecd.ST_Id'
 	 If  @QueryType = 1
 	  	 SELECT @SQL = @SQL + ' WHERE pu.PU_Id <> 0'
 	 If  @QueryType = 2
 	 SELECT @SQL = @SQL + ' WHERE pl.pl_Id = ' + Convert(nVarChar(10),@Id)
 	 ELSE If @QueryType = 3 /* By Unit */
 	  	 SELECT @SQL = @SQL + ' WHERE pu.PU_Id = ' + Convert(nVarChar(10),@Id)
 	 ELSE If @QueryType = 4 /* By Dept */
 	  	 SELECT @SQL = @SQL + ' WHERE d.Dept_Id = ' + Convert(nVarChar(10),@Id)
 	 
 	 INSERT INTO #ECP
 	 Execute(@SQL)
 	 SELECT @Sql = 'SELECT pl.PL_Desc,pu.PU_Desc,et.ET_desc,pei.Input_Name,ed.Model_Num,Isnull(ec.EC_Desc,ed.Model_Desc),pu2.PU_Desc,efp.Field_Desc,edf.Field_Order,edft.Field_Type_Desc,null,'
 	 SELECT @Sql = @Sql + 'Convert(bit,0),null,Null,Null,Null,'
 	 SELECT @Sql = @Sql + 'Value = Case When edf.ED_Field_Type_Id = 8 Then (SELECT ST_Desc FROM sampling_type WHERE ST_Id = convert(int,Convert(nVarChar(10),isnull(value,efp.Default_Value)))) '
 	 SELECT @Sql = @Sql + ' 	  	  	  When edf.ED_Field_Type_Id = 9 Then (SELECT Pl_Desc FROM Prod_Units_Base    pu Join Prod_Lines_Base pl On pl.PL_Id = pu.PL_Id  WHERE PU_Id = convert(int,Convert(nVarChar(10),isnull(value,efp.Default_Value))))'
 	 SELECT @Sql = @Sql + ' 	  	  	  When edf.ED_Field_Type_Id = 10 Then (SELECT Pl_Desc FROM Variables_Base   v Join Prod_Units_Base    pu On pu.PU_Id = v.PU_Id Join Prod_Lines_Base pl On pl.PL_Id = pu.PL_Id  WHERE Var_Id = convert(int,Convert(nVarChar(10),isnull(value,efp.Default_Value))))'
 	 SELECT @Sql = @Sql + ' 	  	  	  When edf.ED_Field_Type_Id = 15 Then (SELECT Event_Reason_Name FROM event_reasons  WHERE Event_Reason_Id = convert(int,Convert(nVarChar(10),isnull(value,efp.Default_Value))))'
 	 SELECT @Sql = @Sql + ' 	  	  	  When edf.ED_Field_Type_Id = 16 or edft.ED_Field_Type_Id = 16 Then (SELECT ProdStatus_Desc FROM production_Status  WHERE ProdStatus_Id = convert(int,Convert(nVarChar(10),isnull(value,efp.Default_Value))))'
 	 SELECT @Sql = @Sql + ' 	  	  	 ELSE Convert(nvarchar(255),isnull(value,efp.Default_Value)) END,'
 	 SELECT @Sql = @Sql + 'Value2 = Case When edf.ED_Field_Type_Id = 9 Then (SELECT PU_Desc FROM Prod_Units_Base     WHERE PU_Id = convert(int,Convert(nVarChar(10),isnull(value,efp.Default_Value))))'
 	 SELECT @Sql = @Sql + ' 	  	  	  When edf.ED_Field_Type_Id = 10 Then (SELECT PU_Desc FROM Variables_Base   v Join Prod_Units_Base    pu On pu.PU_Id = v.PU_Id  WHERE Var_Id = convert(int,Convert(nVarChar(10),isnull(value,efp.Default_Value))))'
 	 SELECT @Sql = @Sql + ' 	  	  	 ELSE null  END,'
 	 SELECT @Sql = @Sql + 'Value3 = Case When edf.ED_Field_Type_Id = 10 Then (SELECT Var_Desc FROM Variables_Base    WHERE Var_Id = convert(int,Convert(nVarChar(10),isnull(value,efp.Default_Value))))'
 	 SELECT @Sql = @Sql + ' 	  	  	 ELSE null END, '
 	 SELECT @Sql = @Sql + ' ec.Ec_id,1'
 	 SELECT @Sql = @Sql + ' FROM Event_Configuration ec'
 	 SELECT @Sql = @Sql + ' Join  ED_Field_Properties efp on ec.ED_Model_Id = efp.ED_Model_Id'
 	 SELECT @Sql = @Sql + ' Left Join Event_Configuration_Properties ecp on ecp.EC_Id = ec.EC_Id and ecp.ED_Field_Prop_Id = efp.ED_Field_Prop_Id'
 	 SELECT @Sql = @Sql + ' Left Join Prod_Units_Base    pu on pu.PU_Id = ec.PU_Id'
 	 SELECT @Sql = @Sql + ' Left Join Prod_Units_Base    pu2 on pu2.PU_Id = ec.PU_Id'
 	 SELECT @Sql = @Sql + ' Left Join Prod_Lines_Base pl on pl.PL_Id = pu.pl_Id'
 	 SELECT @Sql = @Sql + ' Left Join  Departments_Base  d On d.Dept_Id = pl.Dept_Id'
 	 SELECT @Sql = @Sql + ' Left Join Event_types et on et.ET_Id = ec.ET_Id'
 	 SELECT @Sql = @Sql + ' Left Join Prdexec_inputs pei on pei.PEI_Id = ec.PEI_Id'
 	 SELECT @Sql = @Sql + ' Left Join ed_Models ed on ed.ED_Model_Id = ec.ED_Model_Id'
 	 SELECT @Sql = @Sql + ' Left Join ed_Fields edf on edf.ED_Field_Id = ecp.ED_Field_Prop_Id'
 	 SELECT @Sql = @Sql + ' Left Join ed_FieldTypes edft on efp.ED_Field_Type_Id = edft.ED_Field_Type_Id'
 	 If  @QueryType = 1
 	  	 SELECT @SQL = @SQL + ' WHERE pu.PU_Id <> 0'
 	 If  @QueryType = 2
 	 SELECT @SQL = @SQL + ' WHERE pl.pl_Id = ' + Convert(nVarChar(10),@Id)
 	 ELSE If @QueryType = 3 /* By Unit */
 	  	 SELECT @SQL = @SQL + ' WHERE pu.PU_Id = ' + Convert(nVarChar(10),@Id)
 	 ELSE If @QueryType = 4 /* By Dept */
 	  	 SELECT @SQL = @SQL + ' WHERE d.Dept_Id = ' + Convert(nVarChar(10),@Id)
 	 INSERT INTO #ECP
 	 Execute(@SQL)
 	 SELECT PL_Desc ,PU_Desc,ET_desc ,Input_Name,Model_Num,ModelDesc ,PU_Des2 ,FieldDesc ,FieldOrder,FTDesc ,Alias ,
 	  	 MyTrigger ,Attribute , STDesc ,Sampling_Offset ,Input_Precision = isnull(Input_Precision,0) ,Value ,Value2 , Value3, Is_UD 
 	  FROM #ECP
 	  Order by Ec_id,Is_UD,FieldOrder
 	 Drop Table #ECP
END
ELSE If @DataType = 'ReasonTrees'
 	 BEGIN
 	  	 IF @QueryType = 1 
 	  	  	 SELECT rt.Tree_Name, sg.Group_Desc, rth1.Level_Name As Level_Name1, rth2.Level_Name As Level_Name2, rth3.Level_Name As Level_Name3, rth4.Level_Name As Level_Name4 
 	  	  	 FROM Event_Reason_Tree rt
     	  	 Left Join Security_Groups sg On rt.Group_id = sg.Group_Id
     	  	 Left Join Event_Reason_Level_Headers rth1 On rt.Tree_Name_Id = rth1.Tree_Name_Id And rth1.Reason_Level = 1
     	  	 Left Join Event_Reason_Level_Headers rth2 On rt.Tree_Name_Id = rth2.Tree_Name_Id And rth2.Reason_Level = 2
     	  	 Left Join Event_Reason_Level_Headers rth3 On rt.Tree_Name_Id = rth3.Tree_Name_Id And rth3.Reason_Level = 3
     	  	 Left Join Event_Reason_Level_Headers rth4 On rt.Tree_Name_Id = rth4.Tree_Name_Id And rth4.Reason_Level = 4
 	  	 ELSE
 	  	  	 SELECT rt.Tree_Name, sg.Group_Desc, rth1.Level_Name As Level_Name1, rth2.Level_Name As Level_Name2, rth3.Level_Name As Level_Name3, rth4.Level_Name As Level_Name4 
 	  	  	 FROM Event_Reason_Tree rt
     	  	 Left Join Security_Groups sg On rt.Group_id = sg.Group_Id
     	  	 Left Join Event_Reason_Level_Headers rth1 On rt.Tree_Name_Id = rth1.Tree_Name_Id And rth1.Reason_Level = 1
     	  	 Left Join Event_Reason_Level_Headers rth2 On rt.Tree_Name_Id = rth2.Tree_Name_Id And rth2.Reason_Level = 2
     	  	 Left Join Event_Reason_Level_Headers rth3 On rt.Tree_Name_Id = rth3.Tree_Name_Id And rth3.Reason_Level = 3
     	  	 Left Join Event_Reason_Level_Headers rth4 On rt.Tree_Name_Id = rth4.Tree_Name_Id And rth4.Reason_Level = 4
 	  	  	 WHERE rt.Tree_Name_Id = @Id
 	 END
ELSE If @DataType = 'ReasonCategory'
 	 BEGIN
 	  	 SELECT  	 t.Tree_Name, 
 	  	  	 r1.Event_Reason_Name As Reason1,
 	  	  	 Null As Reason2,
 	  	  	 Null As Reason3,
 	  	  	 Null As Reason4,
 	  	  	 c1.ERC_Desc As Category
 	  	 FROM Event_Reason_Tree_Data td1
 	  	      Inner Join Event_Reasons r1 On td1.Event_Reason_Id = r1.Event_Reason_Id
 	  	      Inner Join Event_Reason_Category_Data cd1 On td1.Event_Reason_Tree_Data_Id = cd1.Event_Reason_Tree_Data_Id And cd1.Propegated_From_ETDId Is Null
 	  	      Inner Join Event_Reason_Catagories c1 On cd1.ERC_Id = c1.ERC_Id
 	  	      Inner Join Event_Reason_Tree t On td1.Tree_Name_Id = t.Tree_Name_Id
 	  	 WHERE td1.Event_Reason_Level = 1
 	  	 
 	  	 Union
 	  	 SELECT  	 t.Tree_Name, 
 	  	  	 r1.Event_Reason_Name As Reason1, 
 	  	  	 r2.Event_Reason_Name As Reason2,
 	  	  	 Null As Reason3,
 	  	  	 Null As Reason4, 
 	  	  	 c2.ERC_Desc As Category
 	  	 FROM Event_Reason_Tree_Data td1
 	  	      Inner Join Event_Reasons r1 On td1.Event_Reason_Id = r1.Event_Reason_Id
 	  	      Inner Join Event_Reason_Tree_Data td2 On td1.Event_Reason_Tree_Data_Id = td2.Parent_Event_R_Tree_Data_Id And td1.Tree_Name_Id = td2.Tree_Name_Id
 	  	      Inner Join Event_Reasons r2 On td2.Event_Reason_Id = r2.Event_Reason_Id
 	  	      Inner Join Event_Reason_Category_Data cd2 On td2.Event_Reason_Tree_Data_Id = cd2.Event_Reason_Tree_Data_Id And cd2.Propegated_From_ETDId Is Null
 	  	      Inner Join Event_Reason_Catagories c2 On cd2.ERC_Id = c2.ERC_Id
 	  	      Inner Join Event_Reason_Tree t On td1.Tree_Name_Id = t.Tree_Name_Id
 	  	 WHERE td1.Event_Reason_Level = 1
 	  	 
 	  	 Union
 	  	 SELECT  	 t.Tree_Name, 
 	  	  	 r1.Event_Reason_Name As Reason1, 
 	  	  	 r2.Event_Reason_Name As Reason2,
 	  	  	 r3.Event_Reason_Name As Reason3,
 	  	  	 Null As Reason4, 
 	  	  	 c3.ERC_Desc As Category
 	  	 FROM Event_Reason_Tree_Data td1
 	  	      Inner Join Event_Reasons r1 On td1.Event_Reason_Id = r1.Event_Reason_Id
 	  	      Inner Join Event_Reason_Tree_Data td2 On td1.Event_Reason_Tree_Data_Id = td2.Parent_Event_R_Tree_Data_Id And td1.Tree_Name_Id = td2.Tree_Name_Id
 	  	      Inner Join Event_Reasons r2 On td2.Event_Reason_Id = r2.Event_Reason_Id
 	  	      Inner Join Event_Reason_Tree_Data td3 On td2.Event_Reason_Tree_Data_Id = td3.Parent_Event_R_Tree_Data_Id And td2.Tree_Name_Id = td3.Tree_Name_Id
 	  	      Inner Join Event_Reasons r3 On td3.Event_Reason_Id = r3.Event_Reason_Id
 	  	      Inner Join Event_Reason_Category_Data cd3 On td3.Event_Reason_Tree_Data_Id = cd3.Event_Reason_Tree_Data_Id And cd3.Propegated_From_ETDId Is Null
 	  	      Inner Join Event_Reason_Catagories c3 On cd3.ERC_Id = c3.ERC_Id
 	  	      Inner Join Event_Reason_Tree t On td1.Tree_Name_Id = t.Tree_Name_Id
 	  	 WHERE td1.Event_Reason_Level = 1
 	  	 
 	  	 Union
 	  	 SELECT  	 t.Tree_Name, 
 	  	  	 r1.Event_Reason_Name As Reason1, 
 	  	  	 r2.Event_Reason_Name As Reason2,
 	  	  	 r3.Event_Reason_Name As Reason3,
 	  	  	 r4.Event_Reason_Name As Reason4, 
 	  	  	 c4.ERC_Desc As Category
 	  	 FROM Event_Reason_Tree_Data td1
 	  	      Inner Join Event_Reasons r1 On td1.Event_Reason_Id = r1.Event_Reason_Id
 	  	      Inner Join Event_Reason_Tree_Data td2 On td1.Event_Reason_Tree_Data_Id = td2.Parent_Event_R_Tree_Data_Id And td1.Tree_Name_Id = td2.Tree_Name_Id
 	  	      Inner Join Event_Reasons r2 On td2.Event_Reason_Id = r2.Event_Reason_Id
 	  	      Inner Join Event_Reason_Tree_Data td3 On td2.Event_Reason_Tree_Data_Id = td3.Parent_Event_R_Tree_Data_Id And td2.Tree_Name_Id = td3.Tree_Name_Id
 	  	      Inner Join Event_Reasons r3 On td3.Event_Reason_Id = r3.Event_Reason_Id
 	  	      Inner Join Event_Reason_Tree_Data td4 On td3.Event_Reason_Tree_Data_Id = td4.Parent_Event_R_Tree_Data_Id And td3.Tree_Name_Id = td4.Tree_Name_Id
 	  	      Inner Join Event_Reasons r4 On td4.Event_Reason_Id = r4.Event_Reason_Id
 	  	      Inner Join Event_Reason_Category_Data cd4 On td4.Event_Reason_Tree_Data_Id = cd4.Event_Reason_Tree_Data_Id
 	  	      Inner Join Event_Reason_Catagories c4 On cd4.ERC_Id = c4.ERC_Id
 	  	      Inner Join Event_Reason_Tree t On td1.Tree_Name_Id = t.Tree_Name_Id
 	  	 WHERE td1.Event_Reason_Level = 1
 	  	 Order By t.Tree_Name, Reason1, Reason2, Reason3, Reason4
 	 END
ELSE If @DataType = 'AlarmTemplates'
 	 BEGIN
 	  	 SELECT  	 AT_Desc, --AP_Desc,
 	  	  	 Custom_Text, Use_Var_Desc, Use_AT_Desc, Use_Trigger_Desc,pl.PL_Desc, pu.PU_Desc, v.Var_Desc, co.Comparison_Operator_Value, a.DQ_Value, 
 	  	     Cause_Required, crt.Tree_Name, cr1.Event_Reason_Name, cr2.Event_Reason_Name, cr3.Event_Reason_Name, cr4.Event_Reason_Name,
 	  	     Action_Required, art.Tree_Name, ar1.Event_Reason_Name, ar2.Event_Reason_Name, ar3.Event_Reason_Name, ar4.Event_Reason_Name,
 	  	         	 substring(c.Comment,1,255),
 	  	  	 Alarm_Type_Desc = Case 	 When a.Alarm_Type_Id = 1 and a.String_Specification_Setting = 0 Then 'Variable Limits String - (Equal Spec)'
 	  	  	  	  	  	  	  	  	 When a.Alarm_Type_Id = 1 and a.String_Specification_Setting = 1 Then 'Variable Limits String - (Not Equal Spec)'
 	  	  	  	  	  	  	  	  	 When a.Alarm_Type_Id = 1 and a.String_Specification_Setting = 2 Then 'Variable Limits String - (Use Phrase Order)'
 	    	  	  	  	  	  	   ELSE alt.Alarm_Type_Desc END,
 	    	  	 ESignature_Level = Case When a.ESignature_Level = 1 Then 'User Level'
 	    	  	  	  	  	 When a.ESignature_Level = 2 Then 'Approver Level'
 	    	  	  	  	  	 ELSE 'Undefined' END,'spLocal_' + a.sp_Name
 	  	  	 FROM Alarm_Templates a
 	  	  	 Left Join Variables_Base   v On v.Var_Id = a.DQ_Var_Id
 	  	  	 Left Join Prod_Units_Base    pu On v.PU_Id = pu.PU_Id
 	  	  	 Left Join PU_Groups pug On v.PUG_Id = pug.PUG_Id
 	  	  	 Left Join Prod_Lines_Base pl On pu.PL_Id = pl.PL_Id
 	  	  	 Left Join Comparison_Operators co On a.DQ_Criteria = co.Comparison_Operator_Id
 	  	  	 Left Join Comments c On a.Comment_Id = c.Comment_Id
 	  	  	 Left Join Event_Reason_Tree crt On a.Cause_Tree_Id = crt.Tree_Name_Id
 	  	  	 Left Join Event_Reasons cr1 On a.Default_Cause1 = cr1.Event_Reason_Id
 	  	  	 Left Join Event_Reasons cr2 On a.Default_Cause2 = cr2.Event_Reason_Id
 	  	  	 Left Join Event_Reasons cr3 On a.Default_Cause3 = cr3.Event_Reason_Id
 	  	  	 Left Join Event_Reasons cr4 On a.Default_Cause4 = cr4.Event_Reason_Id
 	  	  	 Left Join Event_Reason_Tree art On a.Action_Tree_Id = art.Tree_Name_Id
 	  	  	 Left Join Event_Reasons ar1 On a.Default_Action1 = ar1.Event_Reason_Id
 	  	  	 Left Join Event_Reasons ar2 On a.Default_Action2 = ar2.Event_Reason_Id
 	  	  	 Left Join Event_Reasons ar3 On a.Default_Action3 = ar3.Event_Reason_Id
 	  	  	 Left Join Event_Reasons ar4 On a.Default_Action4 = ar4.Event_Reason_Id
 	  	  	 Join Alarm_Types alt on alt.Alarm_Type_Id = a.Alarm_Type_Id
 	  	 WHERE a.Alarm_Type_Id in (1,2,4)
 	 END
ELSE If @DataType = 'AlarmTemplateData'
 	 BEGIN
 	  	 SELECT distinct a.AT_Desc, pl.PL_Desc, pu.PU_Desc,  v.Var_Desc,eg.EG_Desc
 	  	 FROM Alarm_Template_Var_Data av
 	  	      Join Alarm_Templates a On a.AT_Id = av.AT_Id
 	  	      Join Variables_Base   v On v.Var_Id = av.Var_Id
 	  	      Join Prod_Units_Base    pu On pu.PU_Id = v.PU_Id
 	  	      Join Prod_Lines_Base pl On pl.PL_Id = pu.PL_Id
 	  	  	  LEFT Join Email_Groups 	 eg ON eg.EG_Id = av.EG_Id
 	  	  	  Order by AT_Desc,pl.PL_Desc,pu.PU_Desc
 	 END
ELSE If @DataType = 'AlarmRules'
 	 BEGIN
 	   SELECT 	 at.AT_Desc, 
 	  	  	  	 Rule_Desc = Isnull(ar.Alarm_SPC_Rule_Desc,avr.Alarm_Variable_Rule_Desc),
 	  	  	  	 Priority = IsNull(ap.AP_Desc,ap1.AP_Desc),
 	  	  	  	 SPC_Group_Variable_Type_Desc,
 	  	  	  	 atrd.Firing_Priority,
 	  	  	  	 atrpd.Value,
 	  	  	  	 atrpd.mValue
 	  	 FROM Alarm_Templates at
 	  	 Left Join Alarm_Template_SPC_Rule_Data atrd on atrd.AT_Id = at.AT_Id
 	  	 Left Join alarm_template_variable_rule_data atvrd on atvrd.AT_Id = at.AT_Id
 	  	 Left Join Alarm_Variable_Rules avr on avr.Alarm_Variable_Rule_Id = atvrd.Alarm_Variable_Rule_Id
 	  	 Left Join Alarm_SPC_Rules ar on ar.Alarm_SPC_Rule_Id = atrd.Alarm_SPC_Rule_Id
 	  	 Left Join Alarm_SPC_Rule_Properties arp on arp.Alarm_SPC_Rule_Id = atrd.Alarm_SPC_Rule_Id
 	  	 Left Join Alarm_Priorities ap On atrd.AP_Id = ap.AP_Id
 	  	 Left Join Alarm_Priorities ap1 On atvrd.AP_Id = ap1.AP_Id
 	  	 LEFT JOIN SPC_Group_Variable_Types sgv ON atrd.SPC_Group_Variable_Type_Id = sgv.SPC_Group_Variable_Type_Id
 	  	 Left Join Alarm_Template_SPC_Rule_Property_Data atrpd on atrpd.Alarm_SPC_Rule_Property_Id = arp.Alarm_SPC_Rule_Property_Id and atrpd.ATSRD_Id = atrd.ATSRD_Id
 	  	 WHERE ar.Alarm_SPC_Rule_Desc is not null or avr.Alarm_Variable_Rule_Desc is not null
 	  	 Order By at.AT_Desc,  atrd.Firing_Priority,ar.Alarm_SPC_Rule_Desc, arp.Alarm_SPC_Rule_Property_Desc, atrpd.Value, atrpd.mValue
 	 END
ELSE If @DataType = 'CrewSchedule'
 	 BEGIN
    SELECT @Sql = 'SELECT PL_Desc,PU_Desc,Crew_Desc,Shift_Desc,Start_Time,End_Time,Substring(c.Comment,1,255)'
    SELECT @Sql = @Sql + ' FROM Crew_Schedule cs'
    SELECT @Sql = @Sql + ' Join Prod_Units_Base    pu On pu.PU_Id = cs.PU_Id'
    SELECT @Sql = @Sql + ' Join Prod_Lines_Base pl On pl.PL_Id = pu.PL_Id'
 	  	 SELECT @Sql = @Sql + ' Left Join Comments c on c.comment_Id = cs.comment_Id'
    If @QueryType = 1
      BEGIN
        SELECT @Sql = @Sql + ' WHERE  pu.PU_Id = ' + Convert(nVarChar(10), @Id)
      END
    If @QueryType = 2
      BEGIN
        SELECT @Sql = @Sql + ' WHERE  pu.PU_Id <> 0 and Master_Unit is NULL'
      END
 	  	 If @EndTime is null
      BEGIN
   	  	   SELECT @Sql = @Sql + ' and Start_Time > ''' + Convert(nVarChar(25),@StartTime,120) + ''''
      END
 	   ELSE 	 
      BEGIN
   	  	   SELECT @Sql = @Sql + ' and Start_Time Between ''' + Convert(nvarchar(25), @StartTime,120) + ''' and ''' + Convert(nVarChar(25),@EndTime,120) + ''''
      END
 	  	 Execute(@Sql)
 	 END
ELSE If @DataType = 'NonProductiveSchedule'
 	 BEGIN
    SELECT @Sql = 'SELECT PL_Desc,PU_Desc,Start_Time,End_Time,Tree_Name,e1.Event_Reason_Name,e2.Event_Reason_Name,e3.Event_Reason_Name,e4.Event_Reason_Name,Substring(c.Comment,1,255)'
    SELECT @Sql = @Sql + ' FROM NonProductive_Detail npd'
    SELECT @Sql = @Sql + ' Join Prod_Units_Base    pu On pu.PU_Id = npd.PU_Id'
    SELECT @Sql = @Sql + ' Join Prod_Lines_Base pl On pl.PL_Id = pu.PL_Id'
    SELECT @Sql = @Sql + ' Left Join Event_Reason_Tree ert On ert.Tree_Name_Id = pu.Non_Productive_Reason_Tree'
    SELECT @Sql = @Sql + ' Left Join Event_Reasons e1 On e1.Event_Reason_Id = npd.Reason_Level1'
    SELECT @Sql = @Sql + ' Left Join Event_Reasons e2 On e2.Event_Reason_Id = npd.Reason_Level2'
    SELECT @Sql = @Sql + ' Left Join Event_Reasons e3 On e3.Event_Reason_Id = npd.Reason_Level3'
    SELECT @Sql = @Sql + ' Left Join Event_Reasons e4 On e4.Event_Reason_Id = npd.Reason_Level4'
    SELECT @Sql = @Sql + ' Left Join Comments c on c.comment_Id = npd.comment_Id'
    If @QueryType = 1
      BEGIN
        SELECT @Sql = @Sql + ' WHERE  pu.PU_Id = ' + Convert(nVarChar(10), @Id)
      END
    If @QueryType = 2
      BEGIN
        SELECT @Sql = @Sql + ' WHERE  pu.PU_Id <> 0 and Master_Unit is NULL'
      END
 	  	 If @EndTime is null
      BEGIN
   	  	   SELECT @Sql = @Sql + ' and Start_Time > ''' + Convert(nVarChar(25),@StartTime,120) + ''''
      END
 	   ELSE 	 
      BEGIN
   	  	   SELECT @Sql = @Sql + ' and Start_Time Between ''' + Convert(nvarchar(25), @StartTime,120) + ''' and ''' + Convert(nVarChar(25),@EndTime,120) + ''''
      END
 	  	 Execute(@Sql)
 	 END
ELSE If @DataType = 'ProductionLines'
 	 BEGIN
 	  	 SELECT @Sql =  'SELECT d.Dept_Desc,pl.PL_Desc, pl.External_Link, pl.Extended_Info, sg.Group_Desc'
 	  	 SELECT @Sql = @Sql +  ' FROM Prod_Lines_Base pl'
 	  	 SELECT @Sql = @Sql +  ' Left Join  Departments_Base  d On d.Dept_Id = pl.Dept_Id'
 	  	 SELECT @Sql = @Sql +  ' Left Join Security_Groups sg on pl.Group_Id = sg.Group_Id'
 	  	 SELECT @Sql = @Sql +  ' WHERE pl.PL_Id > 0'
 	  	 If  @QueryType = 2
 	  	   BEGIN
 	  	  	 SELECT @Sql = @Sql + ' and d.Dept_Id = ' + Convert(nVarChar(10),@Id)
 	  	   END
 	  	 SELECT @Sql = @Sql +  ' Order By d.Dept_Desc,pl.PL_Desc'
 	  	 Execute(@Sql)
 	 END
ELSE If @DataType = 'ProductionGroups'
 	 BEGIN
 	  	 SELECT @Sql = 'SELECT pl.PL_Desc, pu.PU_Desc, pug.PUG_Desc, pug.External_Link, sg.Group_Desc'
 	  	 SELECT @Sql = @Sql + ' FROM PU_Groups pug'
 	   	 SELECT @Sql = @Sql + ' Join Prod_Units_Base    pu on pug.PU_Id = pu.PU_Id'
 	   	 SELECT @Sql = @Sql + ' Join Prod_Lines_Base pl on pu.PL_id = pl.PL_id'
 	   	 SELECT @Sql = @Sql + ' Join  Departments_Base  d on d.Dept_id = pl.Dept_id'
 	   	 SELECT @Sql = @Sql + ' Left Join Security_Groups sg on pug.Group_Id = sg.Group_Id'
 	  	 SELECT @Sql = @Sql + ' WHERE pug.pug_id > 0 and PUG_Desc <> ''Model 5014 Calculation'' '
 	  	 If  @QueryType = 2
 	  	   BEGIN
 	  	  	 SELECT @Sql = @Sql + ' and pl.PL_Id = ' + Convert(nVarChar(10),@Id)
 	  	   END
 	  	 If  @QueryType = 3
 	  	   BEGIN
 	  	  	 SELECT @Sql = @Sql + ' and pu.PU_Id = ' + Convert(nVarChar(10),@Id)
 	  	   END
 	  	 If  @QueryType = 4
 	  	   BEGIN
 	  	  	 SELECT @Sql = @Sql + ' and d.Dept_Id = ' + Convert(nVarChar(10),@Id)
 	  	   END
 	  	 SELECT  @Sql = @Sql + ' Order By pl.PL_Desc,Isnull(pu.PU_Order,255), pu.PU_Desc, pug.PUG_Order,pug.PUG_Desc'
 	  	 Execute(@Sql)
 	 END
ELSE If @DataType = 'ProductProperties'
 	 BEGIN
 	  	 SELECT  	 pp.Prop_Desc,pp.External_Link,sg.Group_Desc
 	  	 FROM Product_Properties pp
      	 Left Join Security_Groups sg On pp.Group_Id = sg.Group_Id
 	  	 Order by Prop_Desc
 	 END
ELSE If @DataType = 'EventReasons'
 	 BEGIN
 	  	 SELECT  r.Event_Reason_Name, r.Event_Reason_Name, Convert(Bit,r.Comment_Required), r.Event_Reason_Code, sg.Group_Desc,r.External_Link
 	  	 FROM Event_Reasons r
       	          Left Join Security_Groups sg On r.Group_Id = sg.Group_Id
 	  	 Order by r.Event_Reason_Name
 	 END
ELSE If @DataType = 'VariableCalculations'
  BEGIN 
 /* Calculations */
 	 Create Table #Calcs (PL_Desc nvarchar(50),PU_Desc nvarchar(50),Var_Desc nvarchar(50),DS_Desc nvarchar(50),
 	  	  	  	  	  	  PL_Des2 nvarchar(50),PU_Des2 nvarchar(50),Var_Des2 nvarchar(50),C_Name nvarchar(255),
 	  	  	  	  	      C_Description nvarchar(255),C_Type nVarChar(100),Equation nvarchar(255),Trigger_Type nVarChar(100),
 	  	  	  	  	   	  Lag_Time Int,Max_Run_Time Int,Alias nVarChar(100),Input_Name nVarChar(100),Entity nVarChar(100),
 	  	  	  	  	  	  Attribute nVarChar(100),Input_Order Int,Default_Value nvarchar(1000), 	 Optional Bit,Sp_Name nvarchar(255),
 	  	  	  	  	   	  Script 	 nvarchar(20),Comment nvarchar(255),Constant nvarchar(1000),Orderby Int,Calc_Id Int,OptimizeCalc Bit,C_Version nVarChar(10),NonTriggering Bit)
 	 Create Table #CalcId (Calc_Id Int)
 	 SELECT @SQL = 'SELECT pl.PL_Desc,pu.PU_Desc,v.Var_Desc,ds.DS_Desc,null,null,null,'
 	 SELECT @SQL = @SQL + 'c.Calculation_Name,c.Calculation_Desc,ct.Calculation_Type_Desc,c.Equation,ctt.Name,'
 	 SELECT @SQL = @SQL + 'c.Lag_Time,c.Max_Run_Time,null,null,null,null,null,null,null,'
 	 SELECT @SQL = @SQL + 'c.Stored_Procedure_Name,Script = case When c.Calculation_Type_Id = 3 then Char(2) + convert(nVarChar(10), c.Calculation_Id) ELSE null END, REPLACE(substring(cm.Comment_Text,1,255),char(13) + char(10),char(10)),Null,3,c.Calculation_Id,Optimize_Calc_Runs,Version,Null'
 	 SELECT @SQL = @SQL + ' FROM Variables_Base   v'
 	 SELECT @SQL = @SQL + ' Join Prod_Units_Base    pu On pu.PU_Id = v.PU_Id'
 	 SELECT @SQL = @SQL + ' Join Prod_Lines_Base pl On Pl.PL_Id = pu.PL_Id'
 	 SELECT @SQL = @SQL + ' Join  Departments_Base  d On Pl.Dept_Id = d.Dept_Id'
 	 SELECT @SQL = @SQL + ' Join Data_Source ds on ds.DS_Id = v.DS_Id'
 	 SELECT @SQL = @SQL + ' Join Calculations c On v.Calculation_Id = c.Calculation_Id and (c.Calculation_Desc  Not In (''MSI_Calc_Downtime'',''MSI_Calc_Waste'',''MSI_Calc_Efficiency'',''MSI_Calc_Production''))'
 	 SELECT @SQL = @SQL + ' Join Calculation_Types ct On c.Calculation_Type_Id = ct.Calculation_Type_Id'
 	 SELECT @SQL = @SQL + ' Join Calculation_Trigger_Types ctt On c.Trigger_Type_Id = ctt.Trigger_Type_Id'
 	 SELECT @SQL = @SQL + ' Left Join Comments cm On cm.Comment_Id = c.Comment_Id'
 	 SELECT @SQL = @SQL + ' WHERE v.PU_Id <> 0 And (v.system = 0 or v.system Is Null) And v.DS_Id = 16 And v.Calculation_Id Is Not Null'
 	 If @QueryType = 2 /* By Group */
 	   SELECT @SQL = @SQL + ' And v.PUG_Id = ' + Convert(nVarChar(10),@Id)
 	 ELSE If @QueryType = 3 /* By Unit */
 	   SELECT @SQL = @SQL + '  And  v.PU_Id = ' + Convert(nVarChar(10),@Id)  
 	 ELSE If @QueryType = 4 /* By Line */
 	   SELECT @SQL = @SQL + '  And  pl.PL_Id = ' + Convert(nVarChar(10),@Id) 
 	 ELSE If @QueryType = 5 /* By Department */
 	   SELECT @SQL = @SQL + '  And  d.Dept_Id = ' + Convert(nVarChar(10),@Id) 
 	 INSERT INTO #Calcs
 	  	 Execute (@Sql)
 	 INSERT INTO #CalcId 
 	    SELECT Distinct Calc_Id FROM #Calcs
/* Calculation Dependency */
 	 SELECT @SQL =  ' SELECT pl.PL_Desc,pu.PU_Desc,v.Var_Desc,''Calculation Dependency'',pl1.PL_Desc,pu1.PU_Desc,v1.Var_Desc,'
 	 SELECT @SQL = @SQL + 'c.Calculation_Name,Null,Null,Null,Null,'
 	 SELECT @SQL = @SQL + 'Null,Null,null,cd.Name,null,cds.Calc_Dependency_Scope_Name,null,null,cd.Optional,'
 	 SELECT @SQL = @SQL + 'Null,Null,Null,Null,5,c.Calculation_Id,Null,Null,Null'
 	 SELECT @SQL = @SQL + ' FROM Variables_Base   v'
 	 SELECT @SQL = @SQL + ' Join Calculation_Dependency_Data cdd  On cdd.Result_Var_Id = v.Var_Id'
 	 SELECT @SQL = @SQL + ' Join Calculation_Dependencies cd On cd.Calc_Dependency_Id = cdd.Calc_Dependency_Id' 
 	 SELECT @SQL = @SQL + ' Join Calculation_Dependency_Scopes cds On cd.Calc_Dependency_Scope_Id = cds.Calc_Dependency_Scope_Id'
 	 SELECT @SQL = @SQL + ' Join Variables_Base   v1 On cdd.Var_Id = v1.Var_Id'
 	 SELECT @SQL = @SQL + ' Join Prod_Units_Base    pu1 On v1.PU_Id = pu1.PU_Id'
 	 SELECT @SQL = @SQL + ' Join Prod_Lines_Base pl1 On pu1.PL_Id = pl1.PL_Id'
 	 SELECT @SQL = @SQL + ' Join Prod_Units_Base    pu On pu.PU_Id = v.PU_Id'
 	 SELECT @SQL = @SQL + ' Join Prod_Lines_Base pl On Pl.PL_Id = pu.PL_Id'
 	 SELECT @SQL = @SQL + ' Join  Departments_Base  d On Pl.Dept_Id = d.Dept_Id'
 	 SELECT @SQL = @SQL + ' Join Calculations c On v.Calculation_Id = c.Calculation_Id'
 	 SELECT @SQL = @SQL + ' Join #CalcId c1 On c1.Calc_Id = c.Calculation_Id'
 	 INSERT INTO #Calcs
 	  	 Execute (@Sql)
/* Additional Dependency */
 	 SELECT @SQL = ' SELECT pl.PL_Desc,pu.PU_Desc,v.Var_Desc,''Additional Dependency'',pl1.PL_Desc,pu1.PU_Desc,v1.Var_Desc,'
 	 SELECT @SQL = @SQL + 'c.Calculation_Name,Null,Null,Null,Null,'
 	 SELECT @SQL = @SQL + 'Null,Null,null,null,null,cds.Calc_Dependency_Scope_Name,null,null,Null,'
 	 SELECT @SQL = @SQL + 'Null,Null,Null,Null,6,c.Calculation_Id,Null,Null,Null'
 	 SELECT @SQL = @SQL + ' FROM Variables_Base   v'
 	 SELECT @SQL = @SQL + ' Join Calculations c On v.Calculation_Id = c.Calculation_Id'
 	 SELECT @SQL = @SQL + ' Join Calculation_Instance_Dependencies cid  On cid.Result_Var_Id = v.Var_Id'
 	 SELECT @SQL = @SQL + ' Join Calculation_Dependency_Scopes cds On cid.Calc_Dependency_Scope_Id = cds.Calc_Dependency_Scope_Id'
 	 SELECT @SQL = @SQL + ' Join Variables_Base   v1 On cid.Var_Id = v1.Var_Id'
 	 SELECT @SQL = @SQL + ' Join Prod_Units_Base    pu1 On v1.PU_Id = pu1.PU_Id'
 	 SELECT @SQL = @SQL + ' Join Prod_Lines_Base pl1 On pu1.PL_Id = pl1.PL_Id'
 	 SELECT @SQL = @SQL + ' Join Prod_Units_Base    pu On pu.PU_Id = v.PU_Id'
 	 SELECT @SQL = @SQL + ' Join Prod_Lines_Base pl On Pl.PL_Id = pu.PL_Id'
 	 SELECT @SQL = @SQL + ' Join  Departments_Base  d On Pl.Dept_Id = d.Dept_Id'
 	 SELECT @SQL = @SQL + ' Join #CalcId c1 On c1.Calc_Id = c.Calculation_Id'
 	 If  @QueryType = 1
 	  	 SELECT @SQL = @SQL + ' WHERE v.PU_Id <> 0 and v1.PU_Id <> 0'
 	 ELSE If @QueryType = 2 /* By Group */
 	   SELECT @SQL = @SQL + ' WHERE v.PUG_Id = ' + Convert(nVarChar(10),@Id) 
 	 ELSE If @QueryType = 3 /* By Unit */
 	   SELECT @SQL = @SQL + ' WHERE pu.PU_Id = ' + Convert(nVarChar(10),@Id)
 	 ELSE If @QueryType = 4 /* By Line */
 	   SELECT @SQL = @SQL + ' WHERE pl.PL_Id = ' + Convert(nVarChar(10),@Id)
 	 ELSE If @QueryType = 5 /* By Department */
 	   SELECT @SQL = @SQL + ' WHERE d.Dept_Id = ' + Convert(nVarChar(10),@Id)
 	 INSERT INTO #Calcs
 	  	 Execute (@Sql)
/* Aliased */
 	 SELECT @SQL =  ' SELECT pl.PL_Desc,pu.PU_Desc,v.Var_Desc,''Aliased'',pl2.PL_Desc,pu2.PU_Desc,v2.Var_Desc,'
 	 SELECT @SQL = @SQL + 'Null,Null,Null,Null,Null,'
 	 SELECT @SQL = @SQL + 'Null,Null,null,null,null,Null,null,null,Null,'
 	 SELECT @SQL = @SQL + 'Null,Null,Null,Null,1,null,Null,Null,Null'
 	 SELECT @SQL = @SQL + ' FROM Variable_Alias va'
 	 SELECT @SQL = @SQL + ' Join Variables_Base   v On v.Var_Id = va.Dst_Var_Id'
 	 SELECT @SQL = @SQL + ' Join Variables_Base   v2 On v2.Var_Id = va.Src_Var_Id'
 	 SELECT @SQL = @SQL + ' Join Prod_Units_Base    pu On v.PU_Id = pu.PU_Id'
 	 SELECT @SQL = @SQL + ' Join Prod_Lines_Base pl On pu.PL_Id = pl.PL_Id'
 	 SELECT @SQL = @SQL + ' Join  Departments_Base  d On d.dept_Id = pl.Dept_Id'
 	 SELECT @SQL = @SQL + ' Join Prod_Units_Base    pu2 On pu2.PU_Id = v2.PU_Id'
 	 SELECT @SQL = @SQL + ' Join Prod_Lines_Base pl2 On Pl2.PL_Id = pu2.PL_Id'
 	 If  @QueryType = 1
 	  	 SELECT @SQL = @SQL + ' WHERE pu.PU_Id <> 0 and pu2.PU_Id <> 0'
 	 ELSE If @QueryType = 2 /* By Group */
 	   SELECT @SQL = @SQL + ' WHERE v.PUG_Id = ' + Convert(nVarChar(10),@Id) 
 	 ELSE If @QueryType = 3 /* By Unit */
 	   SELECT @SQL = @SQL + ' WHERE pu.PU_Id = ' + Convert(nVarChar(10),@Id)
 	 ELSE If @QueryType = 4 /* By Line */
 	   SELECT @SQL = @SQL + ' WHERE pl.PL_Id = ' + Convert(nVarChar(10),@Id)
 	 ELSE If @QueryType = 5 /* By Department */
 	   SELECT @SQL = @SQL + ' WHERE d.Dept_Id = ' + Convert(nVarChar(10),@Id)
 	 INSERT INTO #Calcs
 	  	 Execute (@Sql)
/* Calculation Inputs */
 	 SELECT @SQL = ' SELECT pl.PL_Desc,pu.PU_Desc,v.Var_Desc,''Calculation Input'',pl1.PL_Desc,pu1.PU_Desc,v1.Var_Desc,'
 	 SELECT @SQL = @SQL + 'c.Calculation_Name,Null,Null,Null,Null,'
 	 SELECT @SQL = @SQL + 'Null,Null,ci.Alias,ci.Input_Name,cie.Entity_Name,cia.Attribute_Name,ci.Calc_Input_Order,ci.Default_Value,ci.Optional,'
 	 SELECT @SQL = @SQL + 'Null,Null,Null,cid.Default_Value,4,c.Calculation_Id,Null,Null,ci.Non_Triggering'
 	 SELECT @SQL = @SQL + ' FROM Variables_Base   v'
 	 SELECT @SQL = @SQL + ' Join Calculations c On c.Calculation_Id = v.Calculation_Id'
 	 SELECT @SQL = @SQL + ' Join #CalcId c1 On c1.Calc_Id = v.Calculation_Id'
 	 SELECT @SQL = @SQL + ' Join Calculation_Inputs ci On ci.Calculation_Id =  c.Calculation_Id'
 	 SELECT @SQL = @SQL + ' Left Join Calculation_Input_Data cid  on ci.Calc_Input_Id = cid.Calc_Input_Id and cid.Result_Var_Id = v.Var_Id'
 	 SELECT @SQL = @SQL + ' Left Join Calculation_Input_Entities cie On ci.Calc_Input_Entity_Id = cie.Calc_Input_Entity_Id'
 	 SELECT @SQL = @SQL + ' Left Join Calculation_Input_Attributes cia On ci.Calc_Input_Attribute_Id = cia.Calc_Input_Attribute_Id'
 	 SELECT @SQL = @SQL + ' left Join Variables_Base   v1 On cid.Member_Var_Id = v1.Var_Id'
 	 SELECT @SQL = @SQL + ' left Join Prod_Units_Base    pu1 On v1.PU_Id = pu1.PU_Id'
 	 SELECT @SQL = @SQL + ' left Join Prod_Lines_Base pl1 On pu1.PL_Id = pl1.PL_Id'
 	 SELECT @SQL = @SQL + ' left Join Prod_Units_Base    pu On pu.PU_Id = v.PU_Id'
 	 SELECT @SQL = @SQL + ' left Join Prod_Lines_Base pl On Pl.PL_Id = pu.PL_Id'
 	 SELECT @SQL = @SQL + ' left Join  Departments_Base  d On d.Dept_Id = pl.Dept_Id'
 	 If  @QueryType = 1
 	  	 SELECT @SQL = @SQL + ' WHERE pu1.PU_Id <> 0 '
 	 ELSE If @QueryType = 2 /* By Group */
 	   SELECT @SQL = @SQL + ' WHERE v.PUG_Id = ' + Convert(nVarChar(10),@Id)
 	 ELSE If @QueryType = 3 /* By Unit */
 	   SELECT @SQL = @SQL + ' WHERE pu.PU_Id = ' + Convert(nVarChar(10),@Id)
 	 ELSE If @QueryType = 4 /* By Line */
 	   SELECT @SQL = @SQL + ' WHERE pl.PL_Id = ' + Convert(nVarChar(10),@Id)
 	 ELSE If @QueryType = 5 /* By Dept */
 	   SELECT @SQL = @SQL + ' WHERE d.Dept_Id = ' + Convert(nVarChar(10),@Id)
 	 INSERT INTO #Calcs
 	  	 Execute (@Sql)
 	 SELECT PL_Desc,PU_Desc,Var_Desc,DS_Desc,PL_Des2,PU_Des2,Var_Des2,C_Name,C_Description,C_Type,Equation,Trigger_Type,
 	  	  	  	  	   	  Lag_Time,Max_Run_Time,Alias,Input_Name,Entity,Attribute,Input_Order,Default_Value,Optional,Sp_Name,
 	  	  	  	  	   	  Script,Comment,Constant,OptimizeCalc,C_Version,nonTriggering
 	 FROM #Calcs
 	 Order by  Calc_Id,PL_Desc,PU_Desc,Var_Desc,Orderby,Input_Order
  END 
ELSE If @DataType = 'DisplayOptions'
 	 BEGIN
 	   Create Table #Temp ([Id] Int,[Desc] nVarChar(100))
 	  INSERT INTO #Temp  
 	   SELECT Distinct ES.Event_SubType_Id, ES.Event_SubType_Desc
 	    FROM Event_SubTypes ES 
 	    Join Event_Types ET on ES.ET_Id = ET.ET_Id
 	     WHERE ET.IncludeOnSoe = 1 And ET.SubTypes_Apply = 1
 	  INSERT INTO #Temp
 	   SELECT  Distinct (-1* ET.ET_Id) , ET.ET_Desc 
 	  	 FROM Event_Types ET  
 	      WHERE ET.IncludeOnSoe = 1  And ET.SubTypes_Apply = 0    And ET_Id <> 11
 	  
 	  If (SELECT IncludeOnSoe FROM Event_Types WHERE ET_Id = 11) = 1
 	   BEGIN
 	    Declare @AlarmEventDescription nVarChar(100)
 	    SELECT @AlarmEventDescription = Et_Desc FROM Event_Types WHERE ET_ID = 11
 	    INSERT INTO #Temp   SELECT  -10000, @AlarmEventDescription + ' Low'
 	    INSERT INTO #Temp   SELECT  -10001, @AlarmEventDescription + ' Medium'
 	    INSERT INTO #Temp   SELECT  -10002, @AlarmEventDescription + ' High'
 	   END 
 	   Create Table #Conf (ID int, Conf_Desc nvarchar(20))
 	     INSERT INTO #Conf(ID,Conf_Desc) Values(6,'Cross')
 	     INSERT INTO #Conf(ID,Conf_Desc) Values(7,'Diagonal Cross')
 	     INSERT INTO #Conf(ID,Conf_Desc) Values(5,'Downward Diagonal')
 	     INSERT INTO #Conf(ID,Conf_Desc) Values(2,'Horizontal')
 	     INSERT INTO #Conf(ID,Conf_Desc) Values(1,'Transparent')
 	     INSERT INTO #Conf(ID,Conf_Desc) Values(4,'Upward Diagonal')
 	     INSERT INTO #Conf(ID,Conf_Desc) Values(3,'Vertical')
 	   SELECT @Sql = 'SELECT s.Sheet_Desc,do.Display_Option_Desc,Value_Text = '
 	   SELECT @Sql = @Sql + 'CASE  When  Field_Type_Id = 22 and isnull(sdo.Value,st.Display_Option_Default) = 1 Then ''TRUE'''
 	   SELECT @Sql = @Sql + ' When  Field_Type_Id = 22 and isnull(sdo.Value,st.Display_Option_Default) = 0 Then ''FALSE'''
 	   SELECT @Sql = @Sql + ' When  Field_Type_Id = 8 Then (SELECT ST_Desc FROM Sampling_Type WHERE ST_Id = isnull(sdo.Value,st.Display_Option_Default))'
 	   SELECT @Sql = @Sql + ' When  Field_Type_Id = 9 Then (SELECT Pu_Desc FROM Prod_Units_Base    WHERE pu_Id = isnull(sdo.Value,st.Display_Option_Default))'
 	   SELECT @Sql = @Sql + ' When  Field_Type_Id = 10 Then (SELECT PL_Desc + ''|'' + PU_Desc + ''|'' + Var_Desc FROM Variables_Base   v Join Prod_Units_Base    pu On pu.pu_Id = v.PU_Id Join Prod_Lines_Base pl on pl.pl_Id = pu.PL_Id WHERE Var_Id = isnull(sdo.Value,st.Display_Option_Default))'
 	   SELECT @Sql = @Sql + ' When  Field_Type_Id = 13 Then (SELECT WET_Name FROM Waste_Event_Type WHERE WET_Id = isnull(sdo.Value,st.Display_Option_Default))'
 	   SELECT @Sql = @Sql + ' When  Field_Type_Id = 14 Then (SELECT WEMT_Name FROM Waste_Event_Meas WHERE WEMT_Id = isnull(sdo.Value,st.Display_Option_Default))'
 	   SELECT @Sql = @Sql + ' When  Field_Type_Id = 15 Then (SELECT Event_Reason_Name FROM Event_Reasons WHERE Event_Reason_Id = isnull(sdo.Value,st.Display_Option_Default))'
 	   SELECT @Sql = @Sql + ' When  Field_Type_Id = 16 Then (SELECT ProdStatus_Desc FROM Production_Status WHERE ProdStatus_Id = isnull(sdo.Value,st.Display_Option_Default))'
 	   SELECT @Sql = @Sql + ' When  Field_Type_Id = 23 Then (SELECT Char_Desc FROM Characteristics WHERE Char_Id = isnull(sdo.Value,st.Display_Option_Default))'
 	   SELECT @Sql = @Sql + ' When  Field_Type_Id = 24 Then (SELECT CS_Desc FROM Color_Scheme WHERE CS_Id = isnull(sdo.Value,st.Display_Option_Default))'
 	   SELECT @Sql = @Sql + ' When  Field_Type_Id = 27 Then (SELECT [Desc] FROM #Temp WHERE Id = isnull(sdo.Value,st.Display_Option_Default))'
 	   SELECT @Sql = @Sql + ' When  Field_Type_Id = 28 Then (SELECT CONVERT(nvarchar(255), isnull(sdo.Value,st.Display_Option_Default)))'
 	   SELECT @Sql = @Sql + ' When  Field_Type_Id = 29 Then (SELECT Tree_Statistic_Desc FROM Tree_Statistics WHERE Tree_Statistic_Id = isnull(sdo.Value,st.Display_Option_Default))'
 	   SELECT @Sql = @Sql + ' When  Field_Type_Id = 30 Then (SELECT AL_Desc FROM Access_Level WHERE Al_Id = isnull(sdo.Value,st.Display_Option_Default))'
 	   SELECT @Sql = @Sql + ' When  Field_Type_Id = 31 Then (SELECT Conf_Desc FROM #Conf WHERE Id = isnull(sdo.Value,st.Display_Option_Default))'
  	   SELECT @Sql = @Sql + ' When  Field_Type_Id = 34 Then (SELECT Color_Desc FROM Colors WHERE Color_Id = isnull(sdo.Value,st.Display_Option_Default))'
  	   SELECT @Sql = @Sql + ' When  Field_Type_Id = 39 Then (SELECT Tree_Name FROM Event_Reason_Tree WHERE Tree_Name_Id = isnull(sdo.Value,st.Display_Option_Default))'
 	   SELECT @Sql = @Sql + ' When  Field_Type_Id = 40 Then (SELECT Event_Reason_Name FROM Event_Reasons WHERE Event_Reason_Id = isnull(sdo.Value,st.Display_Option_Default))'
 	   SELECT @Sql = @Sql + ' ELSE  isnull(sdo.value,st.Display_Option_Default)'
 	   SELECT @Sql = @Sql + ' END'
 	   SELECT @Sql = @Sql + ' FROM Sheets s'
 	   SELECT @Sql = @Sql + ' Left Join Sheet_Type_Display_Options st on st.Sheet_Type_Id = s.Sheet_Type'
 	   SELECT @Sql = @Sql + ' Join Display_Options do on do.Display_Option_Id = st.Display_Option_Id'
 	   SELECT @Sql = @Sql + ' left Join  Sheet_Display_options sdo on sdo.Sheet_Id = s.Sheet_Id and sdo.Display_Option_Id = do.Display_Option_Id'
 	   SELECT @Sql = @Sql + ' WHERE st.Display_Option_Id <> 159 '
 	   If @QueryType = 2 /* By Group */
 	  	 BEGIN
 	  	   SELECT @SQL = @SQL + ' and s.Sheet_Group_Id = ' + Convert(nVarChar(10),@Id)
 	  	 END
 	   If @QueryType = 3 /* By Sheet */
 	   BEGIN
 	  	 SELECT @SQL = @SQL + ' And s.Sheet_Id = ' + Convert(nVarChar(10),@Id)
 	   END
 	   SELECT @Sql = @Sql + ' Order by s.Sheet_Desc,do.Display_Option_Desc'
 	   Execute(@SQL)
 	 END
ELSE If @DataType = 'UnitLocations'
 	 BEGIN
 	  	 SELECT @Sql = 'SELECT PL.PL_Desc, PU.PU_Desc, UL.Location_Code, UL.Location_Desc, P.Prod_Code,'
 	  	 SELECT @Sql = @Sql + ' UL.Maximum_Items, UL.Maximum_Dimension_X, UL.Maximum_Dimension_Y, UL.Maximum_Dimension_Z, UL.Maximum_Dimension_A, UL.Maximum_Alarm_Enabled,'
 	  	 SELECT @Sql = @Sql + ' UL.Minimum_Items, UL.Minimum_Dimension_X, UL.Minimum_Dimension_Y, UL.Minimum_Dimension_Z, UL.Minimum_Dimension_A, UL.Minimum_Alarm_Enabled,'
 	  	 SELECT @Sql = @Sql + ' UL.Comment_Id'
 	  	 SELECT @Sql = @Sql + ' FROM Unit_Locations UL'
 	  	 SELECT @Sql = @Sql + ' Join Prod_Units_Base    PU on PU.PU_Id = UL.PU_Id'
 	  	 SELECT @Sql = @Sql + ' Join Prod_Lines_Base PL on PL. PL_Id = PU.PL_Id'
 	  	 SELECT @Sql = @Sql + ' Left Outer Join Products_Base   P on P.Prod_Id = UL.Prod_Id'
 	  	 SELECT @Sql = @Sql + ' WHERE UL.PU_Id = ' + Convert(nVarChar(10),@Id)
 	  	 SELECT @Sql = @Sql + ' Order By UL.Location_Id ASC'
 	    	 Execute(@SQL)
 	 END
ELSE If @DataType = 'ScheduleStatuses'
 	 BEGIN
 	   SELECT PP_Status_Desc
 	  	 FROM Production_Plan_Statuses
 	  	 Order by PP_Status_Desc
 	 END
ELSE If @DataType = 'ProcessOrder'
 	 BEGIN
 	  	 If @EndTime is null
 	  	  	 SELECT Path_Code,Process_Order,Forecast_Start_Date,Forecast_End_Date,Forecast_Quantity,p.Prod_Code,Implied_Sequence,PP_Status_Desc,Block_Number,
 	  	  	   PP_Type_Name,Production_Rate,Adjusted_Quantity,Predicted_Total_Duration,
 	  	  	   ct.Control_Type_Desc,pp.Extended_Info,pp.User_General_1,pp.User_General_2,pp.User_General_3,REPLACE(substring(c.Comment_Text,1,255),char(13) + char(10),char(10))
 	  	  	  FROM Production_Plan pp
 	  	  	  Left Join Products_Base   p on p.Prod_Id =  pp.Prod_Id
 	  	  	  Left Join Production_Plan_statuses pps On pps.PP_Status_Id = pp.PP_Status_Id
 	  	  	  Left Join Production_Plan_Types ppt on pp.PP_Type_Id = ppt.PP_Type_Id
 	  	  	  Left Join comments c on c.comment_Id = pp.comment_Id
 	  	  	  Left Join Prdexec_Paths pep on pep.Path_Id = pp.Path_Id 
       Left Outer Join Control_Type ct on ct.Control_Type_Id = pp.Control_Type
 	  	  	  WHERE  Forecast_Start_Date > @StartTime
         Order by Path_Code, Process_Order
 	  	 ELSE 	 
 	  	  	 SELECT Path_Code,Process_Order,Forecast_Start_Date,Forecast_End_Date,Forecast_Quantity,p.Prod_Code,Implied_Sequence,PP_Status_Desc,Block_Number,
 	  	  	   PP_Type_Name,Production_Rate,Adjusted_Quantity,Predicted_Total_Duration,
 	  	  	   ct.Control_Type_Desc,pp.Extended_Info,pp.User_General_1,pp.User_General_2,pp.User_General_3,REPLACE(substring(c.Comment_Text,1,255),char(13) + char(10),char(10))
 	  	  	  FROM Production_Plan pp
 	  	  	  Left Join Products_Base   p on p.Prod_Id =  pp.Prod_Id
 	  	  	  Left Join Production_Plan_statuses pps On pps.PP_Status_Id = pp.PP_Status_Id
 	  	  	  Left Join Production_Plan_Types ppt on pp.PP_Type_Id = ppt.PP_Type_Id
 	  	  	  Left Join comments c on c.comment_Id = pp.comment_Id
 	  	  	  Left Join Prdexec_Paths pep on pep.Path_Id = pp.Path_Id 
       Left Outer Join Control_Type ct on ct.Control_Type_Id = pp.Control_Type
 	  	  	  WHERE  Forecast_Start_Date Between @StartTime and @EndTime
         Order by Path_Code, Process_Order
 	 END
ELSE If @DataType = 'ProcessOrderSequence'
 	 BEGIN
 	  	 If @EndTime is null
 	  	  	 SELECT pep.Path_Code,pp.Process_Order,ps.Pattern_Code,ps.Implied_Sequence,PP_Status_Desc,ps.Pattern_Repititions,ps.Base_Dimension_A,
 	  	  	  ps.Base_Dimension_X,ps.Base_Dimension_Y,ps.Base_Dimension_Z,ps.Forecast_Quantity,ps.Base_General_1,ps.Base_General_2,
 	  	  	  ps.Base_General_3,ps.Base_General_4,ps.Extended_Info,ps.Shrinkage,ps.Predicted_Total_Duration,ps.User_General_1,
       ps.User_General_2,ps.User_General_3,REPLACE(substring(c.Comment_Text,1,255),char(13) + char(10),char(10))
 	  	  	  FROM Production_Plan pp
 	  	  	  Join production_Setup ps on ps.PP_Id = pp.PP_Id
 	  	  	  Left Join Production_Plan_statuses pps On ps.PP_Status_Id = pps.PP_Status_Id
 	  	  	  Left Join Prdexec_Paths pep on pep.Path_Id = pp.Path_Id 
 	  	  	  Left Join comments c on c.comment_Id = ps.comment_Id
 	  	  	  WHERE  Forecast_Start_Date > @StartTime
         Order by pep.Path_Code, pp.Process_Order, ps.Pattern_Code
 	  	 ELSE 	 
 	  	  	 SELECT pep.Path_Code,pp.Process_Order,ps.Pattern_Code,ps.Implied_Sequence,PP_Status_Desc,ps.Pattern_Repititions,ps.Base_Dimension_A,
 	  	  	  ps.Base_Dimension_X,ps.Base_Dimension_Y,ps.Base_Dimension_Z,ps.Forecast_Quantity,ps.Base_General_1,ps.Base_General_2,
 	  	  	  ps.Base_General_3,ps.Base_General_4,ps.Extended_Info,ps.Shrinkage,ps.Predicted_Total_Duration,ps.User_General_1,ps.User_General_2,ps.User_General_3,REPLACE(substring(c.Comment_Text,1,255),char(13) + char(10),char(10))
 	  	  	  FROM Production_Plan pp
 	  	  	  Join production_Setup ps on ps.PP_Id = pp.PP_Id
 	  	  	  Left Join Production_Plan_statuses pps On ps.PP_Status_Id = pps.PP_Status_Id
 	  	  	  Left Join Prdexec_Paths pep on pep.Path_Id = pp.Path_Id 
 	  	  	  Left Join comments c on c.comment_Id = ps.comment_Id
 	  	  	  WHERE  Forecast_Start_Date Between @StartTime and @EndTime
         Order by pep.Path_Code, pp.Process_Order, ps.Pattern_Code
 	 END
ELSE If @DataType = 'ProcessOrderPattern'
 	 BEGIN
 	  	 If @EndTime is null
 	  	  	 SELECT pep.Path_Code,pp.Process_Order,ps.Pattern_Code,psd.Element_Number,p.Prod_Code,PP_Status_Desc,psd.Target_Dimension_A,psd.Target_Dimension_X,
 	  	  	  psd.Target_Dimension_Y,psd.Target_Dimension_Z,psd.Extended_Info,psd.User_General_1,psd.User_General_2,psd.User_General_3,REPLACE(substring(c.Comment_Text,1,255),char(13) + char(10),char(10))
 	  	  	  FROM Production_Plan pp
 	  	  	  Join production_Setup ps on ps.PP_Id = pp.PP_Id
 	  	  	  Join production_Setup_Detail psd on psd.PP_Setup_Id = ps.PP_Setup_Id
 	  	  	  Left Join Products_Base   p on p.Prod_Id =  psd.Prod_Id
 	  	  	  Left Join Production_Plan_statuses pps On psd.Element_Status = pps.PP_Status_Id
 	  	  	  Left Join Prdexec_Paths pep on pep.Path_Id = pp.Path_Id 
 	  	  	  Left Join comments c on c.comment_Id = psd.comment_Id
 	  	  	  WHERE  Forecast_Start_Date > @StartTime
         Order by pep.Path_Code,pp.Process_Order,ps.Pattern_Code,psd.Element_Number
 	  	 ELSE 	 
 	  	  	 SELECT pep.Path_Code,pp.Process_Order,ps.Pattern_Code,psd.Element_Number,p.Prod_Code,PP_Status_Desc,psd.Target_Dimension_A,psd.Target_Dimension_X,
 	  	  	  psd.Target_Dimension_Y,psd.Target_Dimension_Z,psd.Extended_Info,psd.User_General_1,psd.User_General_2,psd.User_General_3,REPLACE(substring(c.Comment_Text,1,255),char(13) + char(10),char(10))
 	  	  	  FROM Production_Plan pp
 	  	  	  Join production_Setup ps on ps.PP_Id = pp.PP_Id
 	  	  	  Join production_Setup_Detail psd on psd.PP_Setup_Id = ps.PP_Setup_Id
 	  	  	  Left Join Products_Base   p on p.Prod_Id =  psd.Prod_Id
 	  	  	  Left Join Production_Plan_statuses pps On psd.Element_Status = pps.PP_Status_Id
 	  	  	  Left Join Prdexec_Paths pep on pep.Path_Id = pp.Path_Id 
 	  	  	  Left Join comments c on c.comment_Id = psd.comment_Id
 	  	  	  WHERE  Forecast_Start_Date Between @StartTime and @EndTime
         Order by pep.Path_Code,pp.Process_Order,ps.Pattern_Code,psd.Element_Number
 	 END
ELSE If @DataType = 'EventReasonTree'
 	 BEGIN
 	   If @QueryType = 2
 	  	   SELECT ert.Tree_Name,r.Event_Reason_Name,r2.Event_Reason_Name,r3.Event_Reason_Name,r4.Event_Reason_Name,convert(bit,0)
 	  	     FROM event_reason_tree_data d
 	  	  	 Join Event_Reason_Tree ert on ert.Tree_Name_Id = d.Tree_Name_Id
 	  	  	 left join event_reason_tree_data d2 on d2.Parent_Event_R_Tree_Data_Id = d.Event_Reason_Tree_Data_Id
 	  	  	 left join event_reason_tree_data d3 on d3.Parent_Event_R_Tree_Data_Id = d2.Event_Reason_Tree_Data_Id
 	  	  	 left join event_reason_tree_data d4 on d4.Parent_Event_R_Tree_Data_Id = d3.Event_Reason_Tree_Data_Id
 	  	     join event_reasons r on d.event_reason_id = r.event_reason_id
 	  	     Left join event_reasons r2 on d2.event_reason_id = r2.event_reason_id
 	  	     Left join event_reasons r3 on d3.event_reason_id = r3.event_reason_id
 	  	     Left join event_reasons r4 on d4.event_reason_id = r4.event_reason_id
 	  	     WHERE  d.Event_Reason_Level = 1
 	   ELSE
 	  	   SELECT ert.Tree_Name,r.Event_Reason_Name,r2.Event_Reason_Name,r3.Event_Reason_Name,r4.Event_Reason_Name,convert(bit,0)
 	  	     FROM event_reason_tree_data d
 	  	  	 Join Event_Reason_Tree ert on ert.Tree_Name_Id = d.Tree_Name_Id
 	  	  	 left join event_reason_tree_data d2 on d2.Parent_Event_R_Tree_Data_Id = d.Event_Reason_Tree_Data_Id
 	  	  	 left join event_reason_tree_data d3 on d3.Parent_Event_R_Tree_Data_Id = d2.Event_Reason_Tree_Data_Id
 	  	  	 left join event_reason_tree_data d4 on d4.Parent_Event_R_Tree_Data_Id = d3.Event_Reason_Tree_Data_Id
 	  	     join event_reasons r on d.event_reason_id = r.event_reason_id
 	  	     Left join event_reasons r2 on d2.event_reason_id = r2.event_reason_id
 	  	     Left join event_reasons r3 on d3.event_reason_id = r3.event_reason_id
 	  	     Left join event_reasons r4 on d4.event_reason_id = r4.event_reason_id
 	  	     WHERE d.tree_name_id = @Id and d.Event_Reason_Level = 1
 	 END
ELSE If @DataType = 'TimedEventFault'
 	 BEGIN
 	  	   SELECT PL_Desc,p1.PU_Desc,TEFault_Value,TEFault_Name,p2.PU_Desc,r.Event_Reason_Name,r2.Event_Reason_Name,r3.Event_Reason_Name,r4.Event_Reason_Name,convert(bit,0)
 	  	     FROM timed_Event_Fault t
 	  	  	 Join Prod_Units_Base    p1 on p1.PU_Id = t.PU_Id
 	  	  	 Join Prod_Lines_Base pl on pl.PL_Id = p1.PL_Id
 	  	  	 Left Join Prod_Units_Base    p2 on p2.PU_Id = t.Source_PU_Id
 	  	     Left join event_reasons r  on t.Reason_Level1 = r.event_reason_id
 	  	     Left join event_reasons r2 on t.Reason_Level2 = r2.event_reason_id
 	  	     Left join event_reasons r3 on t.Reason_Level3 = r3.event_reason_id
 	  	     Left join event_reasons r4 on t.Reason_Level4 = r4.event_reason_id
 	  	     WHERE t.PU_Id = @Id
 	 END
ELSE If @DataType = 'WasteEventFault'
 	 BEGIN
 	  	   SELECT PL_Desc,p1.PU_Desc,WEFault_Value,WEFault_Name,p2.PU_Desc,r.Event_Reason_Name,r2.Event_Reason_Name,r3.Event_Reason_Name,r4.Event_Reason_Name,convert(bit,0)
 	  	     FROM Waste_Event_Fault w
 	  	  	 Join Prod_Units_Base    p1 on p1.PU_Id = w.PU_Id
 	  	  	 Join Prod_Lines_Base pl on pl.PL_Id = p1.PL_Id
 	  	  	 Left Join Prod_Units_Base    p2 on p2.PU_Id = w.Source_PU_Id
 	  	     Left join event_reasons r  on w.Reason_Level1 = r.event_reason_id
 	  	     Left join event_reasons r2 on w.Reason_Level2 = r2.event_reason_id
 	  	     Left join event_reasons r3 on w.Reason_Level3 = r3.event_reason_id
 	  	     Left join event_reasons r4 on w.Reason_Level4 = r4.event_reason_id
 	  	     WHERE w.PU_Id = @Id
 	 END
ELSE If @DataType = 'Customers'
 	 BEGIN
 	  	 If @SearchString = ''
 	  	   SELECT Customer_Name,Customer_Code,Customer_Type_Desc,Address_1,Address_2,Address_3,Address_4,City,State,ZIP,County,Country,Contact_Name,Contact_Phone,
 	  	  	 Consignee_Name,Consignee_Code,Customer_General_1,Customer_General_2,Customer_General_3,Customer_General_4,Customer_General_5,Extended_Info,Is_Active
 	  	  	  FROM Customer c
 	  	    	  Join Customer_Types ct On  ct.Customer_Type_Id = c.Customer_Type
 	  	 ELSE
 	  	   SELECT Customer_Name,Customer_Code,Customer_Type_Desc,Address_1,Address_2,Address_3,Address_4,City,State,ZIP,County,Country,Contact_Name,Contact_Phone,
 	  	  	 Consignee_Name,Consignee_Code,Customer_General_1,Customer_General_2,Customer_General_3,Customer_General_4,Customer_General_5,Extended_Info,Is_Active
 	  	  	  FROM Customer c
 	  	    	  Join Customer_Types ct On  ct.Customer_Type_Id = c.Customer_Type
 	  	  	  WHERE Customer_Code like @SearchString
 	 END
ELSE If @DataType = 'Orders'
 	 BEGIN
 	   SELECT @Sql = 	 'SELECT co.Plant_Order_Number,co.Order_Type,co.Order_Status,c.Customer_Code,co.Customer_Order_Number,co.Corporate_Order_Number,c1.Customer_Code,'
 	   SELECT @Sql = @Sql + 'co.Forecast_Mfg_Date,co.Actual_Mfg_Date,co.Forecast_Ship_Date,co.Actual_Ship_Date,co.Order_Instructions,'
 	   SELECT @Sql = @Sql + 'co.Extended_Info,co.Order_General_1,co.Order_General_2,co.Order_General_3,co.Order_General_4,co.Order_General_5,co.Is_Active,co.Schedule_Block_Number'
 	   SELECT @Sql = @Sql + ' FROM Customer_Orders co'
 	   SELECT @Sql = @Sql + ' Left Join Customer c On  co.Customer_Id = c.Customer_Id'
 	   SELECT @Sql = @Sql + ' Left Join Customer c1 On  co.Consignee_Id = c1.Customer_Id'
 	   If @EndTime is null
 	    	 SELECT @Sql = @Sql + ' WHERE  Forecast_Ship_Date > ''' + Convert(nVarChar(25),@StartTime,120) + ''''
 	   ELSE
 	    	 SELECT @Sql = @Sql + ' WHERE  (Forecast_Ship_Date Between ''' + Convert(nVarChar(25),@StartTime,120) + ''' and ''' + Convert(nVarChar(25),@EndTime,120) + ''')'
 	   If @SearchString <> '' 
 	  	 SELECT @Sql = @Sql + ' and c.Customer_Code like ''' + @SearchString + ''''
 	   Execute(@SQL)
 	 END
ELSE If @DataType = 'OrderLineItems'
 	 BEGIN
 	   SELECT @Sql = 	 'SELECT o.Plant_Order_Number,co.Line_Item_Number,p.Prod_Code,co.Ordered_Quantity,co.Ordered_UOM,c.Customer_Code,c1.Customer_Code,'
 	   SELECT @Sql = @Sql + 'co.COA_Date,co.Complete_Date,co.Extended_Info,co.Order_Line_General_1,co.Order_Line_General_2,co.Order_Line_General_3,'
 	   SELECT @Sql = @Sql + 'co.Order_Line_General_4,co.Order_Line_General_5,co.Dimension_A,co.Dimension_X,co.Dimension_Y,co.Dimension_Z,'
 	   SELECT @Sql = @Sql + 'co.Dimension_A_Tolerance,co.Dimension_X_Tolerance,co.Dimension_Y_Tolerance,co.Dimension_Z_Tolerance'
 	   SELECT @Sql = @Sql + ' FROM Customer_Order_Line_Items co'
 	   SELECT @Sql = @Sql + ' Join Customer_Orders o on o.Order_Id = co.Order_Id'
 	   SELECT @Sql = @Sql + ' Left Join Products_Base   p On p.Prod_Id = co.Prod_Id'
 	   SELECT @Sql = @Sql + ' Left Join Customer c On  co.ShipTo_Id = c.Customer_Id'
 	   SELECT @Sql = @Sql + ' Left Join Customer c1 On  co.Consignee_Id = c1.Customer_Id'
 	   If @EndTime is null 
 	    	 SELECT @Sql = @Sql + ' WHERE  Forecast_Ship_Date > ''' + Convert(nVarChar(25),@StartTime,120) + ''''
 	   ELSE
 	    	 SELECT @Sql = @Sql + ' WHERE (Forecast_Ship_Date Between ''' + Convert(nVarChar(25),@StartTime,120) + ''' and ''' + Convert(nVarChar(25),@EndTime,120) + ''')'
 	   If @SearchString <> '' 
 	  	 SELECT @Sql = @Sql + ' and c.Customer_Code like ''' + @SearchString + ''''
 	   Execute(@SQL)
 	 END
ELSE If @DataType = 'Shipments'
 	 BEGIN
 	   SELECT @Sql = 	 'SELECT Shipment_Number,Carrier_Type,Carrier_Code,Vehicle_Name,Shipment_Date,Arrival_Date,Complete_Date,COA_Date,Is_Active'
 	   SELECT @Sql = @Sql + ' FROM Shipment'
 	   If @EndTime is null 
 	    	 SELECT @Sql = @Sql + ' WHERE  Shipment_Date > ''' + Convert(nVarChar(25),@StartTime,120) + ''''
 	   ELSE
 	    	 SELECT @Sql = @Sql + ' WHERE (Shipment_Date Between ''' + Convert(nVarChar(25),@StartTime,120) + ''' and ''' + Convert(nVarChar(25),@EndTime,120) + ''')'
 	   If @SearchString <> '' 
 	  	 SELECT @Sql = @Sql + ' and c.Customer_Code like ''' + @SearchString + ''''
 	   Execute(@SQL)
 	 END
ELSE If @DataType = 'EMailRecipients'
 	 BEGIN
 	   SELECT eg.EG_Desc,er.ER_Desc,er.ER_Address
 	   FROM Email_Recipients er 
 	   Left Join Email_Groups_Data egd On er.ER_Id = egd.ER_Id
 	   Left Join Email_Groups eg On eg.EG_Id = egd.EG_Id
 	 END
ELSE If @DataType = 'EMailMessages'
 	 BEGIN
 	   SELECT @Sql = 	 'SELECT emd.Message_id,emd.Message_Subject,emd.Message_Text,eg.EG_Desc,Severity = Case When emd.Severity = 1 Then ''Critical'' When emd.Severity = 2 Then ''Warning'' When emd.Severity = 3 Then ''Informational'' ELSE '''' END'
 	   SELECT @Sql = @Sql + ' FROM Email_Message_Data emd'
 	   SELECT @Sql = @Sql + ' Left Join Email_Groups eg On eg.EG_Id = emd.EG_Id'
 	   Execute(@SQL)
 	 END
ELSE If @DataType = 'EventLocations'
 	 BEGIN
 	   SELECT @Sql = 	 'SELECT pl.PL_Desc,pu.PU_Desc,Case When et.ET_Id = 2 Then ''Downtime'' When et.ET_Id = 3 Then Case When pu.Waste_Event_Association = 1 Then ''Waste(Event)'' When pu.Waste_Event_Association = 2 Then ''Waste(Time)'' END END,pu.PU_Desc,ert.Tree_Name,ert2.Tree_Name,Convert(bit,Research_Enabled)'
 	   SELECT @Sql = @Sql + ' FROM Prod_Units_Base    pu'
 	   SELECT @Sql = @Sql + ' Join Prod_Units_Base    pum on pum.PU_Id = pu.PU_Id'
 	   SELECT @Sql = @Sql + ' Join Prod_Lines_Base pl On pl.PL_Id = pu.PL_Id'
      SELECT @Sql = @Sql + ' Join  Departments_Base  d On d.Dept_Id = pl.Dept_Id'
 	   SELECT @Sql = @Sql + ' Left Join Prod_Events pe On pe.PU_Id = pu.PU_Id and (pe.Event_Type = 2 or pe.Event_Type = 3)'
 	   SELECT @Sql = @Sql + ' Left Join Event_Types et on et.ET_Id = pe.Event_Type'
 	   SELECT @Sql = @Sql + ' Left Join Event_Reason_Tree ert On ert.Tree_Name_Id = pe.Name_Id'
 	   SELECT @Sql = @Sql + ' Left Join Event_Reason_Tree ert2 On ert2.Tree_Name_Id = pe.Action_Tree_Id'
    	 If  @QueryType = 2
 	  	  	 SELECT @SQL = @SQL + ' WHERE pl.pl_Id = ' + Convert(nVarChar(10),@Id)
 	  	 ELSE If @QueryType = 3 /* By Unit */
 	    	  	 SELECT @Sql = @Sql + ' WHERE pu.pu_id = ' + Convert(nVarChar(10),@Id)
 	  	 ELSE If @QueryType = 4 /* By Dept */
 	    	  	 SELECT @SQL = @SQL + ' WHERE d.Dept_Id = ' + Convert(nVarChar(10),@Id)
 	   SELECT @Sql = @Sql + ' And (et.ET_Id = 2 or et.ET_Id = 3) and (pu.timed_event_association > 0 or pu.Waste_Event_Association IN (1,2)) '
 	   Execute(@SQL)
 	 END
ELSE If @DataType = 'DisplayPlots'
 	 BEGIN
 	   SELECT @Sql = 	 'SELECT s.Sheet_Desc, stt.SPC_Trend_Type_Desc, sp.Plot_Order, pl1.PL_Desc, pu1.PU_Desc, v1.Var_Desc, pl2.PL_Desc, pu2.PU_Desc, v2.Var_Desc, pl3.PL_Desc, pu3.PU_Desc, v3.Var_Desc, pl4.PL_Desc, pu4.PU_Desc, v4.Var_Desc, pl5.PL_Desc, pu5.PU_Desc, v5.Var_Desc'
 	   SELECT @Sql = @Sql + ' FROM Sheets s'
 	   SELECT @Sql = @Sql + ' Join Sheet_Plots sp on sp.Sheet_Id = s.Sheet_Id'
 	   SELECT @Sql = @Sql + ' Join SPC_Trend_Types stt on stt.SPC_Trend_Type_Id = sp.SPC_Trend_Type_Id'
 	   SELECT @Sql = @Sql + ' Join Variables_Base   v1 on v1.Var_Id = sp.Var_Id1'
 	   SELECT @Sql = @Sql + ' Join Prod_Units_Base    pu1 on pu1.PU_Id = v1.PU_Id'
 	   SELECT @Sql = @Sql + ' Join Prod_Lines_Base pl1 on pl1.PL_Id = pu1.PL_Id'
 	   SELECT @Sql = @Sql + ' Left Outer Join Variables_Base   v2 on v2.Var_Id = sp.Var_Id2'
 	   SELECT @Sql = @Sql + ' Left Outer Join Prod_Units_Base    pu2 on pu2.PU_Id = v2.PU_Id'
 	   SELECT @Sql = @Sql + ' Left Outer Join Prod_Lines_Base pl2 on pl2.PL_Id = pu2.PL_Id'
 	   SELECT @Sql = @Sql + ' Left Outer Join Variables_Base   v3 on v3.Var_Id = sp.Var_Id3'
 	   SELECT @Sql = @Sql + ' Left Outer Join Prod_Units_Base    pu3 on pu3.PU_Id = v3.PU_Id'
 	   SELECT @Sql = @Sql + ' Left Outer Join Prod_Lines_Base pl3 on pl3.PL_Id = pu3.PL_Id'
 	   SELECT @Sql = @Sql + ' Left Outer Join Variables_Base   v4 on v4.Var_Id = sp.Var_Id4'
 	   SELECT @Sql = @Sql + ' Left Outer Join Prod_Units_Base    pu4 on pu4.PU_Id = v4.PU_Id'
 	   SELECT @Sql = @Sql + ' Left Outer Join Prod_Lines_Base pl4 on pl4.PL_Id = pu4.PL_Id'
 	   SELECT @Sql = @Sql + ' Left Outer Join Variables_Base   v5 on v5.Var_Id = sp.Var_Id5'
 	   SELECT @Sql = @Sql + ' Left Outer Join Prod_Units_Base    pu5 on pu5.PU_Id = v5.PU_Id'
 	   SELECT @Sql = @Sql + ' Left Outer Join Prod_Lines_Base pl5 on pl5.PL_Id = pu5.PL_Id'
 	   If @QueryType = 2 /* By Group */
 	  	 BEGIN
 	  	   SELECT @SQL = @SQL + ' WHERE s.Sheet_Group_Id = ' + Convert(nVarChar(10),@Id)
 	  	 END
 	   If @QueryType = 3 /* By Sheet */
 	   BEGIN
 	  	 SELECT @SQL = @SQL + ' WHERE s.Sheet_Id = ' + Convert(nVarChar(10),@Id)
 	   END
 	   SELECT @Sql = @Sql + ' Order By s.Sheet_Desc, stt.SPC_Trend_Type_Desc, sp.Plot_Order, pl1.PL_Desc, pu1.PU_Desc, v1.Var_Desc, pl2.PL_Desc, pu2.PU_Desc, v2.Var_Desc, pl3.PL_Desc, pu3.PU_Desc, v3.Var_Desc, pl4.PL_Desc, pu4.PU_Desc, v4.Var_Desc, pl5.PL_Desc, pu5.PU_Desc, v5.Var_Desc'
 	   Execute(@SQL)
 	 END
ELSE If @DataType = 'ProductionExecutionPath'
 	 BEGIN
 	  	 If @QueryType=2 
 	  	  	 SELECT pl2.pl_Desc,Path_Desc,Path_Code,IsLine = Convert(bit,Is_Line_Production),
 	  	  	  	  	 AllowChildren = Convert(bit,Create_Children),
 	  	  	  	  	 SCT = Case WHEN Schedule_Control_Type = 0 THEN 'Same Schedule'
 	  	  	  	  	  	  	  	 WHEN  Schedule_Control_Type = 1 THEN 'By Event'
 	  	  	  	  	  	  	  	 WHEN  Schedule_Control_Type = 2 THEN 'Independently'
 	  	  	  	  	  	  	  	 ELSE ''
 	  	  	  	  	  	 END,
 	  	  	  	  	 pl.pl_Desc,pu.pu_Desc,Unit_Order,IsPP = Convert(bit,Is_Production_Point),IsSP = Convert(bit,Is_Schedule_Point),
 	  	  	  	  	 Input_Name,AMM = Convert(bit,Allow_Manual_Movement), PrimSpec = pp.Prop_Desc + '/' + s.Spec_Desc,
 	  	  	  	  	 AltSpec = pp1.Prop_Desc + '/' + s1.Spec_Desc,HideI = Convert(bit,pepi.Hide_Input),
 	  	  	  	  	 LII = Convert(bit,isnull(pepi.Lock_Inprogress_Input,pe.Lock_Inprogress_Input)),
 	  	  	  	  	 pl1.pl_Desc,pu1.pu_Desc,ProdStatus_Desc
 	  	  	 FROM Prdexec_Paths pep 
 	  	  	 JOIN Prod_Lines_Base pl2 on pl2.PL_Id = pep.Pl_Id
 	  	  	 JOIN Prdexec_Path_Units ppu ON pep.Path_Id = ppu.Path_Id
 	  	  	 JOIN Prod_Units_Base    pu ON pu.PU_Id = ppu.PU_Id
 	  	  	 JOIN Prod_Lines_Base pl on pl.PL_Id = pu.Pl_Id
 	  	  	 LEFT JOIN PrdExec_Inputs pe ON ppu.PU_Id= pe.PU_Id
 	  	  	 LEFT JOIN PrdExec_Path_Inputs  pepi ON pepi.PEI_Id =  pe.PEI_Id and pepi.Path_Id = pep.Path_Id
 	  	  	 LEFT JOIN PrdExec_Path_Input_Sources ppis on ppis.PEI_Id = pe.PEI_Id And  ppis.Path_Id = pep.Path_Id
 	  	  	 LEFT JOIN Specifications s ON s.Spec_Id = pepi.Primary_Spec_Id
 	  	  	 LEFT JOIN Product_Properties pp ON pp.Prop_Id = s.Prop_Id
 	  	  	 LEFT JOIN Specifications s1 ON s1.Spec_Id = pepi.Alternate_Spec_Id
 	  	  	 LEFT JOIN Product_Properties pp1 ON pp1.Prop_Id = s1.Prop_Id
 	  	  	 LEFT JOIN Prod_Units_Base    pu1 ON pu1.PU_Id = ppis.PU_Id
 	  	  	 LEFT JOIN Prod_Lines_Base pl1 on pl1.PL_Id = pu1.Pl_Id
 	  	  	 LEFT JOIN PrdExec_Path_Input_Source_Data pepsd ON pepsd.PEPIS_Id = ppis.PEPIS_Id
 	  	  	 LEFT JOIN production_Status ps ON ps.ProdStatus_Id = pepsd.Valid_Status
 	  	  	 WHERE pep.PL_Id = @Id
 	  	  	 order by Path_Code,Unit_Order
 	  	 ELSE
 	  	  	 SELECT pl2.pl_Desc,Path_Desc,Path_Code,IsLine = Convert(bit,Is_Line_Production),
 	  	  	  	  	 AllowChildren = Convert(bit,Create_Children),
 	  	  	  	  	 SCT = Case WHEN Schedule_Control_Type = 0 THEN 'Same Schedule'
 	  	  	  	  	  	  	  	 WHEN  Schedule_Control_Type = 1 THEN 'By Event'
 	  	  	  	  	  	  	  	 WHEN  Schedule_Control_Type = 2 THEN 'Independently'
 	  	  	  	  	  	  	  	 ELSE ''
 	  	  	  	  	  	 END,
 	  	  	  	  	 pl.pl_Desc,pu.pu_Desc,Unit_Order,IsPP = Convert(bit,Is_Production_Point),IsSP = Convert(bit,Is_Schedule_Point),
 	  	  	  	  	 Input_Name,AMM = Convert(bit,Allow_Manual_Movement), PrimSpec = pp.Prop_Desc + '/' + s.Spec_Desc,
 	  	  	  	  	 AltSpec = pp1.Prop_Desc + '/' + s1.Spec_Desc,HideI = Convert(bit,pepi.Hide_Input),
 	  	  	  	  	 LII = Convert(bit,isnull(pepi.Lock_Inprogress_Input,pe.Lock_Inprogress_Input)),
 	  	  	  	  	 pl1.pl_Desc,pu1.pu_Desc,ProdStatus_Desc
 	  	  	 FROM Prdexec_Paths pep 
 	  	  	 JOIN Prod_Lines_Base pl2 on pl2.PL_Id = pep.Pl_Id
 	  	  	 JOIN Prdexec_Path_Units ppu ON pep.Path_Id = ppu.Path_Id
 	  	  	 JOIN Prod_Units_Base    pu ON pu.PU_Id = ppu.PU_Id
 	  	  	 JOIN Prod_Lines_Base pl on pl.PL_Id = pu.Pl_Id
 	  	  	 LEFT JOIN PrdExec_Inputs pe ON ppu.PU_Id= pe.PU_Id
 	  	  	 LEFT JOIN PrdExec_Path_Inputs  pepi ON pepi.PEI_Id =  pe.PEI_Id and pepi.Path_Id = pep.Path_Id
 	  	  	 LEFT JOIN PrdExec_Path_Input_Sources ppis on ppis.PEI_Id = pe.PEI_Id And  ppis.Path_Id = pep.Path_Id
 	  	  	 LEFT JOIN Specifications s ON s.Spec_Id = pepi.Primary_Spec_Id
 	  	  	 LEFT JOIN Product_Properties pp ON pp.Prop_Id = s.Prop_Id
 	  	  	 LEFT JOIN Specifications s1 ON s1.Spec_Id = pepi.Alternate_Spec_Id
 	  	  	 LEFT JOIN Product_Properties pp1 ON pp1.Prop_Id = s1.Prop_Id
 	  	  	 LEFT JOIN Prod_Units_Base    pu1 ON pu1.PU_Id = ppis.PU_Id
 	  	  	 LEFT JOIN Prod_Lines_Base pl1 on pl1.PL_Id = pu1.Pl_Id
 	  	  	 LEFT JOIN PrdExec_Path_Input_Source_Data pepsd ON pepsd.PEPIS_Id = ppis.PEPIS_Id
 	  	  	 LEFT JOIN production_Status ps ON ps.ProdStatus_Id = pepsd.Valid_Status
 	  	  	 WHERE pl2.Dept_Id  = @Id
 	  	  	 order by Path_Code,Unit_Order
 	 END
ELSE If @DataType = 'PromptOverrides'
 	 BEGIN
 	   SELECT p.Prompt_Number,l.Language_Desc, p.Prompt_String,p2.Prompt_String,p3.Prompt_String
 	  	 FROM language_Data p
 	  	 Left Join language_Data p2 on p2.Prompt_Number = p.Prompt_Number and p2.Language_Id = @Id
 	  	 Left Join language_Data p3 on p3.Prompt_Number = p.Prompt_Number and p3.Language_Id = -1
 	  	 Join languages l on l.Language_Id = @Id
 	  	 Join appversions av on av.App_Id = @QueryType
 	  	 WHERE p.Language_Id = 0 and p.Prompt_Number between av.Min_Prompt and av.Max_Prompt
 	  	 Order by p.Prompt_String
 	 END
ELSE If @DataType = 'BillOfMaterial'
 	 BEGIN
 	   If @QueryType=1 --Family
 	  	   SELECT b.BOM_Desc,REPLACE(SubString(coalesce(c.Comment_Text,c.comment),1,255),char(13) + char(10),char(10)),bf.BOM_Family_Desc,REPLACE(SubString(coalesce(c1.comment_text,c1.comment),1,255),char(13) + char(10),char(10))
 	  	  	 FROM Bill_Of_Material b
 	  	  	 Join Bill_Of_Material_Family bf on bf.BOM_Family_Id = b.BOM_Family_Id and  bf.BOM_Family_Id = @Id
 	  	  	 Left Join Comments c on c.comment_Id = b.comment_Id
 	  	  	 Left Join Comments c1 on c1.comment_Id = bf.comment_Id
 	  	  	 Order by bf.BOM_Family_Desc,b.BOM_Desc
 	   ELSE
 	  	   SELECT b.BOM_Desc,REPLACE(SubString(coalesce(c.comment_text,c.comment),1,255),char(13) + char(10),char(10)),bf.BOM_Family_Desc,REPLACE(SubString(coalesce(c1.comment_text,c1.comment),1,255),char(13) + char(10),char(10))
 	  	  	 FROM Bill_Of_Material b
 	  	  	 Join Bill_Of_Material_Family bf on bf.BOM_Family_Id = b.BOM_Family_Id
 	  	  	 Left Join Comments c on c.comment_Id = b.comment_Id
 	  	  	 Left Join Comments c1 on c1.comment_Id = bf.comment_Id
 	  	  	 WHERE b.BOM_Id =@Id
 	  	  	 Order by bf.BOM_Family_Desc,b.BOM_Desc
 	 END
ELSE If @DataType = 'BillOfMaterialFormulation'
 	 BEGIN
 	   If @QueryType=1 --Family
 	  	   SELECT c.BOM_Desc,a.BOM_Formulation_Desc,b.BOM_Formulation_Desc,a.Effective_Date,a.Expiration_Date,a.Standard_Quantity,a.Quantity_Precision,d.Eng_Unit_Code,REPLACE(SubString(coalesce(c1.comment_text,c1.comment),1,255),char(13) + char(10),char(10))
 	   	  	 FROM Bill_Of_Material_Formulation a
 	  	  	 Left Join Bill_Of_Material_Formulation b on a.Master_BOM_Formulation_Id = b.BOM_Formulation_Id
 	  	  	 Join Bill_Of_Material c on c.BOM_Id = a.BOM_Id
 	  	  	 Join Bill_Of_Material_Family bf on bf.BOM_Family_Id = c.BOM_Family_Id and bf.BOM_Family_Id = @Id
 	  	  	 Left Join Engineering_Unit d on d.Eng_Unit_Id = a.Eng_Unit_Id
 	  	  	 Left Join Comments c1 on c1.comment_Id = a.comment_Id
 	  	  	 Order by c.BOM_Desc,b.BOM_Formulation_Desc,a.BOM_Formulation_Desc
 	   ELSE
 	  	   SELECT c.BOM_Desc,a.BOM_Formulation_Desc,b.BOM_Formulation_Desc,a.Effective_Date,a.Expiration_Date,a.Standard_Quantity,a.Quantity_Precision,d.Eng_Unit_Code,REPLACE(SubString(coalesce(c1.comment_text,c1.comment),1,255),char(13) + char(10),char(10))
 	   	  	 FROM Bill_Of_Material_Formulation a
 	  	  	 Left Join Bill_Of_Material_Formulation b on a.Master_BOM_Formulation_Id = b.BOM_Formulation_Id
 	  	  	 Join Bill_Of_Material c on c.BOM_Id = a.BOM_Id
 	  	  	 Left Join Engineering_Unit d on d.Eng_Unit_Id = a.Eng_Unit_Id
 	  	  	 Left Join Comments c1 on c1.comment_Id = a.comment_Id
 	  	  	 WHERE a.BOM_Id =@Id
 	  	  	 Order by c.BOM_Desc,b.BOM_Formulation_Desc,a.BOM_Formulation_Desc
 	 END
ELSE If @DataType = 'BOMFormulationItem'
 	 BEGIN
 	   If @QueryType=1 --Family
 	  	   SELECT b.BOM_Formulation_Desc,a.Alias,c.Prod_Code,a.Quantity,a.Quantity_Precision,a.Lower_Tolerance,a.LTolerance_Precision,a.Upper_Tolerance,a.UTolerance_Precision,d.Eng_Unit_Code,a.Scrap_Factor,a.Lot_Desc,f.PL_Desc,e.PU_Desc,i.PL_Desc,h.PU_Desc,g.Location_Code,a.BOM_Formulation_Order,convert(bit,Use_Event_Components),REPLACE(SubString(coalesce(c1.comment_text,c1.comment),1,255),char(13) + char(10),char(10))
 	  	  	 FROM Bill_Of_Material_Formulation_Item a
 	  	  	 Join Bill_Of_Material_Formulation b on a.BOM_Formulation_Id = b.BOM_Formulation_Id
 	  	  	 Join Bill_Of_Material bom on bom.BOM_Id = b.BOM_Id
 	  	  	 Join Bill_Of_Material_Family bf on bf.BOM_Family_Id = bom.BOM_Family_Id and bf.BOM_Family_Id = @Id
 	  	  	 Join Products_Base   c on c.Prod_Id = a.Prod_Id
 	  	  	 Left Join Engineering_Unit d on d.Eng_Unit_Id = a.Eng_Unit_Id
 	  	  	 Left Join Prod_Units_Base    e on e.pu_Id = a.pu_Id
 	  	  	 Left Join Prod_Lines_Base f on f.PL_Id = e.PL_Id
 	  	  	 Left Join Unit_Locations g on g.Location_Id = a.Location_Id
 	  	  	 Left Join Prod_Units_Base    h on h.pu_Id = g.pu_Id
 	  	  	 Left Join Prod_Lines_Base i on i.PL_Id = h.PL_Id
 	  	  	 Left Join Comments c1 on c1.comment_Id = a.comment_Id
 	  	   Order by BOM_Formulation_Desc,BOM_Formulation_Order
 	   ELSE
 	  	   SELECT b.BOM_Formulation_Desc,a.Alias,c.Prod_Code,a.Quantity,a.Quantity_Precision,a.Lower_Tolerance,a.LTolerance_Precision,a.Upper_Tolerance,a.UTolerance_Precision,d.Eng_Unit_Code,a.Scrap_Factor,a.Lot_Desc,f.PL_Desc,e.PU_Desc,i.PL_Desc,h.PU_Desc,g.Location_Code,a.BOM_Formulation_Order,convert(bit,Use_Event_Components),REPLACE(SubString(coalesce(c1.comment_text,c1.comment),1,255),char(13) + char(10),char(10))
 	  	  	 FROM Bill_Of_Material_Formulation_Item a
 	  	  	 Join Bill_Of_Material_Formulation b on a.BOM_Formulation_Id = b.BOM_Formulation_Id
 	  	  	 Join Products_Base   c on c.Prod_Id = a.Prod_Id
 	  	  	 Left Join Engineering_Unit d on d.Eng_Unit_Id = a.Eng_Unit_Id
 	  	  	 Left Join Prod_Units_Base    e on e.pu_Id = a.pu_Id
 	  	  	 Left Join Prod_Lines_Base f on f.PL_Id = e.PL_Id
 	  	  	 Left Join Unit_Locations g on g.Location_Id = a.Location_Id
 	  	  	 Left Join Prod_Units_Base    h on h.pu_Id = g.pu_Id
 	  	  	 Left Join Prod_Lines_Base i on i.PL_Id = h.PL_Id
 	  	  	 Left Join Comments c1 on c1.comment_Id = a.comment_Id
 	  	  	 WHERE b.BOM_Id = @Id
 	  	   Order by BOM_Formulation_Desc,BOM_Formulation_Order
 	 END
ELSE If @DataType = 'EngineeringUnit'
 	 BEGIN
 	  	   SELECT Eng_Unit_Desc,Eng_Unit_Code
 	  	  	 FROM Engineering_Unit
 	  	  	 WHERE Eng_Unit_Id > 50000
 	 END
ELSE If @DataType = 'EngineeringUnitConversion'
 	 BEGIN
 	  	   SELECT Conversion_Desc,b.Eng_Unit_Code,c.Eng_Unit_Code,Slope,Intercept,substring(Custom_Conversion,1,1000)
 	  	  	 FROM Engineering_Unit_Conversion a
 	  	  	 Join Engineering_Unit b on b.Eng_Unit_Id = a.From_Eng_Unit_Id
 	  	  	 Join Engineering_Unit c on c.Eng_Unit_Id = a.To_Eng_Unit_Id
 	  	  	 WHERE Conversion_Desc is not null and Eng_Unit_Conv_Id > 50000
 	 END
ELSE If @DataType = 'BillOfMaterialProduct'
 	 BEGIN
 	   If @QueryType=1 --Family
 	  	 SELECT c.Prod_Code, b.BOM_Formulation_Desc,pl.pl_Desc,pu.PU_Desc
 	  	  	 FROM Bill_Of_Material_product a
 	  	  	 Join Bill_Of_Material_Formulation b On a.BOM_Formulation_Id = b.BOM_Formulation_Id
 	  	  	 Join Bill_Of_Material bom on bom.BOM_Id = b.BOM_Id
 	  	  	 Join Bill_Of_Material_Family bf on bf.BOM_Family_Id = bom.BOM_Family_Id and bf.BOM_Family_Id = @Id
 	  	  	 Join Products_Base   c on c.Prod_Id = a.prod_Id
 	  	  	 left join Prod_Units_Base    pu on a.PU_Id=pu.PU_Id
 	  	  	 left join Prod_Lines_Base pl on pu.PL_Id = pl.PL_Id 
 	  	  	 Order by  b.BOM_Formulation_Desc, c.Prod_Code
 	   ELSE
 	  	 SELECT c.Prod_Code, b.BOM_Formulation_Desc,pl.pl_Desc, pu.PU_Desc
 	  	  	 FROM Bill_Of_Material_product a
 	  	  	 Join Bill_Of_Material_Formulation b On a.BOM_Formulation_Id = b.BOM_Formulation_Id
 	  	  	 Join Products_Base   c on c.Prod_Id = a.prod_Id
 	  	  	 left join Prod_Units_Base    pu on a.PU_Id=pu.PU_Id
 	  	  	 left join Prod_Lines_Base pl on pu.PL_Id = pl.PL_Id 
 	  	  	 WHERE b.BOM_Id = @Id 
 	  	  	 Order by  b.BOM_Formulation_Desc, c.Prod_Code
 	 END
ELSE If @DataType = 'BillOfMaterialSubstitution'
 	 BEGIN
 	   If @QueryType=1 --Family
 	  	 SELECT c.BOM_Formulation_Desc,b.BOM_Formulation_Order,e.Prod_Code,d.Eng_Unit_Code,Conversion_Factor,BOM_Substitution_Order
 	  	  	 FROM Bill_Of_Material_Substitution a
 	  	  	 Join  Bill_Of_Material_Formulation_Item b On a.BOM_Formulation_Item_Id = b.BOM_Formulation_Item_Id
 	  	    	 Join Bill_Of_Material_Formulation c on c.BOM_Formulation_Id = b.BOM_Formulation_Id
 	  	  	 Join Bill_Of_Material bom on bom.BOM_Id = c.BOM_Id
 	  	  	 Join Bill_Of_Material_Family bf on bf.BOM_Family_Id = bom.BOM_Family_Id and bf.BOM_Family_Id = @Id
 	  	  	 Join Engineering_Unit d On a.Eng_Unit_Id = d.Eng_Unit_Id
 	  	  	 Join Products_Base   e on e.Prod_Id = a.prod_Id
 	   ELSE
 	  	 SELECT c.BOM_Formulation_Desc,b.BOM_Formulation_Order,e.Prod_Code,d.Eng_Unit_Code,Conversion_Factor,BOM_Substitution_Order
 	  	  	 FROM Bill_Of_Material_Substitution a
 	  	  	 Join Bill_Of_Material_Formulation_Item b On a.BOM_Formulation_Item_Id = b.BOM_Formulation_Item_Id
 	  	    	 Join Bill_Of_Material_Formulation c on c.BOM_Formulation_Id = b.BOM_Formulation_Id
 	  	  	 Join Engineering_Unit d On a.Eng_Unit_Id = d.Eng_Unit_Id
 	  	  	 Join Products_Base   e on e.Prod_Id = a.prod_Id
 	 END
ELSE If @DataType = 'CrossReference'
 	 BEGIN
 	  	 Create Table #CrossRef(DS nvarchar(255),TN nvarchar(255),F1 nvarchar(255) Null,F2 nvarchar(255) Null,F3 nvarchar(255) Null,FK nvarchar(255) Null,Actual_Id Int Null,Actual_Text nvarchar(255) null,Subscription_Desc nvarchar(50) Null,XML_Header nvarchar(255) Null)
 	  	 If @Id is null or @Id = 0
 	  	  	 INSERT INTO #CrossRef(DS,TN,FK,Actual_Id,Actual_Text,Subscription_Desc,XML_Header)
 	  	  	 SELECT c.Ds_Desc,b.TableName,a.Foreign_Key,a.Actual_Id,a.Actual_Text,Subscription_Desc, XML_Header
 	  	  	  	 FROM Data_Source_XRef a
 	  	  	  	 Join  Tables b On b.TableId = a.Table_Id
 	  	  	  	 Join  Data_Source c On c.DS_ID = a.DS_Id
 	  	  	  	 Left Join Subscription s on s.Subscription_Id = a.Subscription_Id
 	  	 ELSE
 	  	  	 INSERT INTO #CrossRef(DS,TN,FK,Actual_Id,Actual_Text,Subscription_Desc,XML_Header)
 	  	  	 SELECT c.Ds_Desc,b.TableName,a.Foreign_Key,a.Actual_Id,a.Actual_Text,Subscription_Desc, XML_Header 
 	  	  	  	 FROM Data_Source_XRef a
 	  	  	  	 Join  Tables b On b.TableId = a.Table_Id
 	  	  	  	 Join  Data_Source c On c.DS_ID = a.DS_Id
 	  	  	  	 Left Join Subscription s on s.Subscription_Id = a.Subscription_Id
 	  	  	  	 WHERE a.DS_ID = @Id
 	  	 Update #CrossRef Set F1 = Dept_Desc 
 	  	  	 FROM #CrossRef a
 	  	  	 Left Join  Departments_Base  b on b.Dept_id = a.Actual_Id
 	  	  	 WHERE a.TN = ' Departments_Base '
 	  	 Update #CrossRef Set F1 = PL_Desc 
 	  	  	 FROM #CrossRef a
 	  	  	 Left Join Prod_Lines_Base b on b.pl_id = a.Actual_Id
 	  	  	 WHERE a.TN = 'Prod_Lines'
 	  	 Update #CrossRef Set F1 = PL_Desc,F2 = PU_Desc
 	  	  	 FROM #CrossRef a
 	  	  	 Left Join Prod_Units_Base    b on b.PU_id = a.Actual_Id
 	  	  	 Left Join Prod_Lines_Base c on c.PL_id = b.PL_id
 	  	  	 WHERE a.TN = 'Prod_Units'
 	  	 Update #CrossRef Set F1 = PL_Desc ,F2 = PU_Desc,F3 = PUG_Desc
 	  	  	 FROM #CrossRef a
 	  	  	 Left Join PU_Groups b on b.PUG_id = a.Actual_Id
 	  	  	 Left Join Prod_Units_Base    c on c.PU_id = b.PU_Id
 	  	  	 Left Join Prod_Lines_Base d on d.PL_id = c.PL_id
 	  	  	 WHERE a.TN = 'PU_Groups'
 	  	 Update #CrossRef Set F1 = PL_Desc,F2 = PU_Desc, F3 = Var_Desc
 	  	  	 FROM #CrossRef a
 	  	  	 Left Join Variables_Base   b on b.Var_id = a.Actual_Id
 	  	  	 Left Join Prod_Units_Base    c on c.PU_id = b.PU_Id
 	  	  	 Left Join Prod_Lines_Base d on d.PL_id = c.PL_id
 	  	  	 WHERE a.TN = 'Variables'
 	  	 Update #CrossRef Set F1 = Product_Family_Desc 
 	  	  	 FROM #CrossRef a
 	  	  	 Left Join Product_Family b on b.Product_Family_Id = a.Actual_Id
 	  	  	 WHERE a.TN = 'Product_Family'
 	  	 Update #CrossRef Set F1 = Product_Grp_Desc 
 	  	  	 FROM #CrossRef a
 	  	  	 Left Join Product_Groups b on b.Product_Grp_Id = a.Actual_Id
 	  	  	 WHERE a.TN = 'Product_Groups'
 	  	 Update #CrossRef Set F1 = Prod_Code 
 	  	  	 FROM #CrossRef a
 	  	  	 Left Join Products_Base   b on b.Prod_id = a.Actual_Id
 	  	  	 WHERE a.TN = 'Products'
 	  	 Update #CrossRef Set F1 = Path_Code 
 	  	  	 FROM #CrossRef a
 	  	  	 Left Join PrdExec_Paths b on b.Path_Id = a.Actual_Id
 	  	  	 WHERE a.TN = 'PrdExec_Paths'
 	  	 Update #CrossRef Set F1 = Event_Reason_Name 
 	  	  	 FROM #CrossRef a
 	  	  	 Left Join Event_Reasons b on b.Event_Reason_Id = a.Actual_Id
 	  	  	 WHERE a.TN = 'Event_Reasons'
 	  	 Update #CrossRef Set F1 = ERC_Desc 
 	  	  	 FROM #CrossRef a
 	  	  	 Left Join Event_Reason_Catagories b on b.ERC_Id = a.Actual_Id
 	  	  	 WHERE a.TN = 'Event_Reason_Catagories'
 	  	 Update #CrossRef Set F1 = BOM_Formulation_Desc 
 	  	  	 FROM #CrossRef a
 	  	  	 Left Join Bill_Of_Material_Formulation b on b.BOM_Formulation_Id = a.Actual_Id
 	  	  	 WHERE a.TN = 'Bill_Of_Material_Formulation'
 	  	 Update #CrossRef Set F1 = BOM_Formulation_Desc ,F2 = Convert(nVarChar(10),BOM_Formulation_Order)
 	  	  	 FROM #CrossRef a
 	  	  	 Left Join Bill_Of_Material_Formulation_Item b on b.BOM_Formulation_Item_Id = a.Actual_Id
 	  	  	 Left Join Bill_Of_Material_Formulation c on c.BOM_Formulation_Id = b.BOM_Formulation_Id
 	  	  	 WHERE a.TN = 'Bill_Of_Material_Formulation'
 	  	 SELECT DS,TN,FK,F1,F2,F3,Actual_Text,Subscription_Desc,XML_Header FROM #CrossRef
 	  	 Drop Table #CrossRef
 	 END
ELSE If @DataType = 'Subscription'
 	 BEGIN
 	   If  @QueryType = 1
 	  	 SELECT Subscription_Group_Desc,Subscription_Desc,Time_Trigger_Interval,Time_Trigger_Offset,TableName,
 	  	  	 Key1 = Case When Table_Id = 1 then  (SELECT  PL_Desc FROM Prod_Units_Base    pu Join Prod_Lines_Base pl on pl.PL_Id = pu.PL_Id WHERE PU_Id = Key_Id)
 	  	  	  	  	   When Table_Id = 7 then  (SELECT  Path_Code FROM PrdExec_Paths WHERE Path_Id = Key_Id)
 	  	  	  	  	  	  	  	 END,
 	  	  	 Key2 = Case When Table_Id = 1 then  (SELECT  PU_Desc FROM Prod_Units_Base    WHERE PU_Id = Key_Id) END
 	  	  	 FROM Subscription s
 	  	  	 Join Subscription_Group sg on sg.Subscription_Group_Id = s.Subscription_Group_Id
 	  	  	 Left Join Tables t on t.TableId = s.Table_Id
 	   If  @QueryType = 2
 	  	 SELECT Subscription_Group_Desc,Subscription_Desc,Time_Trigger_Interval,Time_Trigger_Offset,TableName,
 	  	  	 Key1 = Case When Table_Id = 1 then  (SELECT  PL_Desc FROM Prod_Units_Base    pu Join Prod_Lines_Base pl on pl.PL_Id = pu.PL_Id WHERE PU_Id = Key_Id)
 	  	  	  	  	   When Table_Id = 7 then  (SELECT  Path_Code FROM PrdExec_Paths WHERE Path_Id = Key_Id)
 	  	  	  	  	  	  	  	 END,
 	  	  	 Key2 = Case When Table_Id = 1 then  (SELECT  PU_Desc FROM Prod_Units_Base    WHERE PU_Id = Key_Id) END
 	  	  	 FROM Subscription s
 	  	  	 Join Subscription_Group sg on sg.Subscription_Group_Id = s.Subscription_Group_Id
 	  	  	 Left Join Tables t on t.TableId = s.Table_Id
 	  	  	 WHERE  s.Subscription_Group_Id = @Id
 	 END
ELSE If @DataType = 'SubscriptionGroup'
 	 BEGIN
 	  	 SELECT Subscription_Group_Desc,Stored_Procedure_Name,Priority FROM Subscription_Group 
 	 END
ELSE If @DataType = 'Models'
 	 BEGIN
 	  	 SELECT Model_Desc, Model_Num,Derived_from,
 	  	  	 Model_Version, convert(bit,isnull(Interval_Based,0)),convert(bit,isnull(Locked,0)),ET_Desc,REPLACE(substring(c.Comment_Text,1,255),char(13) + char(10),char(10))
 	  	 FROM ED_Models em
 	  	 Left Join comments c on c.comment_Id = em.comment_Id
 	  	 Left Join Event_types et on et.et_Id = em.et_Id
 	  	 WHERE ED_Model_Id = @Id
 	 END
ELSE If @DataType = 'ModelFields'
 	 BEGIN
 	  	 SELECT Model_Desc, ef.Field_Order,ef.Field_Desc, Substring(ef.Default_Value, 1, 255), ef.Optional, convert(bit,isnull(ef.Locked,0)),
 	  	  	 convert(bit,isnull(ef.Use_Percision,0)), ef.Percision,REPLACE(substring(c.Comment_Text,1,255),char(13) + char(10),char(10))
 	  	 FROM ED_Fields ef
 	  	 Join ED_Models em on em.Ed_Model_Id = ef.Ed_Model_Id
 	  	 Left Join comments c on c.comment_Id = ef.comment_Id 	  	 
 	  	 WHERE ef.ED_Model_Id = @Id
 	  	 Order by ef.Field_Order
 	 END
ELSE If @DataType = 'ModelProperties'
 	 BEGIN
 	  	 SELECT Model_Desc,ep.Optional, ep.Locked,ep.Field_Desc, Field_Type_Desc, ep.Default_Value
 	  	 FROM ed_field_properties ep
 	  	 Join ED_Models em on em.Ed_Model_Id = ep.Ed_Model_Id
 	  	 Join ed_Fieldtypes ef on ef.ED_Field_Type_Id = ep.ED_Field_Type_Id
 	  	 WHERE ep.ED_Model_Id = @Id
 	 END
ELSE If @DataType = 'RawMaterialInputs'
 	 BEGIN
 	  	 SELECT @Sql = 'SELECT PL.PL_Desc, PU.PU_Desc, p.Input_Name, es.Event_Subtype_Desc,'
 	  	 SELECT @Sql = @Sql + ' pp.Prop_Desc + ''/'' + s.Spec_Desc,' 
 	  	 SELECT @Sql = @Sql + ' pp2.Prop_Desc + ''/'' + s2.Spec_Desc,'
 	  	 SELECT @Sql = @Sql + ' convert(bit,isnull(p.Lock_Inprogress_Input,0)),' 
 	  	 SELECT @Sql = @Sql + ' PL1.PL_Desc, PU1.PU_Desc,ProdStatus_Desc'
 	  	 SELECT @Sql = @Sql + ' FROM prdexec_inputs p'
   	  	 SELECT @SQL = @SQL + ' Join Event_Subtypes es on es.Event_Subtype_Id = p.Event_Subtype_Id'
 	  	 SELECT @Sql = @Sql + ' Join Prod_Units_Base    PU on PU.PU_Id = p.PU_Id'
 	  	 SELECT @Sql = @Sql + ' Join Prod_Lines_Base PL on PL. PL_Id = PU.PL_Id'
 	      	 SELECT @Sql = @Sql + ' Join  Departments_Base  d On d.Dept_Id = pl.Dept_Id'
 	  	 SELECT @SQL = @SQL + ' Left Join Specifications s on s.Spec_Id = p.Primary_Spec_Id'
 	  	 SELECT @SQL = @SQL + ' Left Join Product_Properties pp on pp.Prop_Id = s.Prop_Id'
 	  	 SELECT @SQL = @SQL + ' Left Join Specifications s2 on s2.Spec_Id = p.Alternate_Spec_Id'
 	  	 SELECT @SQL = @SQL + ' Left Join Product_Properties pp2 on pp2.Prop_Id = s2.Prop_Id'
 	  	 SELECT @SQL = @SQL + ' Left Join PrdExec_Input_Sources pis on pis.PEI_Id = p.PEI_Id'
 	  	 SELECT @Sql = @Sql + ' Left Join Prod_Units_Base    PU1 on PU1.PU_Id = pis.PU_Id'
 	  	 SELECT @Sql = @Sql + ' Left Join Prod_Lines_Base PL1 on PL1. PL_Id = PU1.PL_Id'
 	  	 SELECT @SQL = @SQL + ' Left Join PrdExec_Input_Source_Data pisd on pisd.PEIS_Id = pis.PEIS_Id'
 	  	 SELECT @Sql = @Sql + ' Left Join Production_Status ps on ps.ProdStatus_Id = pisd.Valid_Status'
 	  	 If  @QueryType = 1
 	  	  	 SELECT @SQL = @SQL + ' WHERE pu.PU_Id <> 0'
   	  	 ELSE If  @QueryType = 2
 	  	  	 SELECT @SQL = @SQL + ' WHERE pl.pl_Id = ' + Convert(nVarChar(10),@Id)
 	  	 ELSE If @QueryType = 3 /* By Unit */
 	    	  	 SELECT @SQL = @SQL + ' WHERE pu.PU_Id = ' + Convert(nVarChar(10),@Id)
 	  	 ELSE If @QueryType = 4 /* By Dept */
 	    	  	 SELECT @SQL = @SQL + ' WHERE d.Dept_Id = ' + Convert(nVarChar(10),@Id)
 	  	 SELECT @Sql = @Sql + ' Order By PL.PL_Desc, PU.PU_Desc, p.Input_Name,PL1.PL_Desc, PU1.PU_Desc '
 	    	 Execute(@SQL)
 	 END
ELSE If @DataType = 'ProductionUnitStatuses'
 	 BEGIN
 	  	 SELECT @Sql = 'SELECT PL.PL_Desc, PU.PU_Desc, ps.ProdStatus_Desc,'
 	  	 SELECT @Sql = @Sql + ' convert(bit,isnull(p.Is_Default_Status,0)),' 
 	  	 SELECT @Sql = @Sql + ' ps2.ProdStatus_Desc'
 	  	 SELECT @Sql = @Sql + ' FROM PrdExec_Status p'
 	  	 SELECT @Sql = @Sql + ' Join Prod_Units_Base    PU on PU.PU_Id = p.PU_Id'
 	  	 SELECT @Sql = @Sql + ' Join Prod_Lines_Base PL on PL. PL_Id = PU.PL_Id'
 	      	 SELECT @Sql = @Sql + ' Join  Departments_Base  d On d.Dept_Id = pl.Dept_Id'
 	  	 SELECT @SQL = @SQL + ' Left Join PrdExec_Trans pst on pst.pu_Id = p.PU_Id and pst.From_ProdStatus_Id = p.Valid_Status'
 	  	 SELECT @Sql = @Sql + ' Join Production_Status ps on ps.ProdStatus_Id = p.Valid_Status'
 	  	 SELECT @Sql = @Sql + ' Join Production_Status ps2 on ps2.ProdStatus_Id = pst.To_ProdStatus_Id'
 	  	 If  @QueryType = 1
 	  	  	 SELECT @SQL = @SQL + ' WHERE pu.PU_Id <> 0'
   	  	 ELSE If  @QueryType = 2
 	  	  	 SELECT @SQL = @SQL + ' WHERE pl.pl_Id = ' + Convert(nVarChar(10),@Id)
 	  	 ELSE If @QueryType = 3 /* By Unit */
 	    	  	 SELECT @SQL = @SQL + ' WHERE pu.PU_Id = ' + Convert(nVarChar(10),@Id)
 	  	 ELSE If @QueryType = 4 /* By Dept */
 	    	  	 SELECT @SQL = @SQL + ' WHERE d.Dept_Id = ' + Convert(nVarChar(10),@Id)
 	  	 SELECT @Sql = @Sql + ' Order By PL.PL_Desc, PU.PU_Desc, ps.ProdStatus_Desc,ps2.ProdStatus_Desc '
 	    	 Execute(@SQL)
 	 END
ELSE If @DataType = 'CalculationTemplate'
  BEGIN 
 /* Calculations */
 	 Create Table #Calcs2 (DS_Desc nvarchar(50),C_Name nvarchar(255),C_Description nvarchar(255),C_Type nVarChar(100),Equation nvarchar(255),Trigger_Type nVarChar(100),
 	  	  	  	 Lag_Time Int,Max_Run_Time Int,Alias nVarChar(100),Input_Name nVarChar(100),Entity nVarChar(100),
 	  	  	  	 Attribute nVarChar(100),Input_Order Int,Default_Value nVarChar(100),Optional Bit,Sp_Name nvarchar(255),
 	  	  	  	 Script 	 nvarchar(20),Comment nvarchar(255),Constant nVarChar(100),Orderby Int,Calc_Id Int,OptimizeCalc Bit,C_Version nVarChar(10),NonTriggering Bit)
 	 SELECT @SQL = 'SELECT ''CalculationMgr'',c.Calculation_Name,c.Calculation_Desc,ct.Calculation_Type_Desc,c.Equation,ctt.Name,'
 	 SELECT @SQL = @SQL + 'c.Lag_Time,c.Max_Run_Time,null,null,null,null,null,null,null,'
 	 SELECT @SQL = @SQL + 'c.Stored_Procedure_Name,Script = case When c.Calculation_Type_Id = 3 then Char(2) + convert(nVarChar(10), c.Calculation_Id) ELSE null END,'
 	 SELECT @SQL = @SQL + 'REPLACE(substring(cm.Comment_Text,1,255),char(13) + char(10),char(10)),Null,3,c.Calculation_Id,Optimize_Calc_Runs,Version,Null'
 	 SELECT @SQL = @SQL + ' FROM Calculations c '
 	 SELECT @SQL = @SQL + ' Join Calculation_Types ct On c.Calculation_Type_Id = ct.Calculation_Type_Id'
 	 SELECT @SQL = @SQL + ' Join Calculation_Trigger_Types ctt On c.Trigger_Type_Id = ctt.Trigger_Type_Id'
 	 SELECT @SQL = @SQL + ' Left Join Comments cm On cm.Comment_Id = c.Comment_Id'
 	 If  @QueryType = 1
 	   SELECT @SQL = @SQL + ' WHERE  c.Calculation_Id = ' + Convert(nVarChar(10),@Id) 
 	 INSERT INTO #Calcs2
 	  	 Execute (@Sql)
/* Calculation Dependency */
 	 SELECT @SQL =  ' SELECT ''Calculation Dependency'','
 	 SELECT @SQL = @SQL + 'c.Calculation_Name,Null,Null,Null,Null,'
 	 SELECT @SQL = @SQL + 'Null,Null,null,cd.Name,null,cds.Calc_Dependency_Scope_Name,null,null,cd.Optional,'
 	 SELECT @SQL = @SQL + 'Null,Null,Null,Null,5,c.Calculation_Id,Null,Null,Null'
 	 SELECT @SQL = @SQL + ' FROM Calculation_Dependencies cd' 
 	 SELECT @SQL = @SQL + ' Join Calculation_Dependency_Scopes cds On cd.Calc_Dependency_Scope_Id = cds.Calc_Dependency_Scope_Id'
 	 SELECT @SQL = @SQL + ' Join Calculations c On cd.Calculation_Id = c.Calculation_Id'
 	 SELECT @SQL = @SQL + ' WHERE cd.Calculation_Id = ' + Convert(nVarChar(10),@Id) 
 	 INSERT INTO #Calcs2
 	  	 Execute (@Sql)
/* Calculation Inputs */
 	 SELECT @SQL = ' SELECT ''Calculation Input'','
 	 SELECT @SQL = @SQL + 'c.Calculation_Name,Null,Null,Null,Null,'
 	 SELECT @SQL = @SQL + 'Null,Null,ci.Alias,ci.Input_Name,cie.Entity_Name,cia.Attribute_Name,ci.Calc_Input_Order,ci.Default_Value,ci.Optional,'
 	 SELECT @SQL = @SQL + 'Null,Null,Null,Null,4,c.Calculation_Id,Null,Null,ci.Non_Triggering'
 	 SELECT @SQL = @SQL + ' FROM Calculations c'
 	 SELECT @SQL = @SQL + ' Join Calculation_Inputs ci On ci.Calculation_Id =  c.Calculation_Id'
 	 SELECT @SQL = @SQL + ' Left Join Calculation_Input_Entities cie On ci.Calc_Input_Entity_Id = cie.Calc_Input_Entity_Id'
 	 SELECT @SQL = @SQL + ' Left Join Calculation_Input_Attributes cia On ci.Calc_Input_Attribute_Id = cia.Calc_Input_Attribute_Id'
 	 SELECT @SQL = @SQL + ' WHERE c.Calculation_Id = ' + Convert(nVarChar(10),@Id) 
 	 INSERT INTO #Calcs2
 	  	 Execute (@Sql)
 	 SELECT DS_Desc,C_Name,C_Description,C_Type,Equation,Trigger_Type,Lag_Time,Max_Run_Time,Alias,Input_Name,Entity,Attribute,
 	  	 Input_Order,Default_Value,Optional,Sp_Name,Script,Comment,OptimizeCalc,C_Version,NonTriggering
 	 FROM #Calcs2
 	 Order by Input_Order
 	 Drop Table #Calcs2
  END 
ELSE If @DataType = 'DefaultCharacteristic'
 	 BEGIN
 	   SELECT @SQL = 'SELECT p.Prod_Code,pp.Prop_Desc,c.Char_Desc'
 	   SELECT @SQL = @SQL + ' FROM Products_Base   p '
 	   SELECT @SQL = @SQL + ' Left Join Product_Family pf on pf.Product_Family_Id = p.Product_Family_Id'
 	   SELECT @SQL = @SQL + ' Join Product_Characteristic_Defaults pc on pc.Prod_Id = p.Prod_Id' 	 
 	   SELECT @SQL = @SQL + ' Left Join Product_Properties pp on pp.Prop_Id = pc.Prop_Id' 	 
 	   SELECT @SQL = @SQL + ' Left Join Characteristics c on c.Char_Id = pc.Char_Id' 	 
 	   SELECT @SQL = @SQL + ' WHERE p.Prod_ID <> 1'
 	   If  @QueryType = 2
 	  	 SELECT @SQL = @SQL + ' and p.Product_Family_Id = ' + Convert(nVarChar(10),@Id) 
 	   SELECT @Sql = @Sql + + ' Order By pf.Product_Family_Desc'
 	   Execute(@SQL)
 	 END
ELSE If @DataType = 'Historian'
 	 BEGIN
 	  	 SELECT Alias,convert(bit,Hist_Default),OS_Desc,Hist_Type_Desc,Hist_ServerName,Hist_Username,convert(bit,Is_Remote),convert(bit,Is_Active),Hist_Option_Desc,isnull(Value,Hist_Option_Default_Value)
 	  	 FROM  Historian_Type_Options  hto
 	  	 JOIN Historian_Types ht ON ht.Hist_Type_Id = hto.Hist_Type_Id 
 	  	 JOIN Historians h on h.Hist_Type_Id = ht.Hist_Type_Id
 	  	 Left Join historian_Options ho on ho.Hist_Option_Id = hto.Hist_Option_Id
 	  	 Left JOIN Operating_Systems os on OS.OS_Id = h.Hist_OS_Id
 	  	 Left JOIN Historian_Option_Data hod on h.Hist_Id = hod.Hist_Id and hod.Hist_Option_Id = hto.Hist_Option_Id
 	  	 WHERE h.Hist_Id <> -1
 	  	 Order by Alias,Hist_Option_Desc
 	 END 	 
ELSE If @DataType = 'ProdXRef'
 	 BEGIN
 	  	 IF  @QueryType = 1
 	  	  	 SELECT Prod_Code,Prod_Code_XRef,pl.PL_Desc,pu.PU_Desc
 	  	  	  	 FROM Prod_XRef px
 	  	  	  	 JOIN Products_Base   p ON p.Prod_Id = px.Prod_Id
 	  	  	  	 JOIN Product_Group_Data pg on pg.Prod_Id = p.Prod_Id
 	  	  	  	 LEFT JOIN Prod_Units_Base    pu ON pu.PU_Id = px.PU_Id
 	  	  	  	 LEFT JOIN Prod_Lines_Base pl On pl.PL_Id = pu.PL_Id
 	  	  	  	 WHERE pg.Product_Grp_Id = @Id 
 	  	 ELSE
 	  	  	 SELECT Prod_Code,Prod_Code_XRef,pl.PL_Desc,pu.PU_Desc
 	  	  	  	 FROM Prod_XRef px
 	  	  	  	 JOIN Products_Base   p ON p.Prod_Id = px.Prod_Id
 	  	  	  	 JOIN Product_Family pf on pf.Product_Family_Id = p.Product_Family_Id
 	  	  	  	 LEFT JOIN Prod_Units_Base    pu ON pu.PU_Id = px.PU_Id
 	  	  	  	 LEFT JOIN Prod_Lines_Base pl On pl.PL_Id = pu.PL_Id
 	  	  	  	 WHERE pf.Product_Family_Id = @Id
 	 END 	 
ELSE If @DataType='ReportTreeNodes'
  BEGIN
 	 Declare @T Table(Id int identity(1,1), Report_Name nvarchar(255), Report_Type_Name nvarchar(255), Parent_Node_Name nvarchar(50),Report_Tree_Template_Name nvarchar(255), Class_Name nvarchar(50), Node_Id int, Report_Tree_Template_Id int, Node_Id_Type int, Parent_Node_Id int, Report_Def_Id int, Report_Type_Id int, Node_Order int, Node_Level int, Node_Name nvarchar(255), URL nvarchar(50), ForceRunMode int, SendParameters int, P1_Id int, P1_Name nvarchar(50), P2_Id int, P2_Name nvarchar(50), P3_Id int, P3_Name nvarchar(50), P4_Id int, P4_Name nvarchar(50), P5_Id int, P5_Name nvarchar(50), P6_Id int, P6_Name nvarchar(50), P7_Id int, P7_Name nvarchar(50), P8_Id int, P8_Name nvarchar(50), P9_Id int, P9_Name nvarchar(50))
 	 INSERT INTO @T(Report_Tree_Template_Name, Class_Name , Node_Id , Report_Tree_Template_Id , Node_Id_Type ,
 	  	 Parent_Node_Id , Report_Def_Id , Report_Type_Id , Node_Order , Node_Level , 
 	  	 Node_Name , URL , ForceRunMode , SendParameters )
 	 Select RTT.Report_Tree_Template_Name, RT.Class_Name,RTN.Node_Id, RTN.Report_Tree_Template_Id,RTN.Node_Id_Type,
 	  	 RTN.Parent_Node_Id,RTN.Report_Def_Id, coalesce(RTN.Report_Type_Id,RD.Report_Type_Id), RTN.Node_Order, RTN.Node_Level, 
 	  	 RTN.Node_Name,RTN.URL, RTN.ForceRunMode,
 	  	 'SendParameters' = 
 	  	 Case 
 	  	  	 When RTN.SendParameters Is Null Then RT.Send_Parameters
 	  	  	 Else RTN.SendParameters
 	  	 End
 	 From Report_Tree_Nodes RTN
 	 Left join Report_Tree_Templates RTT on RTT.Report_Tree_Template_Id = @Id
 	 Left Join Report_Definitions RD on RTN.Report_Def_Id = RD.Report_Id
 	 Left Join Report_Types RT on RTN.Report_Type_Id = RT.Report_Type_Id OR RT.Report_Type_Id = RD.Report_Type_Id
 	 where RTN.Report_Tree_Template_Id = @Id
 	 Order By RTN.Node_Level asc, RTN.Node_Order asc
   	 UPDATE @T SET URL = Char(4) + convert(nVarChar(10), Node_Id) 
   	  	 WHERE (URL Is Not Null) and (URL <> '')
   	 UPDATE @T SET URL ='' WHERE URL Is  Null
 	 UPDATE @T SET Parent_Node_Name = b.Node_Name
 	  	 FROM @T a
 	  	 Join Report_Tree_Nodes b ON a.Parent_Node_ID = b.Node_Id 
 	 UPDATE @T SET Report_Name = b.Report_Name
 	  	 FROM @T a
 	  	 Join Report_Definitions b ON a.Report_def_Id = b.Report_id 
 	 UPDATE @T SET Report_Type_Name = b.Description
 	  	 FROM @T a
 	  	 Join Report_Types b ON a.Report_Type_Id = b.Report_Type_Id 
 	 
 	 Declare @rId int, @NodeLevel int, @NodeId int, @ParentNodeId int
 	 Declare @P1 int, @P2 int, @P3 int, @P4 int, @P5 int, @P6 int, @P7 int, @P8 int, @P9 int
 	 
 	 Declare MyCursor INSENSITIVE CURSOR
 	   For ( SELECT Id, Node_Level, Node_Id, Parent_Node_Id FROM @T )
 	   For Read Only
 	   Open MyCursor  
 	 
 	   Fetch Next FROM MyCursor INTO @rId, @NodeLevel, @NodeId, @ParentNodeId
 	   While (@@Fetch_Status = 0)
 	     BEGIN
 	  	 
 	  	  	 If @NodeLevel >= 9 SELECT @P9 = Parent_Node_Id FROM Report_Tree_Nodes WHERE Node_Id = @NodeId
 	  	  	 If @NodeLevel >= 8 SELECT @P8 = Parent_Node_Id FROM Report_Tree_Nodes WHERE Node_Id = IsNull(@P9, @NodeId)
 	  	  	 If @NodeLevel >= 7 SELECT @P7 = Parent_Node_Id FROM Report_Tree_Nodes WHERE Node_Id = IsNull(@P8, @NodeId)
 	  	  	 If @NodeLevel >= 6 SELECT @P6 = Parent_Node_Id FROM Report_Tree_Nodes WHERE Node_Id = IsNull(@P7, @NodeId)
 	  	  	 If @NodeLevel >= 5 SELECT @P5 = Parent_Node_Id FROM Report_Tree_Nodes WHERE Node_Id = IsNull(@P6, @NodeId)
 	  	  	 If @NodeLevel >= 4 SELECT @P4 = Parent_Node_Id FROM Report_Tree_Nodes WHERE Node_Id = IsNull(@P5, @NodeId)
 	  	  	 If @NodeLevel >= 3 SELECT @P3 = Parent_Node_Id FROM Report_Tree_Nodes WHERE Node_Id = IsNull(@P4, @NodeId)
 	  	  	 If @NodeLevel >= 2 SELECT @P2 = Parent_Node_Id FROM Report_Tree_Nodes WHERE Node_Id = IsNull(@P3, @NodeId)
 	  	  	 If @NodeLevel >= 1 SELECT @P1 = Parent_Node_Id FROM Report_Tree_Nodes WHERE Node_Id = IsNull(@P2, @NodeId)
 	 
 	  	  	 update @T Set
 	  	  	  	 P9_Id = @P9, P8_Id = @P8, P7_Id = @P7, P6_Id = @P6, P5_Id = @P5, P4_Id = @P4, P3_Id = @P3, P2_Id = @P2, P1_Id = @P1 WHERE Id = @rId
 	 
 	  	  	 Update @T SET 
 	  	  	  	 P1_Name = (SELECT rtn.Node_Name FROM Report_Tree_Nodes rtn WHERE rtn.Node_Id = P1_Id),
 	  	  	  	 P2_Name = (SELECT rtn.Node_Name FROM Report_Tree_Nodes rtn WHERE rtn.Node_Id = P2_Id),
 	  	  	  	 P3_Name = (SELECT rtn.Node_Name FROM Report_Tree_Nodes rtn WHERE rtn.Node_Id = P3_Id),
 	  	  	  	 P4_Name = (SELECT rtn.Node_Name FROM Report_Tree_Nodes rtn WHERE rtn.Node_Id = P4_Id),
 	  	  	  	 P5_Name = (SELECT rtn.Node_Name FROM Report_Tree_Nodes rtn WHERE rtn.Node_Id = P5_Id),
 	  	  	  	 P6_Name = (SELECT rtn.Node_Name FROM Report_Tree_Nodes rtn WHERE rtn.Node_Id = P6_Id),
 	  	  	  	 P7_Name = (SELECT rtn.Node_Name FROM Report_Tree_Nodes rtn WHERE rtn.Node_Id = P7_Id),
 	  	  	  	 P8_Name = (SELECT rtn.Node_Name FROM Report_Tree_Nodes rtn WHERE rtn.Node_Id = P8_Id),
 	  	  	  	 P9_Name = (SELECT rtn.Node_Name FROM Report_Tree_Nodes rtn WHERE rtn.Node_Id = P9_Id)
 	 
 	  	  	 Fetch Next FROM MyCursor INTO @rId, @NodeLevel, @NodeId, @ParentNodeId
 	     END 
 	 
 	 Close MyCursor
 	 Deallocate MyCursor
 	 SELECT Report_Tree_Template_Name, P1_Name, P2_Name, P3_Name, P4_Name, P5_Name, P6_Name, P7_Name, P8_Name, P9_Name, Node_Name, Node_Id_Type, Report_Name, Report_Type_Name, ForceRunMode, SendParameters, nChar(4) + convert(nVarChar(10), Node_Id) [URL] FROM @t
  END  
ELSE If @DataType='ReportTreeUsers'
  BEGIN
 	 Declare @TU Table(Report_Tree_Template_Name nvarchar(50), UserName nvarchar(50), User_Rights int, View_Setting int)
 	 INSERT INTO @TU(Report_Tree_Template_Name, UserName, User_Rights, View_Setting)
 	  	 SELECT rtt.Report_Tree_Template_Name, u.Username, rtu.user_rights, rtu.View_Setting
 	  	 FROM report_tree_users rtu
 	  	 Join Users u on u.user_Id = rtu.user_Id
 	  	 Join Report_Tree_Templates rtt on rtt.Report_Tree_Template_Id = rtu.Report_Tree_Template_Id
 	      WHERE rtt.Report_Tree_Template_Id = @Id
 	 If (SELECT Count(*) FROM @TU) = 0
 	  	 INSERT INTO @TU(Report_Tree_Template_Name, UserName, User_Rights, View_Setting)
 	  	 Values('No Users On Tree', '', 0, 0)
 	 SELECT * FROM @TU
  END
ELSE IF @DataType = 'ProdExecPathProducts'
BEGIN
 	 SELECT Path_Code,Prod_Code
 	  	 FROM Prdexec_Paths pep
 	  	 JOIN PrdExec_Path_Products ppp ON ppp.Path_Id = pep.Path_Id
 	  	 Join Products_Base   p ON p.Prod_Id = ppp.Prod_Id
 	  	 WHERE pep.PL_Id = @Id
 	  	 ORDER BY Path_Code
END 	 
ELSE IF @DataType = 'ProdExecPathSchedTrans'
BEGIN
 	 SELECT Path_Code,ps1.PP_Status_Desc,ps2.PP_Status_Desc
 	  	 FROM Prdexec_Paths pep
 	  	 JOIN Production_Plan_Status pps ON pps.Path_Id = pep.Path_Id
 	  	 JOIN Production_Plan_Statuses ps1 ON ps1.PP_Status_Id =  pps.From_PPStatus_Id
 	  	 JOIN Production_Plan_Statuses ps2 ON ps2.PP_Status_Id = pps.To_PPStatus_Id
 	  	 WHERE pep.PL_Id = @Id
 	  	 ORDER by Path_Code,ps1.PP_Status_Desc
END 	 
ELSE IF @DataType = 'ProdExecPathStatusDetail'
BEGIN
 	 SELECT Path_Code,ps.PP_Status_Desc,AutoTo = ps1.PP_Status_Desc,AutoFrom = ps2.PP_Status_Desc,Sort_Order,How_Many,SortWith = ps3.PP_Status_Desc
 	 FROM Prdexec_Paths pep
 	 JOIN PrdExec_Path_Status_Detail pps ON pps.Path_Id = pep.Path_Id
 	 Left JOIN Production_Plan_Statuses ps ON ps.PP_Status_Id = pps.PP_Status_Id
 	 Left JOIN Production_Plan_Statuses ps1 ON ps1.PP_Status_Id =  pps.AutoPromoteTo_PPStatusId
 	 Left JOIN Production_Plan_Statuses ps2 ON ps2.PP_Status_Id = pps.AutoPromoteFrom_PPStatusId
 	 Left JOIN Production_Plan_Statuses ps3 ON ps3.PP_Status_Id = pps.SortWith_PPStatusId
 	 WHERE pep.PL_Id = @Id
 	 ORDER BY Path_Code,ps.PP_Status_Desc
END 	 
ELSE IF @DataType = 'ProdExecPathSchedAlarms'
BEGIN
 	 DECLARE @euPU TABLE (PU_Id Int,Path_Id Int,Eng_Unit nvarchar(15))
 	 INSERT INTO  @euPU
 	  	 SELECT Max(pu.PU_Id),pu.Path_Id,Null
 	  	 FROM Prdexec_Path_Units pu
 	  	 JOIN Prdexec_Paths p on p.path_Id = pu.Path_Id and p.PL_Id = @Id
 	  	 WHERE Is_Production_Point = 1 
 	  	 Group By pu.Path_Id
 	 UPDATE @euPU SET Eng_Unit = eu.Eng_Unit_Code
 	  	 FROM @euPU e
 	  	 LEFT JOIN Event_Configuration ec ON ec.PU_Id = e.PU_Id and ec.Et_Id = 1
 	  	 Left Join Event_Subtypes es ON ec.Event_Subtype_Id = es.Event_Subtype_Id
 	  	 LEFT Join Engineering_Unit eu on es.Dimension_X_Eng_Unit_Id = eu.Eng_Unit_Id
 	 SELECT Path_Code,PEPAT_Desc,
 	  	    TValue = Case WHEN ppa.PEPAT_Id = 9 THEN (SELECT PP_Status_Desc  FROM Production_Plan_Statuses WHERE PP_Status_Id = Threshold_Value)
 	  	  	  	  	  	  	  	  	  	  	   ELSE Convert(nVarChar(10),Threshold_Value)
 	  	  	  	  	  	  	  	  	  	  	  END,
 	  	   Units = Case When Threshold_Type_Selection = 2 Then coalesce(eu.Eng_Unit,ppat.Threshold_Eng_Units)
 	  	  	  	  	 WHEN Threshold_Type_Selection Is Null THEN ''
 	  	  	  	  	 WHEN Threshold_Type_Selection = 0 THEN ''
 	  	  	  	  	 WHEN Threshold_Type_Selection = 3 THEN ppat.Threshold_Eng_Units
 	  	  	  	  	 WHEN Threshold_Type_Selection = 4 AND ppa.Threshold_Type_Selection = 2 THEN coalesce(eu.Eng_Unit,ppat.Threshold_Eng_Units)
 	  	  	  	  	 WHEN Threshold_Type_Selection = 5 AND ppa.Threshold_Type_Selection = 2  THEN ppat.Threshold_Eng_Units
 	  	  	  	  	 WHEN Threshold_Type_Selection = 6 THEN ''
 	  	  	  	  	 ELSE '%' 
 	  	  	  	   END,  AP_Desc
 	  	 FROM Prdexec_Paths pep
 	  	 JOIN PrdExec_Path_Alarms ppa ON ppa.Path_Id = pep.Path_Id
 	  	 JOIN PrdExec_Path_Alarm_Types ppat ON  ppat.PEPAT_Id = ppa.PEPAT_Id
 	  	 JOIN Alarm_Priorities ap ON ap.AP_Id = ppa.AP_Id
 	  	 LEFT JOIN @euPU eu on pep.Path_Id = eu.Path_Id 
 	  	 WHERE pep.PL_Id = @Id
 	  	 ORDER BY Path_Code,PEPAT_Desc
END 	 
ELSE IF @DataType = 'UserDefinedProperty'
BEGIN
 	 DECLARE @Output Table (TableId Int,KeyId Int,Field1 nVarChar(100),Field2 nVarChar(100),Field3 nVarChar(100),Table_Field_Id Int,Value1 nvarchar(2000),Value2 nvarchar(2000),Value3 nvarchar(2000),CurrentValue nvarchar(2000),EDFieldTypeId Int)
 	 If @SearchString = ''
 	 BEGIN
 	  	 INSERT INTO @Output(TableId,KeyId,Table_Field_Id,CurrentValue,EDFieldTypeId)
 	  	  	 SELECT tv.TableId,KeyId,tv.Table_Field_Id,Value,ED_Field_Type_Id
 	  	  	  	 FROM Table_fields_Values tv
 	  	  	  	 JOIN Tables t on t.TableId = tv.TableId and Allow_User_Defined_Property = 1
 	  	  	  	 Join table_Fields tf ON tf.Table_Field_Id = tv.Table_Field_Id 
 	 END
 	 ELSE
 	 BEGIN
 	   SELECT @SQL = 'SELECT tv.TableId,KeyId,tv.Table_Field_Id,Value,ED_Field_Type_Id'
 	   SELECT @SQL = @SQL + ' FROM Table_fields_Values tv '
 	   SELECT @SQL = @SQL + ' JOIN Tables t on t.TableId = tv.TableId and Allow_User_Defined_Property = 1'
 	   SELECT @SQL = @SQL + ' JOIN table_Fields tf ON tf.Table_Field_Id = tv.Table_Field_Id'
 	   SELECT @SQL = @SQL + ' WHERE t.TableId in (' + @SearchString + ')'
 	   INSERT INTO @Output(TableId,KeyId,Table_Field_Id,CurrentValue,EDFieldTypeId) EXECUTE (@SQL)
 	 END
/* Update the Keys */
 	 --  7           Production_Plan
 	 UPDATE o SET Field1 = b.Path_Code,Field2 = a.Process_Order
 	  	 FROM @Output o
 	  	 Join Production_Plan a On a.PP_Id = o.KeyId
 	  	 Left JOIN Prdexec_Paths b on b.Path_Id = a.Path_Id
 	  	 WHERE TableId = 7
 	 --  8           Production_Setup
 	 UPDATE o SET Field1 = b.Path_Code,Field2 = a.Process_Order,Field3 = c.Pattern_Code
 	  	 FROM @Output o
 	  	 Join  Production_Setup c on c.PP_Setup_Id =  o.KeyId
 	  	 Join Production_Plan a On a.PP_Id = c.PP_Id
 	  	 Left JOIN Prdexec_Paths b on b.Path_Id = a.Path_Id
 	  	 WHERE TableId = 8
 	 --  9           Production_Setup_Detail
 	 UPDATE o SET Field1 = d.Path_Code,Field2 = c.Process_Order,Field3 = b.Pattern_Code
 	  	 FROM @Output o
 	  	 JOIN Production_Setup_Detail a ON  a.PP_Setup_Detail_Id =  o.KeyId
 	  	 Join  Production_Setup b on b.PP_Setup_Id =  a.PP_Setup_Id
 	  	 Join Production_Plan c On c.PP_Id = b.PP_Id
 	  	 Left JOIN Prdexec_Paths d on d.Path_Id = c.Path_Id
 	  	 WHERE TableId = 9
 	 --  13          PrdExec_Paths
 	 UPDATE o SET Field1 = Path_Code
 	  	 FROM @Output o
 	  	 Join PrdExec_Paths a On a.Path_Id = o.KeyId
 	  	 WHERE TableId = 13
 	 --  17           Departments_Base 
 	 UPDATE o SET Field1 = Dept_Desc
 	  	 FROM @Output o
 	  	 Join  Departments_Base  a On a.Dept_Id = o.KeyId
 	  	 WHERE TableId = 17
 	 --  18          Prod_Lines_Base
 	 UPDATE o SET Field1 = PL_Desc
 	  	 FROM @Output o
 	  	 Join Prod_Lines_Base a On a.PL_Id = o.KeyId
 	  	 WHERE TableId = 18
 	 --  19          PU_Groups
 	 UPDATE o SET Field1 = PL_Desc,Field2 = PU_Desc,Field3 = PUG_Desc
 	  	 FROM @Output o
 	  	 Join PU_Groups a On a.PUG_Id = o.KeyId
 	  	 Join Prod_Units_Base    b On b.PU_Id = a.PU_Id
 	  	 Join Prod_Lines_Base c on c.PL_Id = b.PL_Id
 	  	 WHERE TableId = 19
 	 --  20          Variables_Base  
 	 UPDATE o SET Field1 = PL_Desc,Field2 = PU_Desc,Field3 = Var_Desc
 	  	 FROM @Output o
 	  	 Join Variables_Base   v On v.Var_Id = o.KeyId
 	  	 Join Prod_Units_Base    pu On pu.PU_Id = v.PU_Id
 	  	 Join Prod_Lines_Base pl on pl.PL_Id = pu.PL_Id
 	  	 WHERE TableId = 20
 	 --  21          Product_Family
 	 UPDATE o SET Field1 = Product_Family_Desc
 	  	 FROM @Output o
 	  	 Join Product_Family a On a.Product_Family_Id = o.KeyId
 	  	 WHERE TableId = 21
 	 --  22          Product_Groups
 	 UPDATE o SET Field1 = Product_Grp_Desc
 	  	 FROM @Output o
 	  	 Join Product_Groups a On a.Product_Grp_Id = o.KeyId
 	  	 WHERE TableId = 22
 	 --  23          Products_Base  
 	 UPDATE o SET Field1 = Prod_Code
 	  	 FROM @Output o
 	  	 Join Products_Base   a On a.Prod_Id = o.KeyId
 	  	 WHERE TableId = 23
 	 --  24          Event_Reasons
 	 UPDATE o SET Field1 = Event_Reason_Name
 	  	 FROM @Output o
 	  	 Join Event_Reasons a On a.Event_Reason_Id = o.KeyId
 	  	 WHERE TableId = 24
 	 --  25          Event_Reason_Catagories
 	 UPDATE o SET Field1 = ERC_Desc
 	  	 FROM @Output o
 	  	 Join Event_Reason_Catagories a On a.ERC_Id = o.KeyId
 	  	 WHERE TableId = 25
 	 --  26          Bill_Of_Material_Formulation
 	 UPDATE o SET Field1 = BOM_Formulation_Desc
 	  	 FROM @Output o
 	  	 Join Bill_Of_Material_Formulation a On a.BOM_Formulation_Id = o.KeyId
 	  	 WHERE TableId = 26
 	 --  27          Subscription
 	 UPDATE o SET Field1 = Subscription_Desc
 	  	 FROM @Output o
 	  	 Join Subscription a On a.Subscription_Id = o.KeyId
 	  	 WHERE TableId = 27
 	 --  28          Bill_Of_Material_Formulation_Item
 	 UPDATE o SET Field1 = b.BOM_Formulation_Desc, Field2 = a.BOM_Formulation_Order
 	  	 FROM @Output o
 	  	 Join Bill_Of_Material_Formulation_Item a On a.BOM_Formulation_Item_Id = o.KeyId
 	  	 Join Bill_Of_Material_Formulation b On b.BOM_Formulation_Id = a.BOM_Formulation_Id
 	  	 WHERE TableId = 28
 	 --  29          Subscription_Group
 	 UPDATE o SET Field1 = Subscription_Group_Desc
 	  	 FROM @Output o
 	  	 Join Subscription_Group a On a.Subscription_Group_Id = o.KeyId
 	  	 WHERE TableId = 29
 	 --  30          PrdExec_Path_Units
 	 UPDATE o SET Field1 = PL_Desc,Field2 = PU_Desc,Field3 = Path_Code
 	  	 FROM @Output o
 	  	 Join PrdExec_Path_Units a On a.PEPU_Id = o.KeyId
 	  	 Join Prod_Units_Base    b On b.PU_Id = a.PU_Id
 	  	 Join Prod_Lines_Base c on c.PL_Id = b.PL_Id
 	  	 Join PrdExec_Paths d On d.Path_Id = a.Path_Id
 	  	 WHERE TableId = 30
 	 --  31          Report_Types
 	 UPDATE o SET Field1 = [Description]
 	  	 FROM @Output o
 	  	 Join Report_Types a On a.Report_Type_Id = o.KeyId
 	  	 WHERE TableId = 31
 	 --  32          Report_Definitions
 	 UPDATE o SET Field1 = [Report_Name]
 	  	 FROM @Output o
 	  	 Join Report_Definitions a On a.Report_Id = o.KeyId
 	  	 WHERE TableId = 32
 	 --  34          Production_Plan_Statuses
 	 UPDATE o SET Field1 = PP_Status_Desc
 	  	 FROM @Output o
 	  	 Join Production_Plan_Statuses a On a.PP_Status_Id = o.KeyId
 	  	 WHERE TableId = 34
 	 --  35          PrdExec_Inputs
 	 UPDATE o SET Field1 = PL_Desc,Field2 = PU_Desc,Field3 = Input_Name
 	  	 FROM @Output o
 	  	 Join PrdExec_Inputs a On a.PEI_Id = o.KeyId
 	  	 Join Prod_Units_Base    b On b.PU_Id = a.PU_Id
 	  	 Join Prod_Lines_Base c on c.PL_Id = b.PL_Id
 	  	 WHERE TableId = 35
 	 --  36          Users
 	 UPDATE o SET Field1 = Username
 	  	 FROM @Output o
 	  	 Join Users a On a.User_Id = o.KeyId
 	  	 WHERE TableId = 36
 	 --  37          Production_Status
 	 UPDATE o SET Field1 = ProdStatus_Desc
 	  	 FROM @Output o
 	  	 Join Production_Status a On a.ProdStatus_Id = o.KeyId
 	  	 WHERE TableId = 37
 	 --  38          Email_Message_Data
 	 UPDATE @Output SET Field1 = KeyId 	 WHERE TableId = 38
 	 --  40          Specifications
 	 UPDATE o SET Field1 = Prop_Desc,Field2 = Spec_Desc
 	  	 FROM @Output o
 	  	 Join Specifications a On a.Spec_Id = o.KeyId
 	  	 Join Product_Properties b On b.Prop_Id = a.Prop_Id
 	  	 WHERE TableId = 40
 	 --  41          Characteristics
 	 UPDATE o SET Field1 = Prop_Desc,Field2 = Char_Desc
 	  	 FROM @Output o
 	  	 Join Characteristics a On a.Char_Id = o.KeyId
 	  	 Join Product_Properties b On b.Prop_Id = a.Prop_Id
 	  	 WHERE TableId = 41
 	 --  43          Prod_Units_Base   
 	 UPDATE o SET Field1 = PL_Desc,Field2 = PU_Desc
 	  	 FROM @Output o
 	  	 Join Prod_Units_Base    a On a.PU_Id = o.KeyId
 	  	 Join Prod_Lines_Base b on b.PL_Id = a.PL_Id
 	  	 WHERE TableId = 43
 	 --  44          Phrase
 	 UPDATE o SET Field1 = Data_Type_Desc,Field2 = Phrase_Value
 	  	 FROM @Output o
 	  	 Join Phrase a On a.Phrase_Id = o.KeyId
 	  	 Join data_Type b on b.Data_Type_Id = a.Data_Type_Id
 	  	 WHERE TableId = 44
 	 --  45          Customer_Orders
 	 UPDATE o SET Field1 = Customer_Code,Field2 = Customer_Order_Number
 	  	 FROM @Output o
 	  	 Join Customer_Orders a On a.Order_Id = o.KeyId
 	  	 Join Customer b on b.Customer_Id = a.Customer_Id
 	  	 WHERE TableId = 45
 	 --  46          Customer_Order_Line_Items
 	 UPDATE o SET Field1 = Customer_Code,Field2 = Customer_Order_Number,Field3 = Line_Item_Number
 	  	 FROM @Output o
 	  	 Join Customer_Order_Line_Items a On a.Order_Line_Id = o.KeyId
 	  	 Join Customer_Orders b On b.Order_Id  = a.Order_Id
 	  	 Join Customer c on c.Customer_Id = b.Customer_Id
 	  	 WHERE TableId = 46
 	 --  47          Customer_Order_Line_Details
 	 UPDATE o SET Field1 = Customer_Code,Field2 = Customer_Order_Number,Field3 = Line_Item_Number
 	  	 FROM @Output o
 	  	 Join Customer_Order_Line_Details a On a.Order_Line_Detail_Id = o.KeyId
 	  	 Join Customer_Order_Line_Items b On b.Order_Line_Id = a.Order_Line_Id
 	  	 Join Customer_Orders c On c.Order_Id  = b.Order_Id
 	  	 Join Customer d on d.Customer_Id = c.Customer_Id
 	  	 WHERE TableId = 47
 	 --  48          Shipment
 	 UPDATE o SET Field1 = Shipment_Number
 	  	 FROM @Output o
 	  	 Join Shipment a On a.Shipment_Id = o.KeyId
 	  	 WHERE TableId = 48
 	 --  49          Shipment_Line_Items
 	 UPDATE o SET Field1 = Customer_Code,Field2 = Customer_Order_Number,Field3 = Line_Item_Number
 	  	 FROM @Output o
 	  	 Join Shipment_Line_Items a On a.Shipment_Item_Id = o.KeyId
 	  	 Join Customer_Order_Line_Items b On b.Order_Line_Id = a.Order_Line_Id
 	  	 Join Customer_Orders c On c.Order_Id  =  b.Order_Id
 	  	 Join Customer d on d.Customer_Id = c.Customer_Id
 	  	 WHERE TableId = 49
 	 --  50          Customer
 	 UPDATE o SET Field1 = Customer_Code
 	  	 FROM @Output o
 	  	 Join Customer a On a.Customer_Id = o.KeyId
 	  	 WHERE TableId = 50
 	 --  51          Event_Subtypes
 	 UPDATE o SET Field1 = Event_Subtype_Desc
 	  	 FROM @Output o
 	  	 Join Event_Subtypes a On a.Event_Subtype_Id = o.KeyId
 	  	 WHERE TableId = 51
/* Update The values*/
-- Text,Numeric,File Path,DateTime,spLocal,
 	 UPDATE @Output SET Value1 = CurrentValue
 	  	 WHERE EDFieldTypeId IN (1,2,11,12,22,51,69)
-- Unit Id
 	 UPDATE o SET Value1 = b.PL_Desc,Value2 = a.PU_Desc
 	  	 FROM @Output o
 	  	 JOIN Prod_Units_Base    a On a.PU_Id = Convert(int,o.CurrentValue)
 	  	 JOIN Prod_Lines_Base b On b.PL_Id = a.PL_Id
 	  	 WHERE EDFieldTypeId = 9
-- Variable Id
 	 UPDATE o SET Value1 = c.PL_Desc,Value2 = b.PU_Desc,Value3 =a.Var_Desc
 	  	 FROM @Output o
 	  	 JOIN Variables_Base   a On a.Var_Id = Convert(int,o.CurrentValue)
 	  	 JOIN Prod_Units_Base    b On b.PU_Id = a.PU_Id
 	  	 JOIN Prod_Lines_Base c On c.PL_Id = b.PL_Id
 	  	 WHERE EDFieldTypeId = 10
-- Production Status
 	 UPDATE o SET Value1 = a.ProdStatus_Desc
 	  	 FROM @Output o
 	  	 JOIN Production_Status a On a.ProdStatus_Id = Convert(int,o.CurrentValue)
 	  	 WHERE EDFieldTypeId = 16 
--Characteristic
 	 UPDATE o SET Value1 = b.Prop_Desc,Value2 = a.Char_Desc
 	  	 FROM @Output o
 	  	 JOIN Characteristics a On a.Char_Id = Convert(int,o.CurrentValue)
 	  	 JOIN Product_Properties b On b.Prop_Id = a.Prop_Id
 	  	 WHERE EDFieldTypeId = 23 --Characteristic
--Color Scheme
 	 UPDATE o SET Value1 = a.CS_Desc
 	  	 FROM @Output o
 	  	 JOIN Color_Scheme a On a.CS_Id = Convert(int,o.CurrentValue)
 	  	 WHERE EDFieldTypeId = 24 
--Event Type
 	 UPDATE o SET Value1 = a.ET_Desc
 	  	 FROM @Output o
 	  	 JOIN Event_Types a On a.ET_Id = Convert(int,o.CurrentValue)
 	  	 WHERE EDFieldTypeId = 27 
--Access Level
 	 UPDATE o SET Value1 = a.AL_Desc
 	  	 FROM @Output o
 	  	 JOIN Access_Level a On a.AL_Id = Convert(int,o.CurrentValue)
 	  	 WHERE EDFieldTypeId = 30 
--Colors
 	 UPDATE o SET Value1 = a.Color_Desc
 	  	 FROM @Output o
 	  	 JOIN colors a On a.Color_Id = Convert(int,o.CurrentValue)
 	  	 WHERE EDFieldTypeId = 34 
--Customer
 	 UPDATE o SET Value1 = a.Customer_Code
 	  	 FROM @Output o
 	  	 JOIN Customer a On a.Customer_Id = Convert(int,o.CurrentValue)
 	  	 WHERE EDFieldTypeId = 35 
--Product
 	 UPDATE o SET Value1 = a.Prod_Code
 	  	 FROM @Output o
 	  	 JOIN Products_Base   a On a.Prod_Id = Convert(int,o.CurrentValue)
 	  	 WHERE EDFieldTypeId = 36 
--Product Group
 	 UPDATE o SET Value1 = a.Product_Grp_Desc
 	  	 FROM @Output o
 	  	 JOIN Product_Groups a On a.Product_Grp_Id = Convert(int,o.CurrentValue)
 	  	 WHERE EDFieldTypeId = 37 
---Reason Tree
 	 UPDATE o SET Value1 = a.Tree_Name
 	  	 FROM @Output o
 	  	 JOIN Event_Reason_Tree a On a.Tree_Name_Id = Convert(int,o.CurrentValue)
 	  	 WHERE EDFieldTypeId = 39 
--Reasons
 	 UPDATE o SET Value1 = a.Event_Reason_Name
 	  	 FROM @Output o
 	  	 JOIN Event_Reasons a On a.Event_Reason_Id = Convert(int,o.CurrentValue)
 	  	 WHERE EDFieldTypeId = 40 
 --Production Plan Path
 	 UPDATE o SET Value1 = a.Path_Code
 	  	 FROM @Output o
 	  	 JOIN PrdExec_Paths a On a.Path_Id = Convert(int,o.CurrentValue)
 	  	 WHERE EDFieldTypeId = 59 
 --Product Family
 	 UPDATE o SET Value1 = a.Product_Family_Desc
 	  	 FROM @Output o
 	  	 JOIN Product_Family a On a.Product_Family_Id = Convert(int,o.CurrentValue)
 	  	 WHERE EDFieldTypeId = 61 
--Data Source
 	 UPDATE o SET Value1 = a.DS_Desc
 	  	 FROM @Output o
 	  	 JOIN Data_Source a On a.DS_Id = Convert(int,o.CurrentValue)
 	  	 WHERE EDFieldTypeId = 63 
 	  	 --DE84727 Import and Export of the UDPs failing
 	  	 UPDATE o 
 	 SET 
 	  	 o.Value1 = T.Value
 	 From
 	  	 @Output o
 	  	 JOin Table_Fields_Values T on T.TableId = o.TableId and T.KeyId = o.KeyId and t.Table_Field_Id = o.Table_Field_Id
 	  	 
 	 SELECT TableName,Table_Field_Desc,Field_Type_Desc,Field1,Field2,Field3,Value1,Value2,Value3,Convert(bit,0)
 	  	  	 FROM @Output o
 	  	  	 JOIN Tables t on t.TableId = o.TableId and Allow_User_Defined_Property = 1
 	  	  	 JOIN Table_Fields tf ON tf.Table_Field_Id = o.Table_Field_Id
 	  	  	 JOIN ed_fieldtypes et on et.ED_Field_Type_Id = tf.ED_Field_Type_Id
 	  	 ORDER BY TableName,Table_Field_Desc,Field1,Field2,Field3
END 	 
ELSE If @DataType = 'ReasonShortcut'
BEGIN
 	 If @QueryType = 1 /* Timed */
 	 BEGIN
 	 SELECT PL_Desc,p1.PU_Desc,Shortcut_Name,Amount,p2.PU_Desc,r.Event_Reason_Name,r2.Event_Reason_Name,r3.Event_Reason_Name,r4.Event_Reason_Name,'Timed'
 	  	  	 FROM Reason_Shortcuts t
 	  	  	 Join Prod_Units_Base    p1 on p1.PU_Id = t.PU_Id
 	  	  	 Join Prod_Lines_Base pl on pl.PL_Id = p1.PL_Id
 	  	  	 Left Join Prod_Units_Base    p2 on p2.PU_Id = t.Source_PU_Id
 	  	  	 Left join event_reasons r  on t.Reason_Level1 = r.event_reason_id
 	  	  	 Left join event_reasons r2 on t.Reason_Level2 = r2.event_reason_id
 	  	  	 Left join event_reasons r3 on t.Reason_Level3 = r3.event_reason_id
 	  	  	 Left join event_reasons r4 on t.Reason_Level4 = r4.event_reason_id
 	  	  	 WHERE t.PU_Id = @Id and App_Id = 2
 	 END
 	 ELSE
 	 BEGIN /* Waste */
 	  	 SELECT PL_Desc,p1.PU_Desc,Shortcut_Name,Amount,p2.PU_Desc,r.Event_Reason_Name,r2.Event_Reason_Name,r3.Event_Reason_Name,r4.Event_Reason_Name,'Waste'
 	  	  	 FROM Reason_Shortcuts t
 	  	  	 Join Prod_Units_Base    p1 on p1.PU_Id = t.PU_Id
 	  	  	 Join Prod_Lines_Base pl on pl.PL_Id = p1.PL_Id
 	  	  	 Left Join Prod_Units_Base    p2 on p2.PU_Id = t.Source_PU_Id
 	  	  	 Left join event_reasons r  on t.Reason_Level1 = r.event_reason_id
 	  	  	 Left join event_reasons r2 on t.Reason_Level2 = r2.event_reason_id
 	  	  	 Left join event_reasons r3 on t.Reason_Level3 = r3.event_reason_id
 	  	  	 Left join event_reasons r4 on t.Reason_Level4 = r4.event_reason_id
 	  	  	 WHERE t.PU_Id = @Id and App_Id = 3
 	 END
END
ELSE If @DataType = 'StatusTranslation'
BEGIN
 	 If @QueryType = 1 /* Timed */
 	 BEGIN
 	 SELECT pl.PL_Desc,pu.PU_Desc,t.testatus_name,t.testatus_value
 	  	  	 FROM Timed_Event_Status t
 	  	  	 Join Prod_Units pu on pu.PU_Id = t.PU_Id
 	  	  	 Join Prod_Lines pl on pl.PL_Id = pu.PL_Id
 	  	  	 WHERE t.PU_Id = @Id
 	 END
END
ELSE If @DataType = 'WasteEventType'
BEGIN
 	 SELECT t.Wet_Name,[ReadOnly] = Convert(bit,coalesce(t.readonly,0)) 
 	  	  	 FROM Waste_Event_Type t
END
ELSE If @DataType = 'WasteEventMeasure'
BEGIN
 	 SELECT pl.PL_Desc,p1.PU_Desc,t.WEMT_Name,t.Conversion,pl2.PL_Desc,p2.PU_Desc,v.var_desc
 	  	  	 FROM Waste_Event_Meas  t
 	  	  	 Join Prod_Units_Base    p1 on p1.PU_Id = t.PU_Id
 	  	  	 Join Prod_Lines_Base pl on pl.PL_Id = p1.PL_Id
 	  	  	 Left Join Variables_Base   v on v.Var_Id = t.Conversion_Spec 
 	  	  	 Left Join Prod_Units_Base    p2 on p2.PU_Id = v.PU_Id
 	  	  	 Left Join Prod_Lines_Base pl2 on pl2.PL_Id = p2.PL_Id
 	  	  	 WHERE t.PU_Id = @Id
END
