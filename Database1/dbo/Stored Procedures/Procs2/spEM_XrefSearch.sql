CREATE PROCEDURE dbo.spEM_XrefSearch
 	 @TableId Int,
 	 @DS_Id 	 Int,
 	 @SubscriptionId 	  	 Int,
 	 @SearchString nvarchar(255)
  AS
 	 If @SearchString = ''
 	   Select @SearchString = '%'
 	 Else
 	   Begin
 	  	  	 Select @SearchString = REPLACE(@SearchString,'*','%')
 	  	  	 Select @SearchString = REPLACE(@SearchString,'?','_')
 	   End
 	 
 	 if charindex('%',@SearchString) = 0
 	  	 Select @SearchString = '%' + @SearchString + '%'
 	 If @TableId = 17  --'Departments'
 	  	 If @SubscriptionId is null
 	  	  	 Select DS_XRef_Id, x.Actual_Id, [Department] = IsNull(d.Dept_Desc,Actual_Text),[Foreign Key] = x.Foreign_Key,isnull(XML_Header,'') 
 	  	  	  	 From Data_Source_Xref  x
 	  	  	  	 Left Join Departments d on d.Dept_Id = x.Actual_Id
 	  	  	  	 Where x.Table_Id = 17 and x.DS_Id = @DS_Id and (d.Dept_Desc like @SearchString or Actual_Text like @SearchString)
 	  	  	  	  	  	  	  	 and Subscription_Id Is Null
 	  	  	 Order by Department
 	  	 Else
 	  	  	 Select DS_XRef_Id, x.Actual_Id, [Department] = IsNull(d.Dept_Desc,Actual_Text),[Foreign Key] = x.Foreign_Key, isnull(XML_Header,'') 
 	  	  	  	 From Data_Source_Xref  x
 	  	  	  	 Left Join Departments d on d.Dept_Id = x.Actual_Id
 	  	  	  	 Where x.Table_Id = 17 and x.DS_Id = @DS_Id and (d.Dept_Desc like @SearchString or Actual_Text like @SearchString)
 	  	  	  	  	  	  	 and Subscription_Id = @SubscriptionId 
 	  	  	  	 Order by Department
 	 Else If @TableId = 43  -- 'Production Units'
 	  	 If @SubscriptionId is null
 	  	  	 Select DS_XRef_Id, x.Actual_Id,[Production Line] = pl_Desc,[Production Unit] = IsNull(pu.PU_Desc,Actual_Text),[Foreign Key] = x.Foreign_Key,isnull(XML_Header,'')
 	  	  	  	 From Data_Source_Xref  x
 	  	  	  	 Left Join Prod_Units pu on pu.PU_Id = x.Actual_Id
 	  	  	  	 Left Join Prod_Lines pl on pl.Pl_Id = pu.Pl_Id
 	  	  	  	 Where x.Table_Id = @TableId and x.DS_Id = @DS_Id and (pu.PU_Desc like  @SearchString or Actual_Text like @SearchString)
 	  	  	  	  	  	  	  	 and Subscription_Id Is Null
 	  	  	  	 Order by pl_Desc,PU_Desc
 	  	 Else
 	  	  	 Select DS_XRef_Id, x.Actual_Id,[Production Line] = pl_Desc,[Production Unit] = IsNull(pu.PU_Desc,Actual_Text),[Foreign Key] = x.Foreign_Key,isnull(XML_Header,'')
 	  	  	  	 From Data_Source_Xref  x
 	  	  	  	 Left Join Prod_Units pu on pu.PU_Id = x.Actual_Id
 	  	  	  	 Left Join Prod_Lines pl on pl.Pl_Id = pu.Pl_Id
 	  	  	  	 Where x.Table_Id = @TableId and x.DS_Id = @DS_Id and (pu.PU_Desc like  @SearchString or Actual_Text like @SearchString)
 	  	  	  	  	  	  	 and Subscription_Id = @SubscriptionId 
 	  	  	  	 Order by pl_Desc,PU_Desc
 	 Else If @TableId = 18  -- 'Production Lines'
 	  	 If @SubscriptionId is null
 	  	  	 Select DS_XRef_Id, x.Actual_Id,[Production Line] = IsNull(pl_Desc,Actual_Text),[Foreign Key] = x.Foreign_Key,isnull(XML_Header,'') 
 	  	  	  	 From Data_Source_Xref  x
 	  	  	  	 Left Join Prod_Lines pl on pl.Pl_Id = x.Actual_Id
 	  	  	  	 Where x.Table_Id = @TableId and x.DS_Id = @DS_Id and (pl_Desc like  @SearchString or Actual_Text like @SearchString)
 	  	  	  	  	  	  	  	 and Subscription_Id Is Null
 	  	  	  	 Order by pl_Desc
 	  	 Else
 	  	  	 Select DS_XRef_Id, x.Actual_Id,[Production Line] = IsNull(pl_Desc,Actual_Text),[Foreign Key] = x.Foreign_Key,isnull(XML_Header,'') 
 	  	  	  	 From Data_Source_Xref  x
 	  	  	  	 Left Join Prod_Lines pl on pl.Pl_Id = x.Actual_Id
 	  	  	  	 Where x.Table_Id = @TableId and x.DS_Id = @DS_Id and (pl_Desc like  @SearchString or Actual_Text like @SearchString)
 	  	  	  	  	  	  	 and Subscription_Id = @SubscriptionId 
 	  	  	  	 Order by pl_Desc
 	 Else If @TableId = 19  -- 'Variable Groups'
 	  	 If @SubscriptionId is null
 	  	  	 Select DS_XRef_Id, x.Actual_Id,[Production Line] = pl_Desc,[Production Unit] = pu.PU_Desc,[Production Group] = IsNull(pug.PUG_Desc,Actual_Text),[Foreign Key] = x.Foreign_Key,isnull(XML_Header,'')
 	  	  	  	 From Data_Source_Xref  x
 	  	  	  	 Left Join PU_Groups pug on pug.PUG_Id = x.Actual_Id
 	  	  	  	 Left Join Prod_Units pu on pug.PU_Id = pu.PU_Id
 	  	  	  	 Left Join Prod_Lines pl on pl.Pl_Id = pu.Pl_Id
 	  	  	  	 Where x.Table_Id = @TableId and x.DS_Id = @DS_Id and (pug.PUG_Desc like  @SearchString or Actual_Text like @SearchString)
 	  	  	  	  	  	  	  	 and Subscription_Id Is Null
 	  	  	  	 Order by pl_Desc,PU_Desc,PUG_Desc
 	  	 Else
 	  	  	 Select DS_XRef_Id, x.Actual_Id,[Production Line] = pl_Desc,[Production Unit] = pu.PU_Desc,[Production Group] = IsNull(pug.PUG_Desc,Actual_Text),[Foreign Key] = x.Foreign_Key,isnull(XML_Header,'')
 	  	  	  	 From Data_Source_Xref  x
 	  	  	  	 Left Join PU_Groups pug on pug.PUG_Id = x.Actual_Id
 	  	  	  	 Left Join Prod_Units pu on pug.PU_Id = pu.PU_Id
 	  	  	  	 Left Join Prod_Lines pl on pl.Pl_Id = pu.Pl_Id
 	  	  	  	 Where x.Table_Id = @TableId and x.DS_Id = @DS_Id and (pug.PUG_Desc like  @SearchString or Actual_Text like @SearchString)
 	  	  	  	  	  	  	 and Subscription_Id = @SubscriptionId 
 	  	  	  	 Order by pl_Desc,PU_Desc,PUG_Desc
 	 Else If @TableId = 20  -- 'Variables'
 	  	 If @SubscriptionId is null
 	  	  	 Select DS_XRef_Id, x.Actual_Id,[Production Line] = pl_Desc,[Production Unit] = pu.PU_Desc,[Variable] = IsNull(v.Var_Desc,Actual_Text),[Foreign Key] = x.Foreign_Key,isnull(XML_Header,'')
 	  	  	  	 From Data_Source_Xref  x
 	  	  	  	 Left Join Variables v on v.Var_Id = x.Actual_Id
 	  	  	  	 Left Join Prod_Units pu on v.PU_Id = pu.PU_Id
 	  	  	  	 Left Join Prod_Lines pl on pl.Pl_Id = pu.Pl_Id
 	  	  	  	 Where x.Table_Id = @TableId and x.DS_Id = @DS_Id and (v.Var_Desc like  @SearchString or Actual_Text like @SearchString)
 	  	  	  	  	  	  	  	 and Subscription_Id Is Null
 	  	  	  	 Order by pl_Desc,PU_Desc,Var_Desc
 	  	 Else
 	  	  	 Select DS_XRef_Id, x.Actual_Id,[Production Line] = pl_Desc,[Production Unit] = pu.PU_Desc,[Variable] = IsNull(v.Var_Desc,Actual_Text),[Foreign Key] = x.Foreign_Key,isnull(XML_Header,'')
 	  	  	  	 From Data_Source_Xref  x
 	  	  	  	 Left Join Variables v on v.Var_Id = x.Actual_Id
 	  	  	  	 Left Join Prod_Units pu on v.PU_Id = pu.PU_Id
 	  	  	  	 Left Join Prod_Lines pl on pl.Pl_Id = pu.Pl_Id
 	  	  	  	 Where x.Table_Id = @TableId and x.DS_Id = @DS_Id and (v.Var_Desc like  @SearchString or Actual_Text like @SearchString)
 	  	  	  	  	  	  	 and Subscription_Id = @SubscriptionId 
 	  	  	  	 Order by pl_Desc,PU_Desc,Var_Desc
 	 Else If @TableId = 21  -- 'Product Families'
 	  	 If @SubscriptionId is null
 	  	  	 Select DS_XRef_Id, x.Actual_Id,[Product Family] = IsNull(pf.Product_Family_Desc,Actual_Text),[Foreign Key] = x.Foreign_Key,isnull(XML_Header,'')
 	  	  	  	 From Data_Source_Xref  x 
 	  	  	  	 Left Join Product_Family pf on pf.Product_Family_Id = x.Actual_Id
 	  	  	  	 Where x.Table_Id = @TableId and x.DS_Id = @DS_Id and (pf.Product_Family_Desc like  @SearchString or Actual_Text like @SearchString)
 	  	  	  	  	  	  	  	 and Subscription_Id Is Null
 	  	  	  	 Order by Product_Family_Desc
 	  	 Else
 	  	  	 Select DS_XRef_Id, x.Actual_Id,[Product Family] = IsNull(pf.Product_Family_Desc,Actual_Text),[Foreign Key] = x.Foreign_Key,isnull(XML_Header,'')
 	  	  	  	 From Data_Source_Xref  x 
 	  	  	  	 Left Join Product_Family pf on pf.Product_Family_Id = x.Actual_Id
 	  	  	  	 Where x.Table_Id = @TableId and x.DS_Id = @DS_Id and (pf.Product_Family_Desc like  @SearchString or Actual_Text like @SearchString)
 	  	  	  	  	  	  	 and Subscription_Id = @SubscriptionId 
 	  	  	  	 Order by Product_Family_Desc
 	 Else If @TableId = 22  -- 'Product Groups'
 	  	 If @SubscriptionId is null
 	  	  	 Select DS_XRef_Id, x.Actual_Id,[Product Group] = IsNull(Product_Grp_Desc,Actual_Text),[Foreign Key] = x.Foreign_Key,isnull(XML_Header,'')
 	  	  	  	 From Data_Source_Xref  x
 	  	  	  	 Left Join Product_Groups p on p.Product_Grp_Id = x.Actual_Id
 	  	  	  	 Where x.Table_Id = @TableId and x.DS_Id = @DS_Id and (Product_Grp_Desc like  @SearchString or Actual_Text like @SearchString)
 	  	  	  	  	  	  	  	 and Subscription_Id Is Null
 	  	  	  	 Order by Product_Grp_Desc
 	  	 Else
 	  	  	 Select DS_XRef_Id, x.Actual_Id,[Product Group] = IsNull(Product_Grp_Desc,Actual_Text),[Foreign Key] = x.Foreign_Key,isnull(XML_Header,'')
 	  	  	  	 From Data_Source_Xref  x
 	  	  	  	 Left Join Product_Groups p on p.Product_Grp_Id = x.Actual_Id
 	  	  	  	 Where x.Table_Id = @TableId and x.DS_Id = @DS_Id and (Product_Grp_Desc like  @SearchString or Actual_Text like @SearchString)
 	  	  	  	  	  	  	 and Subscription_Id = @SubscriptionId 
 	  	  	  	 Order by Product_Grp_Desc
 	 Else If @TableId = 23  -- 'Products'
 	  	 If @SubscriptionId is null
 	  	  	 Select DS_XRef_Id, x.Actual_Id,[Product Code] = IsNull(Prod_Code,Actual_Text),[Foreign Key] = x.Foreign_Key,isnull(XML_Header,'')
 	  	  	  	 From Data_Source_Xref  x
 	  	  	  	 Left Join Products p on p.Prod_Id = x.Actual_Id
 	  	  	  	 Where x.Table_Id = @TableId and x.DS_Id = @DS_Id and (Prod_Code like  @SearchString or Actual_Text like @SearchString)
 	  	  	  	  	  	  	  	 and Subscription_Id Is Null
 	  	  	  	 Order by Prod_Code
 	  	 Else
 	  	  	 Select DS_XRef_Id, x.Actual_Id,[Product Code] = IsNull(Prod_Code,Actual_Text),[Foreign Key] = x.Foreign_Key,isnull(XML_Header,'')
 	  	  	  	 From Data_Source_Xref  x
 	  	  	  	 Left Join Products p on p.Prod_Id = x.Actual_Id
 	  	  	  	 Where x.Table_Id = @TableId and x.DS_Id = @DS_Id and (Prod_Code like  @SearchString or Actual_Text like @SearchString)
 	  	  	  	  	  	  	 and Subscription_Id = @SubscriptionId 
 	  	  	  	 Order by Prod_Code
 	 Else If @TableId = 13  -- 'Production Execution Paths'
 	  	 If @SubscriptionId is null
 	  	  	 Select DS_XRef_Id, x.Actual_Id,[Path] = IsNull(Path_Desc,Actual_Text),[Foreign Key] = x.Foreign_Key,isnull(XML_Header,'')
 	  	  	  	 From Data_Source_Xref  x
 	  	  	  	 Left Join Prdexec_Paths p on p.Path_Id = x.Actual_Id
 	  	  	  	 Where x.Table_Id = @TableId and x.DS_Id = @DS_Id and (Path_Desc like  @SearchString or Actual_Text like @SearchString)
 	  	  	  	  	  	  	  	 and Subscription_Id Is Null
 	  	  	  	 Order by Path_Desc
 	  	 Else
 	  	  	 Select DS_XRef_Id, x.Actual_Id,[Product Code] = IsNull(Prod_Code,Actual_Text),[Foreign Key] = x.Foreign_Key,isnull(XML_Header,'')
 	  	  	  	 From Data_Source_Xref  x
 	  	  	  	 Left Join Products p on p.Prod_Id = x.Actual_Id
 	  	  	  	 Where x.Table_Id = @TableId and x.DS_Id = @DS_Id and (Prod_Code like  @SearchString or Actual_Text like @SearchString)
 	  	  	  	  	  	  	 and Subscription_Id = @SubscriptionId 
 	  	  	  	 Order by Prod_Code
 	 Else If @TableId = 24  -- 'Reasons'
 	  	 If @SubscriptionId is null
 	  	  	 Select DS_XRef_Id, x.Actual_Id,[Reason] = IsNull(Event_Reason_Name,Actual_Text),[Foreign Key] = x.Foreign_Key,isnull(XML_Header,'')
 	  	  	  	 From Data_Source_Xref  x
 	  	  	  	 Left Join Event_Reasons e on e.Event_Reason_Id = x.Actual_Id 
 	  	  	  	 Where x.Table_Id = @TableId and x.DS_Id = @DS_Id and (Event_Reason_Name like  @SearchString or Actual_Text like @SearchString)
 	  	  	  	  	  	  	  	 and Subscription_Id Is Null
 	  	  	  	 Order by Event_Reason_Name
 	  	 Else
 	  	  	 Select DS_XRef_Id, x.Actual_Id,[Reason] = IsNull(Event_Reason_Name,Actual_Text),[Foreign Key] = x.Foreign_Key,isnull(XML_Header,'')
 	  	  	  	 From Data_Source_Xref  x
 	  	  	  	 Left Join Event_Reasons e on e.Event_Reason_Id = x.Actual_Id 
 	  	  	  	 Where x.Table_Id = @TableId and x.DS_Id = @DS_Id and (Event_Reason_Name like  @SearchString or Actual_Text like @SearchString)
 	  	  	  	  	  	  	 and Subscription_Id = @SubscriptionId 
 	  	  	  	 Order by Event_Reason_Name
 	 Else If @TableId = 25  -- 'Reason Categories'
 	  	 If @SubscriptionId is null
 	  	  	 Select DS_XRef_Id, x.Actual_Id,[Category] =IsNull( ERC_Desc,Actual_Text),[Foreign Key] = x.Foreign_Key,isnull(XML_Header,'')
 	  	  	  	 From Data_Source_Xref  x
 	  	  	  	 Left Join Event_Reason_Catagories e on e.ERC_Id = x.Actual_Id 
 	  	  	  	 Where x.Table_Id = @TableId and x.DS_Id = @DS_Id and (ERC_Desc like  @SearchString or Actual_Text like @SearchString)
 	  	  	  	  	  	  	  	 and Subscription_Id Is Null
 	  	  	  	 Order by ERC_Desc
 	  	 Else
 	  	  	 Select DS_XRef_Id, x.Actual_Id,[Category] = IsNull(ERC_Desc,Actual_Text),[Foreign Key] = x.Foreign_Key,isnull(XML_Header,'')
 	  	  	  	 From Data_Source_Xref  x
 	  	  	  	 Left Join Event_Reason_Catagories e on e.ERC_Id = x.Actual_Id 
 	  	  	  	 Where x.Table_Id = @TableId and x.DS_Id = @DS_Id and (ERC_Desc like  @SearchString or Actual_Text like @SearchString)
 	  	  	  	  	  	  	 and Subscription_Id = @SubscriptionId 
 	  	  	  	 Order by ERC_Desc
 	 Else If @TableId = 26  -- 'Bill Of Material Formulations'
 	  	 If @SubscriptionId is null
 	  	  	 Select DS_XRef_Id, x.Actual_Id,[Formulation] = IsNull(BOM_Formulation_Desc,Actual_Text),[Foreign Key] = x.Foreign_Key,isnull(XML_Header,'')
 	  	  	  	 From Data_Source_Xref  x
 	  	  	  	 Left Join Bill_Of_Material_Formulation b on b.BOM_Formulation_Id = x.Actual_Id
 	  	  	  	 Where x.Table_Id = @TableId and x.DS_Id = @DS_Id and (BOM_Formulation_Desc like  @SearchString or Actual_Text like @SearchString)
 	  	  	  	  	  	  	  	 and Subscription_Id Is Null
 	  	  	  	 Order by BOM_Formulation_Desc
 	  	 Else
 	  	  	 Select DS_XRef_Id, x.Actual_Id,[Formulation] = IsNull(BOM_Formulation_Desc,Actual_Text),[Foreign Key] = x.Foreign_Key,isnull(XML_Header,'')
 	  	  	  	 From Data_Source_Xref  x
 	  	  	  	 Left Join Bill_Of_Material_Formulation b on b.BOM_Formulation_Id = x.Actual_Id
 	  	  	  	 Where x.Table_Id = @TableId and x.DS_Id = @DS_Id and (BOM_Formulation_Desc like  @SearchString or Actual_Text like @SearchString)
 	  	  	  	  	  	  	 and Subscription_Id = @SubscriptionId 
 	  	  	  	 Order by BOM_Formulation_Desc
 	 Else If @TableId = 28  -- 'Bill Of Material Formulation item'
 	  	 If @SubscriptionId is null
 	  	  	 Select DS_XRef_Id, x.Actual_Id,[Formulation] = BOM_Formulation_Desc,[Item] = IsNull(BOM_Formulation_Order,Actual_Text),[Foreign Key] = x.Foreign_Key,isnull(XML_Header,'')
 	  	  	  	 From Data_Source_Xref  x
 	  	  	  	 Left Join Bill_Of_Material_Formulation_Item b on b.BOM_Formulation_Item_Id = x.Actual_Id
 	  	  	  	 Left Join Bill_Of_Material_Formulation c on b.BOM_Formulation_Id = c.BOM_Formulation_Id
 	  	  	  	 Where x.Table_Id = @TableId and x.DS_Id = @DS_Id and (BOM_Formulation_Desc like  @SearchString or Actual_Text like @SearchString)
 	  	  	  	  	  	  	  	 and Subscription_Id Is Null
 	  	  	  	 Order by BOM_Formulation_Desc
 	  	 Else
 	  	  	 Select DS_XRef_Id, x.Actual_Id,[Formulation] = BOM_Formulation_Desc,[Item] = IsNull(BOM_Formulation_Order,Actual_Text),[Foreign Key] = x.Foreign_Key,isnull(XML_Header,'')
 	  	  	  	 From Data_Source_Xref  x
 	  	  	  	 Left Join Bill_Of_Material_Formulation_Item b on b.BOM_Formulation_Item_Id = x.Actual_Id
 	  	  	  	 Left Join Bill_Of_Material_Formulation c on b.BOM_Formulation_Id = c.BOM_Formulation_Id
 	  	  	  	 Where x.Table_Id = @TableId and x.DS_Id = @DS_Id and (BOM_Formulation_Desc like  @SearchString or Actual_Text like @SearchString)
 	  	  	  	  	  	  	 and Subscription_Id = @SubscriptionId 
 	  	  	  	 Order by BOM_Formulation_Desc
