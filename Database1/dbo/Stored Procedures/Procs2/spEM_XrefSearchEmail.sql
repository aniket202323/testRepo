CREATE PROCEDURE dbo.spEM_XrefSearchEmail
 	 @TableId Int,
 	 @EG_Id 	 Int
  AS
 	 If @TableId = 17  --'Departments'
 	  	  	 Select  EG_XRef_Id,[Department] = d.Dept_Desc
 	  	  	  	 From Email_Group_Xref  x
 	  	  	  	 Left Join Departments d on d.Dept_Id = x.Key_id
 	  	  	  	 Where x.Table_Id = 17 and x.EG_Id = @EG_Id  
 	  	  	  	 Order by Department
 	 Else If @TableId = 43  -- 'Production Units'
 	  	  	 Select EG_XRef_Id,[Production Line] = pl_Desc,[Production Unit] = pu.PU_Desc
 	  	  	  	 From Email_Group_Xref  x
 	  	  	  	 Left Join Prod_Units pu on pu.PU_Id = x.Key_id
 	  	  	  	 Left Join Prod_Lines pl on pl.Pl_Id = pu.Pl_Id
 	  	  	  	 Where x.Table_Id = @TableId and x.EG_Id = @EG_Id
 	  	  	  	 Order by pl_Desc,PU_Desc
 	 Else If @TableId = 18  -- 'Production Lines'
 	  	  	 Select EG_XRef_Id,[Production Line] = pl_Desc 
 	  	  	  	 From Email_Group_Xref  x
 	  	  	  	 Left Join Prod_Lines pl on pl.Pl_Id = x.Key_id
 	  	  	  	 Where x.Table_Id = @TableId and x.EG_Id = @EG_Id
 	  	  	  	 Order by pl_Desc
 	 Else If @TableId = 19  -- 'Variable Groups'
 	  	  	 Select EG_XRef_Id,[Production Line] = pl_Desc,[Production Unit] = pu.PU_Desc,[Production Group] = pug.PUG_Desc
 	  	  	  	 From Email_Group_Xref  x
 	  	  	  	 Left Join PU_Groups pug on pug.PUG_Id = x.Key_id
 	  	  	  	 Left Join Prod_Units pu on pug.PU_Id = pu.PU_Id
 	  	  	  	 Left Join Prod_Lines pl on pl.Pl_Id = pu.Pl_Id
 	  	  	  	 Where x.Table_Id = @TableId and x.EG_Id = @EG_Id
 	  	  	  	 Order by pl_Desc,PU_Desc,PUG_Desc
 	 Else If @TableId = 21  -- 'Product Families'
 	  	  	 Select EG_XRef_Id,[Product Family] = pf.Product_Family_Desc
 	  	  	  	 From Email_Group_Xref  x 
 	  	  	  	 Left Join Product_Family pf on pf.Product_Family_Id = x.Key_id
 	  	  	  	 Where x.Table_Id = @TableId and x.EG_Id = @EG_Id
 	  	  	  	 Order by Product_Family_Desc
 	 Else If @TableId = 22  -- 'Product Groups'
 	  	  	 Select EG_XRef_Id,[Product Group] = Product_Grp_Desc
 	  	  	  	 From Email_Group_Xref  x
 	  	  	  	 Left Join Product_Groups p on p.Product_Grp_Id = x.Key_id
 	  	  	  	 Where x.Table_Id = @TableId and x.EG_Id = @EG_Id 
 	  	  	  	 Order by Product_Grp_Desc
 	 Else If @TableId = 23  -- 'Products'
 	  	  	 Select EG_XRef_Id,[Product Code] = Prod_Code
 	  	  	  	 From Email_Group_Xref  x
 	  	  	  	 Left Join Products p on p.Prod_Id = x.Key_id
 	  	  	  	 Where x.Table_Id = @TableId and x.EG_Id = @EG_Id
