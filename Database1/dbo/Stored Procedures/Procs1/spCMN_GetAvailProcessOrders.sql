Create Procedure dbo.spCMN_GetAvailProcessOrders
 	 @EventId int,
        @Language_Id int
  AS
Declare @ProdId 	  	 Int,
 	 @TS 	 DateTime,
 	 @PUId 	  	 Int,
        @Col1                   nvarchar(50),
        @Col2                   nvarchar(50),
        @Col3                   nvarchar(50),         
        @Col4                   nvarchar(50),
        @Col5                   nvarchar(50),
        @Col6                   nvarchar(50), 
        @Col7                   nvarchar(50),
        @Col8                   nvarchar(50),
        @Col9                   nvarchar(50),         
        @Col10                  nvarchar(50),         
        @Col11                  nvarchar(50),
        @Col12                  nvarchar(50),
        @Col13                  nvarchar(50),         
        @Col14                  nvarchar(50),
        @Col15                  nvarchar(50),
        @Col16                  nvarchar(50), 
        @Col17                  nvarchar(50),
        @Col18                  nvarchar(50),
        @Col19                  nvarchar(50),
        @SQL                    VarChar(8000)
--If Required Prompt is not found, substitute the English prompt
 Select @Col1 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24126
 Select @Col2 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24127
 Select @Col3 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24128
 Select @Col4 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24129
 Select @Col5 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24130
 Select @Col6 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24131
 Select @Col7 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24132
 Select @Col8 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24133
 Select @Col9 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24134
 Select @Col10 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24135
 Select @Col11 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24136
 Select @Col12 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24137
 Select @Col13 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24138
 Select @Col14 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24139
 Select @Col15 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24140
 Select @Col16 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24141
 Select @Col17 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24142
 Select @Col18 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24143
 Select @Col19 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24144
Select @ProdId = Applied_Product,@TS = TimeStamp,@PUId = PU_Id
 From Events
 Where Event_Id = @EventId
Select @PUId = coalesce(Master_Unit,PU_Id)
  From Prod_Units
  Where PU_Id = @PUId
If @ProdId is null
  Select @ProdId = Prod_Id 
    FROM Production_starts ps
    Where pu_id = @PUId  and Start_Time <= @TS and (End_Time > @TS or End_Time is Null)
Create Table #T (TIMECOLUMNS nvarchar(50))
Insert Into #T  (TIMECOLUMNS) Values (@Col3)
select * from #T
Drop Table #T
Select @SQL = 'Select Order_Line_Id as [' + @Col1 + '], Is_Active as [' + @Col2 + '], Complete_Date as [' + @Col3 + '],
               Ordered_Quantity as [' + @Col4 + '], Consignee_Id as [' + @Col5 + '], Line_Item_Number  as [' + @Col6 + '], 
               Prod_Id as [' + @Col7 + '], Comment_Id as [' + @Col8 + '], Order_Id as [' + @Col9 + '],
               Dimension_Y as [' + @Col10 + '], Dimension_Z as [' + @Col11 + '], Dimension_A as [' + @Col12 + '],
               Dimension_X as [' + @Col13 + '], Ordered_UOM as [' + @Col14 + '], Order_Line_General_1 as [' + @Col15 + '],
               Order_Line_General_2 as [' + @Col16 + '], Order_Line_General_3 as [' + @Col17 + '], 
               Order_Line_General_4 as [' + @Col18 + '], Order_Line_General_5 as [' + @Col19 + '] from Customer_Order_Line_Items'
Exec (@SQL)
