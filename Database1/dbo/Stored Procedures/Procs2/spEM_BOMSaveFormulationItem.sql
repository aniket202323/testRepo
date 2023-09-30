CREATE PROCEDURE dbo.spEM_BOMSaveFormulationItem
 	 @User int,
 	 @Alias nvarchar(50),
 	 @UseComponents bit,
 	 @Scrap float,
 	 @qty float,
 	 @qtyprec int,
 	 @lowert float,
 	 @uppert float,
 	 @ltprec int,
 	 @utprec int,
 	 @Comment text,
 	 @eu int,
 	 @Unit int,
 	 @Location int,
 	 @Formulation int,
 	 @Lot nvarchar(50),
 	 @Product nVarChar(25),
 	 @Id int output
AS
 	 declare @commentid int
 	 declare @formid int
 	 if @Product is null
 	 begin
 	  	 select @commentid=Comment_Id from Bill_Of_Material_Formulation_Item where BOM_Formulation_Item_Id in (@Formulation,@Id)
 	  	 delete from Bill_Of_Material_Substitution where BOM_Formulation_Item_Id in (@Formulation,@Id)
 	  	 delete from Bill_Of_Material_Formulation_Item where BOM_Formulation_Item_Id in (@Formulation,@Id)
 	  	 delete Comments where Comment_Id=@commentid
 	  	 delete from xr from Data_Source_XRef xr inner join Tables t on xr.Table_Id=t.TableId where t.TableName='Bill_Of_Material_Formulation_Item' and xr.Actual_Id in (@Formulation,@Id)
 	 end
 	 else if @Id is null
 	 begin
 	  	 insert into Bill_Of_Material_Formulation_Item 
 	  	  	 (Alias,Use_Event_Components,Scrap_Factor,Quantity,Lower_Tolerance,Upper_Tolerance,BOM_Formulation_Order,Eng_Unit_Id,PU_Id,Location_Id,BOM_Formulation_Id,Prod_Id,Lot_Desc,Quantity_Precision,LTolerance_Precision,UTolerance_Precision) 
 	  	  	 select 
 	  	  	  	 @Alias,isnull(@UseComponents,0),@Scrap,@qty,@lowert,@uppert,isnull(max(BOM_Formulation_Order),0)+1,@eu,@Unit,@Location,@Formulation,(select Prod_Id from Products where Prod_Code=@Product),@Lot,@qtyprec,@ltprec,@utprec
 	  	  	 from Bill_Of_Material_Formulation_Item 
 	  	  	 where BOM_Formulation_Id=@Formulation
 	  	 set @Id=scope_identity()
 	  	 if not @comment is null
 	  	 begin
 	  	  	 exec spEM_CreateComment @id,'fo',@User,3,@commentid out
 	  	  	 update Comments set Comment=@Comment where Comment_Id=@commentid
 	  	 end
 	 end
 	 else
 	 begin
 	  	 update Bill_Of_Material_Formulation_Item set 
 	  	  	 Alias=@Alias,
 	  	  	 Use_Event_Components=case when @UseComponents is null then Use_Event_Components else @UseComponents end,
 	  	  	 Scrap_Factor=@Scrap,
 	  	  	 Quantity=@qty,
 	  	  	 Lower_Tolerance=case when @lowert is null then Lower_Tolerance else @lowert end,
 	  	  	 Upper_Tolerance=case when @uppert is null then Upper_Tolerance else @uppert end,
 	  	  	 Eng_Unit_Id=@eu,
 	  	  	 PU_Id=@Unit,
 	  	  	 Location_Id=@Location,
 	  	  	 Prod_Id=(select Prod_Id from Products where Prod_Code=@Product),
 	  	  	 Lot_Desc=@Lot,
 	  	  	 Quantity_Precision=@qtyprec,
 	  	  	 LTolerance_Precision=@ltprec,
 	  	  	 UTolerance_Precision=@utprec
 	  	 where 
 	  	  	 BOM_Formulation_Item_Id=@Id
 	  	 set @commentid=null
 	  	 select @commentid=Comment_Id from Bill_Of_Material_Formulation_Item where BOM_Formulation_Item_Id=@Id
 	  	 if @commentid is null exec spEM_CreateComment @Id,'fo',@User,3,@commentid out
 	  	 update Comments set Comment=@Comment where Comment_Id=@commentid
 	 end
