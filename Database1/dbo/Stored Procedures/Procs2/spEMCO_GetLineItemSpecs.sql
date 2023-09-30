Create Procedure dbo.spEMCO_GetLineItemSpecs
@Order_Line_ID int,
@User_Id int
AS
select cols.Order_Spec_Id, cols.Spec_Desc, 
  U_Limit = Case When cols.Data_Type_Id > 50 Then pu.Phrase_Value Else cols.U_Limit End,
  Target = Case When cols.Data_Type_Id > 50 Then pt.Phrase_Value Else cols.Target End,
  L_Limit = Case When cols.Data_Type_Id > 50 Then pl.Phrase_Value Else cols.L_Limit End
from Customer_Order_Line_Specs cols
left outer join Phrase pu on pu.Data_Type_Id = cols.Data_Type_Id and pu.Phrase_Id = cols.U_Limit
left outer join Phrase pt on pt.Data_Type_Id = cols.Data_Type_Id and pt.Phrase_Id = cols.Target
left outer join Phrase pl on pl.Data_Type_Id = cols.Data_Type_Id and pl.Phrase_Id = cols.L_Limit
where cols.order_Line_ID = @Order_Line_Id
order by Spec_Desc
