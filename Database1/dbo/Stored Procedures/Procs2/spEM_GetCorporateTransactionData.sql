CREATE PROCEDURE dbo.spEM_GetCorporateTransactionData
  AS
  SELECT Linked_Server_Desc_Alias = Coalesce(l.Linked_Server_Desc_Alias,Linked_Server_Desc) ,l.Linked_Server_Id,Linked_Server_Desc
    FROM Linkable_Remote_Servers l
    Order by Linked_Server_Desc_Alias
  Select Trans_Id,Trans_Desc from Transactions Where Trans_Type_Id = 2 and Linked_Server_Id is null and Corp_Trans_Id is null and Approved_On is null
  SELECT t.Linked_Server_Id,t.Trans_Id,Trans_Desc =  Coalesce(l.Linked_Server_Desc_Alias,l.Linked_Server_Desc) ,ProdFilter = Coalesce(tf1.Value,''),VarFilter = coalesce(tf2.Value,''),t.Corp_Trans_Id
 	 From transactions  t
 	 Join Transactions t1 On t1.trans_Id = t.Corp_Trans_Id and t1.Approved_On is null
 	 Join Linkable_Remote_Servers l on l.Linked_Server_Id = t.Linked_Server_Id
 	 Left Join Transaction_Filter_Values tf1 on tf1.Transaction_Filter_Id = t.Prod_Id_Filter_Id
 	 Left Join Transaction_Filter_Values tf2 on tf2.Transaction_Filter_Id = t.Var_Id_Filter_Id
 	 Where t.Corp_Trans_Id is not null
    Order by t.Corp_Trans_Id,t.Trans_Desc
  Select Distinct v.Var_Id,v.Var_Desc,v.Test_Name 
 	 From Variables v
 	 Where v.Test_Name is not null
  Select  Prod_Id,Prod_Code
 	 From Products
 	 
