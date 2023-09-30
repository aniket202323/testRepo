CREATE Procedure dbo.spGE_GetSubstitutionInventory
@HistoryId int,
@Language_Id int
AS
set nocount on
 	 
DECLARE @Timestamp 	  	 Datetime,
 	 @PU_Id 	  	  	 Int,
 	 @Alt_Spec 	  	 Int,
 	 @Prim_Spec 	  	 Int,
 	 @CurrentProduct 	  	 Int,
 	 @Primary_Prod_Code 	 nvarchar(25),
 	 @Alternate_Prod_Code 	 nvarchar(25),
 	 @Prod_Id 	  	 Int,
 	 @PC 	  	  	 nvarchar(25),
 	 @AppliedProdId 	  	 Int,
 	 @Prop_Id 	  	 Int,
 	 @Now 	  	  	 DateTime,
 	 @Char_Id 	  	 Int,
 	 @PEI_Id                 Int,
        @Col2                   nvarchar(50),
        @Col3                   nvarchar(50),         
        @Col4                   nvarchar(50),
        @Col5                   nvarchar(50),
        @Col6                   nvarchar(50), 
        @Col7                   nvarchar(50),
        @Col8                   nvarchar(50),
        @Col9                   nvarchar(50),         
        @SQL                    nvarchar(2000)
--If Required Prompt is not found, substitute the English prompt
 Select @Col2 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24107
 Select @Col3 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24061
 Select @Col4 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24108
 Select @Col5 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24105
 Select @Col6 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24109
 Select @Col7 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24110
 Select @Col8 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24111
 Select @Col9 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24039
Select @Now = timestamp,@PEI_Id = PEI_Id
 from prdExec_Input_Event_History
 Where Input_Event_History_Id = @HistoryId
select @PU_Id = PU_Id,@Alt_Spec = Alternate_Spec_Id,@Prim_Spec = Primary_Spec_Id
  From PrdExec_Inputs
  Where PEI_Id = @PEI_Id
select @CurrentProduct = Prod_Id 
  From Production_Starts
  Where PU_Id = @PU_Id and (Start_Time <= @Now and  (End_time > @Now or  End_time is null))
If @Prim_Spec is not null
 Begin
   Select @Prop_Id = Prop_Id
     From Specifications
     Where Spec_Id = @Prim_Spec 
   Select @Char_Id = Null
   Select @Char_Id = Char_Id
     From  PU_Characteristics
     Where PU_Id  = @PU_Id And Prop_Id = @Prop_Id and Prod_Id = @CurrentProduct
   If @Char_Id is Null
     Select @Primary_Prod_Code = Null
   Else
     Select @Primary_Prod_Code = Target
      From Active_Specs
      Where Spec_Id  = @Prim_Spec and  Char_Id = @Char_Id
      and (Effective_Date < @Now and (Expiration_Date is null or Expiration_Date > @Now))
 End
else
  select @Primary_Prod_Code = Null
If @Alt_Spec is not null
 Begin
   Select @Prop_Id = Prop_Id
     From Specifications
     Where Spec_Id = @Alt_Spec 
   Select @Char_Id = Null
   Select @Char_Id = Char_Id
     From  PU_Characteristics
     Where PU_Id  = @PU_Id And Prop_Id = @Prop_Id and Prod_Id = @CurrentProduct
   If @Char_Id is null 
     Select @Alternate_Prod_Code = Null
   Else
     Select @Alternate_Prod_Code = Target
      From Active_Specs
      Where Spec_Id  = @Alt_Spec and  Char_Id = @Char_Id
      and (Effective_Date < @Now and (Expiration_Date is null or Expiration_Date > @Now ))
 End
else
  select @Alternate_Prod_Code = Null
If @CurrentProduct = 1 
  Begin
    select @Alternate_Prod_Code = Null
    select @Primary_Prod_Code = Null
  End
 Create Table #Output (Event_Id int,Icon_Id Int,PU_Id Int,Event nvarchar(25),Status nvarchar(25),Product nvarchar(25) null ,Time DateTime,Age Int,Weight Int NULL,Length Int NULL,Width Int NULL,Applied_Product Int Null)
-- Create INdex  PIndex on #Output (Product)
-- Create INdex  PTIndex on #Output (time) 
Insert Into #Output(Event_Id,Event,Status ,Time,Pu_Id,Icon_Id,Age,Weight,Length,Width,Applied_Product) 
   Select e.Event_Id,Event_num,
          ProdStatus_Desc = case When  PEIP_Id is null then ProdStatus_Desc
                                 Else 'In Progress'
 	  	  	     End,e.Timestamp,
          e.PU_Id,Icon_Id,datediff(minute,e.timestamp,dbo.fnServer_CmnGetDate(getUTCdate())),
          ed.final_dimension_x,ed.final_dimension_y,ed.final_dimension_z,e.Applied_Product
    From  PrdExec_Input_Sources pis
    Join  PrdExec_Input_Source_Data pisd on pisd.PEIS_Id = pis.PEIS_Id
    Join Events e  on  pis.PU_Id = e.PU_Id and  pisd.Valid_Status = e.event_status
    left outer Join Event_Details ed on ed.event_id = e.event_id
    Join  Production_Status p on p.ProdStatus_Id = e.event_status
    Left Join PrdExec_Input_Event pie on pie.event_id = e.event_id
    where pis.PEI_Id = @PEI_Id
 	 Delete From #Output
 	   Where Event_Id in (select  Event_Id 
 	  	 From PrdExec_Input_Event  pie
 	  	 Join PrdExec_Inputs pis On pis.pei_Id = Pie.Pei_Id and pis.Lock_Inprogress_Input = 1)
Update #Output  set product =  
(Select Prod_code = CASE when #Output.Applied_Product Is null then pp.Prod_code
                    Else
 	  	  	 pp2.Prod_Code
 	  	     End
     from Production_Starts s
     Left Join  Products pp on pp.prod_id = s.prod_id
     Left Join  Products pp2 on pp2.prod_id = #Output.Applied_Product
     where s.pu_id = #Output.PU_Id and (Start_Time <= #Output.Time and  (s.End_time > #Output.Time or  s.End_time is null)))
If @Primary_Prod_Code is Not Null
  If @Alternate_Prod_Code is not Null
    Delete From #Output where product <> @Alternate_Prod_Code and product <> @Primary_Prod_Code
  Else
    Delete From #Output where product <> @Primary_Prod_Code
Else
 If @Alternate_Prod_Code is not Null
    Delete From #Output where  product <> @Alternate_Prod_Code
Select @SQL = 'Select [Key] = Event_Id, Event as [' + @Col2 + '], Status as [' + @Col3 + '], 
               Product as [' + @Col4 + '], Time as [' + @Col5 + '], Coalesce(Age,0) as [' + @Col6 + '], 
               Coalesce(Convert(nvarchar(25),Weight),''N/A'') as [' + @Col7 + '],
               Coalesce(Convert(nvarchar(25),Length),''N/A'') as [' + @Col8 + '],
               Coalesce(Convert(nvarchar(25),Width),''N/A'') as [' + @Col9 + ']
               from #Output Order by [' + @Col2 + ']'
exec (@SQL)
drop table #Output
set nocount off
