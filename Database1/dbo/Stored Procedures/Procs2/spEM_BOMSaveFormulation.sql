CREATE PROCEDURE dbo.spEM_BOMSaveFormulation
 	 @BOM int,
 	 @efdate datetime,
 	 @exdate datetime,
 	 @qty float,
 	 @qtyprec int,
 	 @eu int,
 	 @Comment text,
 	 @Master int,
 	 @User int,
 	 @Desc nvarchar(50),
 	 @Id int output
AS
 	 declare @commentid int
 	 declare @formid int
 	 declare @formitemid int
 	 declare @err int
 	 if @Desc=''
 	 begin
 	  	 if @Master is not null
 	  	 begin
 	  	  	 set @formid=0
 	  	  	 while @formid is not null
 	  	  	 begin
 	  	  	  	 set @formid=null
 	  	  	  	 select top 1 @formid=BOM_Formulation_Id from Bill_Of_Material_Formulation where Master_BOM_Formulation_Id=@id
 	  	  	  	 if @formid is not null exec @err=dbo.spEM_BOMSaveFormulation null,null,null,null,null,null,null,null,@User,'',@formid
 	  	  	  	 if @err<>0 return @err
 	  	  	 end
 	  	 end
 	  	 select @commentid=Comment_Id from Bill_Of_Material_Formulation where BOM_Formulation_Id=@Id
 	  	 while exists(select top 1 BOM_Formulation_Item_Id from Bill_Of_Material_Formulation_Item where BOM_Formulation_Id=@Id)
 	  	 begin
 	  	  	 set @formitemid=0
 	  	  	 select top 1 @formitemid=BOM_Formulation_Item_Id from Bill_Of_Material_Formulation_Item where BOM_Formulation_Id=@Id
 	  	  	 exec @err=spEM_BOMSaveFormulationItem null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,@formitemid
 	  	  	 if @err<>0 return @err
 	  	 end
 	  	 delete from Bill_Of_Material_Product where BOM_Formulation_Id=@Id
 	  	 update Production_Plan set BOM_Formulation_Id=null where BOM_Formulation_Id=@Id
 	  	 delete from Bill_Of_Material_Formulation where BOM_Formulation_Id=@Id
 	  	 delete from xr from Data_Source_XRef xr inner join Tables t on xr.Table_Id=t.TableId where t.TableName='Bill_Of_Material_Formulation' and xr.Actual_Id=@Id
 	  	 delete Comments where Comment_Id=@commentid
 	 end
 	 else if @Id is null
 	 begin
 	  	 insert into Bill_Of_Material_Formulation (BOM_Id,Effective_Date,Expiration_Date,Standard_Quantity,Eng_Unit_Id,Comment_Id,Master_BOM_Formulation_Id,BOM_Formulation_Desc,Quantity_Precision) values (@BOM,@efdate,@exdate,@qty,@eu,null,@Master,@Desc,@qtyprec)
 	  	 set @Id=scope_identity()
 	  	 if not @Comment is null
 	  	 begin
 	  	  	 exec spEM_CreateComment @id,'fn',@User,3,@commentid out
 	  	  	 update Comments set Comment=@Comment where Comment_Id=@commentid
 	  	 end
 	  	 if not @Master is null
 	  	 begin
 	  	  	 declare @item int
 	  	  	 declare c cursor fast_forward for select BOM_Formulation_Item_Id from Bill_Of_Material_Formulation_Item where BOM_Formulation_Id=@Master
 	  	  	 open c
 	  	  	 fetch next from c into @item
 	  	  	 while @@fetch_status=0
 	  	  	 begin
 	  	  	  	 exec spEM_BOMFormulationItemCopy @Id,@item
 	  	  	  	 fetch next from c into @item
 	  	  	 end
 	  	  	 close c
 	  	  	 deallocate c
 	  	 end
 	 end
 	 else
 	 BEGIN
 	  	 update Bill_Of_Material_Formulation set Quantity_Precision=@qtyprec,Effective_Date=@efdate,Expiration_Date=@exdate,Standard_Quantity=@qty,Eng_Unit_Id=@eu,Master_BOM_Formulation_Id=@Master,BOM_Formulation_Desc=@Desc where BOM_Formulation_Id=@Id
 	  	 select @commentid=Comment_Id from Bill_Of_Material_Formulation where BOM_Formulation_Id=@Id
 	  	 IF @commentid Is Null
 	  	 BEGIN
 	  	  	 if not @Comment is null
 	  	  	 begin
 	  	  	  	 exec spEM_CreateComment @id,'fn',@User,3,@commentid out
 	  	  	  	 update Comments set Comment=@Comment where Comment_Id=@commentid
 	  	  	 end
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 update Comments set Comment=@Comment where Comment_Id=@commentid
 	  	 END
 	 END
