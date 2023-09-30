Create Procedure dbo.spSV_GetHistory
@Id int,
@Case tinyint,
@Language_Id int = 0
AS
--
-- Case
-- Production_Plan = 1
-- Production_Setup = 2
-- Production_Setup_Detail = 3
--
Declare @Col1 nVarChar(50),
        @Col2 nVarChar(50),
        @Col3 nVarChar(50),
        @Col4 nVarChar(50),
        @Col5 nVarChar(50),
        @Col6 nVarChar(50),
        @Col7 nVarChar(50),
        @Col8 nVarChar(50),
        @Col9 nVarChar(50),
        @Col10 nVarChar(50),
        @Col11 nVarChar(50),
        @Col12 nVarChar(50),
        @Col13 nVarChar(50),
        @Col14 nVarChar(50),
        @Col15 nVarChar(50),
        @Col16 nVarChar(50),
        @Col17 nVarChar(50),
        @Col18 nVarChar(50),
        @Col19 nVarChar(50),
        @Col20 nVarChar(50),
        @Col21 nVarChar(50),
        @Col22 nVarChar(50),
        @Col23 nVarChar(50),
        @SQL nVarChar(2000)
Create Table #T (TIMECOLUMNS nvarchar(50))
If @Case = 1
  Begin
    Select @Col1 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20480 --Change Time
    Insert Into #T  (TIMECOLUMNS) Values (@Col1)
    Select @Col1 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20481 --Forecast Start
    Insert Into #T  (TIMECOLUMNS) Values (@Col1)
    Select @Col1 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20482 --Forecast End
    Insert Into #T  (TIMECOLUMNS) Values (@Col1)
    select * from #T
    Select @Col1 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20483 --User
    Select @Col2 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20480 --Change Time
    Select @Col3 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20484 --Trans Type
    Select @Col4 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20072 --Process Order
    Select @Col5 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20180 --Status
    Select @Col6 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20387 --Product Description
    Select @Col7 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20386 --Product Code
    Select @Col8 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20181 --Block Number
    Select @Col9 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20053 --Quantity
    Select @Col10 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20481 --Forecast Start
    Select @Col11 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20482 --Forecast End
    Select @Col12 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20005 --Production Rate
    Select @Col13 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20179 --Type
    Select @Col14 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20485 --Source Order
    Select @Col15 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20411 --User General 1
    Select @Col16 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20412 --User General 2
    Select @Col17 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20413 --User General 3
    Select @Col18 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20177 --Info
    Select @SQL = 'Select u.Username as [' + @Col1 + '], pp.Modified_On as [' + @Col2 + '], t.DBTT_Desc as [' + @Col3 + '], pp.Process_Order as [' + @Col4 + '], 
           ps.PP_Status_Desc as [' + @Col5 + '], p.Prod_Desc as [' + @Col6 + '], p.Prod_Code as [' + @Col7 + '], pp.Block_Number as [' + @Col8 + '], 
           Round(pp.Forecast_Quantity, 1) as [' + @Col9 + '], pp.Forecast_Start_Date as [' + @Col10 + '], pp.Forecast_End_Date as [' + @Col11 + '],
           Round(pp.Production_Rate, 1) as [' + @Col12 + '],
           ppt.PP_Type_Name as [' + @Col13 + '], pp2.Process_Order as [' + @Col14 + '], pp.User_General_1 as [' + @Col15 + '], 
           pp.User_General_2 as [' + @Col16 + '], pp.User_General_3 as [' + @Col17 + '], pp.Extended_Info as [' + @Col18 + ']
           From Production_Plan_History pp 
           Join Production_Plan_Statuses ps on ps.pp_status_id = pp.pp_status_id
           Join Products p on p.prod_id = pp.Prod_Id
           Join DB_Trans_Types t on t.DBTT_Id = pp.DBTT_Id
           Join Users u on u.User_Id = pp.User_Id
           Left Outer Join Production_Plan_Types ppt on pp.pp_type_id = ppt.pp_type_id
           Left Outer Join Production_Plan pp2 on pp.Source_PP_Id = pp2.PP_Id
           Where pp.PP_Id = ' + Convert(nvarchar(10),@Id) +   ' Order By pp.Modified_On desc'
 	  	 EXECUTE (@SQL)
  End
Else If @Case = 2
  Begin
    Select @Col1 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20480 --Change Time
    Insert Into #T  (TIMECOLUMNS) Values (@Col1)
    select * from #T
    Select @Col1 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20483 --User
    Select @Col2 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20480 --Change Time
    Select @Col3 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20484 --Trans Type
    Select @Col4 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20280 --Sequence
    Select @Col5 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20180 --Status
    Select @Col6 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20486 --Reps
    Select @Col7 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20424 --Base Dimension Z
    Select @Col8 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20426 --Base Dimension A
    Select @Col9 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20420 --Base Dimension X
    Select @Col10 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20422 --Base Dimension Y
    Select @Col11 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20487 --Pattern Code
    Select @Col12 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20241 --Base General 1
    Select @Col13 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20423 --Base General 2
    Select @Col14 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20425 --Base General 3
    Select @Col15 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20411 --User General 1
    Select @Col16 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20412 --User General 2
    Select @Col17 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20413 --User General 3
    Select @Col18 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20177 --Info
    Select @Col19 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20427 --Base General 4
    Select @Col20 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20488 --Shrinkage
    Select @SQL = 'Select u.Username as [' + @Col1 + '], ps.Modified_On as [' + @Col2 + '], t.DBTT_Desc as [' + @Col3 + '], ps.Implied_Sequence as [' + @Col4 + '], 
           pps.PP_Status_Desc as [' + @Col5 + '], Pattern_Repititions as [' + @Col6 + '], Round(ps.Base_Dimension_Z, 1) as [' + @Col7 + '], 
           Round(ps.Base_Dimension_A, 1) as [' + @Col8 + '], Round(ps.Base_Dimension_X, 1) as [' + @Col9 + '], 
           Round(ps.Base_Dimension_Y, 1) as [' + @Col10 + '], Pattern_Code as [' + @Col11 + '], 
           Round(ps.Base_General_1, 1) as [' + @Col12 + '], Round(ps.Base_General_2, 1) as [' + @Col13 + '], 
           Round(ps.Base_General_1, 1) as [' + @Col14 + '], Round(ps.Base_General_1, 1) as [' + @Col19 + '], 
           Round(ps.Shrinkage, 1) as [' + @Col20 + '], ps.User_General_1 as [' + @Col15 + '], ps.User_General_2 as [' + @Col16 + '], 
           ps.User_General_3 as [' + @Col17 + '], ps.Extended_Info as [' + @Col18 + ']       
           From Production_Setup_History ps
           Left Outer Join Production_Plan_Statuses pps on pps.PP_Status_Id = ps.PP_Status_Id
           Join DB_Trans_Types t on t.DBTT_Id = ps.DBTT_Id
           Join Users u on u.User_Id = ps.User_Id
           Where ps.PP_Setup_Id = ' + Convert(nvarchar(10),@Id) + 
           ' Order By ps.Modified_On desc'
 	  	 EXECUTE (@SQL)
  End
Else If @Case = 3
  Begin
    Select @Col1 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20480 --Change Time
    Insert Into #T  (TIMECOLUMNS) Values (@Col1)
    select * from #T
    Select @Col1 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20483 --User
    Select @Col2 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20480 --Change Time
    Select @Col3 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20484 --Trans Type
    Select @Col4 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20289 --Num
    Select @Col5 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20180 --Status
    Select @Col6 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20189 --Dimension X
    Select @Col7 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20190 --Dimension Y
    Select @Col8 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20191 --Dimension Z
    Select @Col9 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20192 --Dimension A
    Select @Col10 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20206 --Customer Order
    Select @Col11 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20386 --Product Code
    Select @Col12 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20207 --Customer Code
    Select @Col13 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20209 --Order Instructions
    Select @Col15 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20411 --User General 1
    Select @Col16 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20412 --User General 2
    Select @Col17 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20413 --User General 3
    Select @Col18 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20177 --Info
    Select @SQL = 'Select u.Username as [' + @Col1 + '], psd.Modified_On as [' + @Col2 + '], t.DBTT_Desc as [' + @Col3 + '], psd.Element_Number as [' + @Col4 + '], 
           ps.ProdStatus_Desc as [' + @Col5 + '], Round(psd.Target_Dimension_X, 1) as [' + @Col6 + '], 
           Round(psd.Target_Dimension_Y, 1) as [' + @Col7 + '], Round(psd.Target_Dimension_Z, 1) as [' + @Col8 + '], 
           Round(psd.Target_Dimension_A, 1) as [' + @Col9 + '], co.Plant_Order_Number as [' + @Col10 + '], 
           c.Customer_Code as [' + @Col12 + '], Coalesce(p1.Prod_Code, p2.Prod_Code) as [' + @Col11 + '], 
           co.Order_Instructions as [' + @Col13 + '],
           psd.User_General_1 as [' + @Col15 + '], psd.User_General_2 as [' + @Col16 + '], 
           psd.User_General_3 as [' + @Col17 + '], psd.Extended_Info as [' + @Col18 + ']       
           From Production_Setup_Detail_History psd
           Join Production_Status ps on ps.ProdStatus_Id = psd.Element_Status
           Left Outer Join Products p2 on p2.prod_id = psd.Prod_Id
           Join DB_Trans_Types t on t.DBTT_Id = psd.DBTT_Id
           Join Users u on u.User_Id = psd.User_Id
           Left Outer join Customer_Order_Line_Items coli on coli.Order_Line_Id = psd.Order_Line_Id
           Left Outer Join Products p1 on p1.Prod_Id = coli.Prod_id
           Left Outer join customer_Orders co on co.Order_Id = coli.Order_Id
           Left Outer Join Customer c on c.Customer_Id = co.Customer_Id
           Where psd.PP_Setup_Detail_Id = ' + Convert(nvarchar(10),@Id) + 
           ' Order By psd.Modified_On desc'
  	  	 EXECUTE (@SQL)
 End
Drop Table #T
