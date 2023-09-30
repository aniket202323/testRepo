CREATE PROCEDURE dbo.spEM_XrefAddNewEMail
 	 @TableId  	  	  	  	  	 Int,
 	 @EG_Id 	  	  	  	  	  	 Int,
 	 @SearchString 	  	  	 nVarChar(100)
  AS
 	 Select @SearchString = '%' + @SearchString + '%'
 	 If @TableId = 17  --'Departments'
 	  	  	 Select [Key] = Dept_Id, [Department] = d.Dept_Desc 
 	  	  	  	 From Departments d 
 	  	  	  	 Where Dept_Desc Like @SearchString And Dept_Id Not In (Select Key_Id From Email_Group_Xref  	 Where Table_Id = @TableId and EG_Id = @EG_Id)
 	  	  	  	 Order by Dept_Desc
 	 Else If @TableId = 18  -- 'Production Lines'
 	  	  	 Select [Key] = pl.Pl_Id,[Production Line] = pl_Desc
 	  	  	  	 From Prod_Lines pl 
 	  	  	  	 Where pl_Desc Like @SearchString And pl.Pl_Id Not IN (Select Key_Id From Email_Group_Xref  	 Where Table_Id = @TableId and EG_Id = @EG_Id)
 	  	  	  	 And pl.Pl_Id > 0
 	  	  	  	 Order by pl_Desc
 	 Else If @TableId = 19  -- 'Variable Groups'
 	  	  	 Select [Key] =  pug.PUG_Id,[Production Line] = pl_Desc,[Production Unit] = pu.PU_Desc,[Production Group] = pug.PUG_Desc
 	  	  	  	 From PU_Groups pug 
 	  	  	  	 Join Prod_Units pu on pug.PU_Id = pu.PU_Id
 	  	  	  	 Join Prod_Lines pl on pl.Pl_Id = pu.Pl_Id
 	  	  	  	 Where PUG_Desc Like @SearchString And pug.PUG_Id Not IN (Select Key_Id From Email_Group_Xref  	 Where Table_Id = @TableId and EG_Id = @EG_Id)
 	  	  	  	 And pug.PUG_Id > 0
 	  	  	  	 Order by pl_Desc,PU_Desc,PUG_Desc
 	 Else If @TableId = 21  -- 'Product Families'
 	  	  	 Select [Key] = pf.Product_Family_Id,[Product Family] = pf.Product_Family_Desc
 	  	  	  	 From Product_Family pf
 	  	  	  	 Where Product_Family_Desc Like @SearchString And pf.Product_Family_Id Not IN (Select Key_Id From Email_Group_Xref  	 Where Table_Id = @TableId and EG_Id = @EG_Id)
 	  	  	  	 Order by Product_Family_Desc
 	 Else If @TableId = 22  -- 'Product Groups'
 	  	  	 Select [Key] = p.Product_Grp_Id,[Product Group] = Product_Grp_Desc
 	  	  	  	 From Product_Groups p
 	  	  	  	 Where Product_Grp_Desc Like @SearchString And p.Product_Grp_Id Not IN (Select Key_Id From Email_Group_Xref  	 Where Table_Id = @TableId and EG_Id = @EG_Id)
 	  	  	  	 Order by Product_Grp_Desc
