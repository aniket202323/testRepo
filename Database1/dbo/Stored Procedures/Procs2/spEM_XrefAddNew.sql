CREATE PROCEDURE dbo.spEM_XrefAddNew
 	 @TableId  	  	  	  	  	 Int,
 	 @DS_Id 	  	  	  	  	  	 Int,
 	 @SubScriptionId 	  	 Int,
 	 @SearchString 	  	  	 nVarChar(100)
  AS
 	 Select @SearchString = '%' + @SearchString + '%'
 	 If @TableId = 17  --'Departments'
 	  	 If @SubScriptionId is null
 	  	  	 Select [Key] = Dept_Id, [Department] = d.Dept_Desc 
 	  	  	  	 From Departments d 
 	  	  	  	 Where Dept_Desc Like @SearchString And Dept_Id Not In (Select Actual_Id From Data_Source_Xref  	 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Where Table_Id = @TableId and 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 DS_Id = @DS_Id and 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Actual_Id is not null and 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 subscription_Id Is Null)
 	  	  	  	 Order by Dept_Desc
 	  	 Else
 	  	  	 Select [Key] = Dept_Id, [Department] = d.Dept_Desc 
 	  	  	  	 From Departments d 
 	  	  	  	 Where Dept_Desc Like @SearchString And Dept_Id Not In (Select Actual_Id From Data_Source_Xref  	 Where Table_Id = @TableId and DS_Id = @DS_Id and Actual_Id is not null and subscription_Id = @SubScriptionId)
 	  	  	  	 Order by Dept_Desc
 	 Else If @TableId = 18  -- 'Production Lines'
 	  	 If @SubScriptionId is null
 	  	  	 Select [Key] = pl.Pl_Id,[Production Line] = pl_Desc
 	  	  	  	 From Prod_Lines pl 
 	  	  	  	 Where pl_Desc Like @SearchString And pl.Pl_Id Not IN (Select Actual_Id From Data_Source_Xref  	 Where Table_Id = @TableId and DS_Id = @DS_Id and Actual_Id is not null and subscription_Id Is Null)
 	  	  	  	 And pl.Pl_Id > 0
 	  	  	  	 Order by pl_Desc
 	  	 Else
 	  	  	 Select [Key] = pl.Pl_Id,[Production Line] = pl_Desc
 	  	  	  	 From Prod_Lines pl 
 	  	  	  	 Where pl_Desc Like @SearchString And pl.Pl_Id Not IN (Select Actual_Id From Data_Source_Xref  	 Where Table_Id = @TableId and DS_Id = @DS_Id and Actual_Id is not null and subscription_Id = @SubScriptionId)
 	  	  	  	 And pl.Pl_Id > 0
 	  	  	  	 Order by pl_Desc
 	 Else If @TableId = 19  -- 'Variable Groups'
 	  	 If @SubScriptionId is null
 	  	  	 Select [Key] =  pug.PUG_Id,[Production Line] = pl_Desc,[Production Unit] = pu.PU_Desc,[Production Group] = pug.PUG_Desc
 	  	  	  	 From PU_Groups pug 
 	  	  	  	 Join Prod_Units pu on pug.PU_Id = pu.PU_Id
 	  	  	  	 Join Prod_Lines pl on pl.Pl_Id = pu.Pl_Id
 	  	  	  	 Where PUG_Desc Like @SearchString And pug.PUG_Id Not IN (Select Actual_Id From Data_Source_Xref  	 Where Table_Id = @TableId and DS_Id = @DS_Id and Actual_Id is not null and subscription_Id Is Null)
 	  	  	  	 And pug.PUG_Id > 0
 	  	  	  	 Order by pl_Desc,PU_Desc,PUG_Desc
 	  	 Else
 	  	  	 Select [Key] =  pug.PUG_Id,[Production Line] = pl_Desc,[Production Unit] = pu.PU_Desc,[Production Group] = pug.PUG_Desc
 	  	  	  	 From PU_Groups pug 
 	  	  	  	 Join Prod_Units pu on pug.PU_Id = pu.PU_Id
 	  	  	  	 Join Prod_Lines pl on pl.Pl_Id = pu.Pl_Id
 	  	  	  	 Where PUG_Desc Like @SearchString And pug.PUG_Id Not IN (Select Actual_Id From Data_Source_Xref  	 Where Table_Id = @TableId and DS_Id = @DS_Id and Actual_Id is not null and subscription_Id = @SubScriptionId)
 	  	  	  	 And pug.PUG_Id > 0
 	  	  	  	 Order by pl_Desc,PU_Desc,PUG_Desc
 	 Else If @TableId = 21  -- 'Product Families'
 	  	 If @SubScriptionId is null
 	  	  	 Select [Key] = pf.Product_Family_Id,[Product Family] = pf.Product_Family_Desc
 	  	  	  	 From Product_Family pf
 	  	  	  	 Where Product_Family_Desc Like @SearchString And pf.Product_Family_Id Not IN (Select Actual_Id From Data_Source_Xref  	 Where Table_Id = @TableId and DS_Id = @DS_Id and Actual_Id is not null and subscription_Id Is Null)
 	  	  	  	 Order by Product_Family_Desc
 	  	 Else
 	  	  	 Select [Key] = pf.Product_Family_Id,[Product Family] = pf.Product_Family_Desc
 	  	  	  	 From Product_Family pf
 	  	  	  	 Where Product_Family_Desc Like @SearchString And pf.Product_Family_Id Not IN (Select Actual_Id From Data_Source_Xref  	 Where Table_Id = @TableId and DS_Id = @DS_Id and Actual_Id is not null and subscription_Id = @SubScriptionId)
 	  	  	  	 Order by Product_Family_Desc
 	 Else If @TableId = 22  -- 'Product Groups'
 	  	 If @SubScriptionId is null
 	  	  	 Select [Key] = p.Product_Grp_Id,[Product Group] = Product_Grp_Desc
 	  	  	  	 From Product_Groups p
 	  	  	  	 Where Product_Grp_Desc Like @SearchString And p.Product_Grp_Id Not IN (Select Actual_Id From Data_Source_Xref  	 Where Table_Id = @TableId and DS_Id = @DS_Id and Actual_Id is not null and subscription_Id Is Null)
 	  	  	  	 Order by Product_Grp_Desc
 	  	 Else
 	  	  	 Select [Key] = p.Product_Grp_Id,[Product Group] = Product_Grp_Desc
 	  	  	  	 From Product_Groups p
 	  	  	  	 Where Product_Grp_Desc Like @SearchString And p.Product_Grp_Id Not IN (Select Actual_Id From Data_Source_Xref  	 Where Table_Id = @TableId and DS_Id = @DS_Id and Actual_Id is not null and subscription_Id = @SubScriptionId)
 	  	  	  	 Order by Product_Grp_Desc
 	 Else If @TableId = 13  -- 'Production Execution Paths'
 	  	 If @SubScriptionId is null
 	  	  	 Select [Key] = p.Path_Id,[Path] = Path_Desc
 	  	  	  	 From Prdexec_Paths p 
 	  	  	  	 Where Path_Desc Like @SearchString And p.Path_Id Not IN (Select Actual_Id From Data_Source_Xref  	 Where Table_Id = @TableId and DS_Id = @DS_Id and Actual_Id is not null and subscription_Id Is Null)
 	  	  	  	 Order by Path_Desc
 	  	 Else
 	  	  	 Select [Key] = p.Path_Id,[Path] = Path_Desc
 	  	  	  	 From Prdexec_Paths p 
 	  	  	  	 Where Path_Desc Like @SearchString And p.Path_Id Not IN (Select Actual_Id From Data_Source_Xref  	 Where Table_Id = @TableId and DS_Id = @DS_Id and Actual_Id is not null and subscription_Id = @SubScriptionId)
 	  	  	  	 Order by Path_Desc
 	 Else If @TableId = 24  -- 'Reasons'
 	  	 If @SubScriptionId is null
 	  	  	 Select [Key] = e.Event_Reason_Id,[Reason] = Event_Reason_Name
 	  	  	  	 From Event_Reasons e
 	  	  	  	 Where Event_Reason_Name Like @SearchString And e.Event_Reason_Id Not IN (Select Actual_Id From Data_Source_Xref  	 Where Table_Id = @TableId and DS_Id = @DS_Id and Actual_Id is not null and subscription_Id Is Null)
 	  	  	  	 Order by Event_Reason_Name
 	  	 Else
 	  	  	 Select [Key] = e.Event_Reason_Id,[Reason] = Event_Reason_Name
 	  	  	  	 From Event_Reasons e
 	  	  	  	 Where Event_Reason_Name Like @SearchString And e.Event_Reason_Id Not IN (Select Actual_Id From Data_Source_Xref  	 Where Table_Id = @TableId and DS_Id = @DS_Id and Actual_Id is not null and subscription_Id = @SubScriptionId)
 	  	  	  	 Order by Event_Reason_Name
 	 Else If @TableId = 25  -- 'Reason Categories'
 	  	 If @SubScriptionId is null
 	  	  	 Select [Key] = e.ERC_Id,[Category] = ERC_Desc
  	  	  	  	 From Event_Reason_Catagories e
 	  	  	  	 Where ERC_Desc Like @SearchString And e.ERC_Id Not IN (Select Actual_Id From Data_Source_Xref  	 Where Table_Id = @TableId and DS_Id = @DS_Id and Actual_Id is not null and subscription_Id Is Null)
 	  	  	  	 and e.ERC_Id <> 100
 	  	  	  	 Order by ERC_Desc
 	  	 Else
 	  	  	 Select [Key] = e.ERC_Id,[Category] = ERC_Desc
 	  	  	  	 From Event_Reason_Catagories e
 	  	  	  	 Where ERC_Desc Like @SearchString And e.ERC_Id Not IN (Select Actual_Id From Data_Source_Xref  	 Where Table_Id = @TableId and DS_Id = @DS_Id and Actual_Id is not null and subscription_Id = @SubScriptionId)
 	  	  	  	 and e.ERC_Id <> 100
 	  	  	  	 Order by ERC_Desc
 	 Else If @TableId = 26  -- 'Bill Of Material Formulations'
 	  	 If @SubScriptionId is null
 	  	  	 Select [Key] = BOM_Formulation_Id ,[Formulation] = BOM_Formulation_Desc
 	  	  	  	 From Bill_Of_Material_Formulation b
 	  	  	  	 Where BOM_Formulation_Desc Like @SearchString And b.BOM_Formulation_Id Not IN (Select Actual_Id From Data_Source_Xref  	 Where Table_Id = @TableId and DS_Id = @DS_Id and Actual_Id is not null and subscription_Id Is Null)
 	  	  	  	 Order by BOM_Formulation_Desc
 	  	 Else
 	  	  	 Select [Key] = BOM_Formulation_Id ,[Formulation] = BOM_Formulation_Desc
 	  	  	  	 From Bill_Of_Material_Formulation b
 	  	  	  	 Where BOM_Formulation_Desc Like @SearchString And b.BOM_Formulation_Id Not IN (Select Actual_Id From Data_Source_Xref  	 Where Table_Id = @TableId and DS_Id = @DS_Id and Actual_Id is not null and subscription_Id = @SubScriptionId)
 	  	  	  	 Order by BOM_Formulation_Desc
 	 Else If @TableId = 28  -- 'Bill Of Material Formulation Item'
 	  	 If @SubScriptionId is null
 	  	  	 Select [Key] = BOM_Formulation_Item_Id ,[Formulation] = BOM_Formulation_Desc,[Item] = BOM_Formulation_Order,[Product] = Prod_Code,[Lot Desc] = isnull(Lot_Desc,'')
 	  	  	  	 From Bill_Of_Material_Formulation b
 	  	  	  	 Join Bill_Of_Material_Formulation_Item c on c.BOM_Formulation_Id = b.BOM_Formulation_Id
 	  	  	  	 Join products p on p.Prod_Id = c.Prod_Id
 	  	  	  	 Where BOM_Formulation_Desc Like @SearchString And c.BOM_Formulation_Item_Id Not IN (Select Actual_Id From Data_Source_Xref  	 Where Table_Id = @TableId and DS_Id = @DS_Id and Actual_Id is not null and subscription_Id Is Null)
 	  	  	  	 Order by BOM_Formulation_Desc
 	  	 Else
 	  	  	 Select [Key] = BOM_Formulation_Item_Id ,[Formulation] = BOM_Formulation_Desc,[Product] = Prod_Code,[Lot Desc] = isnull(Lot_Desc,'')
 	  	  	  	 From Bill_Of_Material_Formulation b
 	  	  	  	 Join Bill_Of_Material_Formulation_Item c on c.BOM_Formulation_Id = b.BOM_Formulation_Id
 	  	  	  	 Join products p on p.Prod_Id = c.Prod_Id
 	  	  	  	 Where BOM_Formulation_Desc Like @SearchString And c.BOM_Formulation_Item_Id Not IN (Select Actual_Id From Data_Source_Xref  	 Where Table_Id = @TableId and DS_Id = @DS_Id and Actual_Id is not null and subscription_Id = @SubScriptionId)
 	  	  	  	 Order by BOM_Formulation_Desc
