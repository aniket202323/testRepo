CREATE PROCEDURE dbo.spEM_BOMSave
 	 @Family int,
 	 @Active bit,
 	 @Group int,
 	 @Comment int,
 	 @Desc nvarchar(50),
 	 @Id int output
AS
 	 declare @commentid int
 	 declare @formid int
 	 declare @err int
 	 if @Desc=''
 	 begin
 	  	 select @commentid=Comment_Id from Bill_Of_Material where BOM_Id=@Id
 	  	 set @formid=0
 	  	 while @formid is not null
 	  	 begin
 	  	  	 set @formid=null
 	  	  	 select top 1 @formid=BOM_Formulation_Id from Bill_Of_Material_Formulation where BOM_Id=@Id
 	  	  	 if @formid is not null exec @err=dbo.spEM_BOMSaveFormulation null,null,null,null,null,null,null,@formid,null,'',@formid
 	  	  	 if @err<>0 return @err
 	  	 end
 	  	 delete from Bill_Of_Material where BOM_Id=@Id
 	  	 delete from Comments where Comment_Id=@commentid
 	 end
 	 else if @Id is null
 	 begin
 	  	 insert into Bill_Of_Material (Is_Active,Group_Id,Comment_Id,BOM_Family_Id,BOM_Desc) values (isnull(@Active,1),@Group,@Comment,@Family,@Desc)
 	  	 set @Id=scope_identity()
 	 end
 	 else
 	  	 update Bill_Of_Material set Is_Active=case when @Active is null then Is_Active else @Active end,Group_Id=@Group,Comment_Id=@Comment,BOM_Family_Id=@Family,BOM_Desc=@Desc where BOM_Id=@Id
