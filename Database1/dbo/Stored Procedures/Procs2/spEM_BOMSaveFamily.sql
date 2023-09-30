CREATE PROCEDURE dbo.spEM_BOMSaveFamily
 	 @Group int,
 	 @Comment int,
 	 @Desc nvarchar(50),
 	 @Id int output
AS
 	 declare @commentid int
 	 declare @bomid int
 	 declare @err int
 	 if @Desc=''
 	 begin
 	  	 select @commentid=Comment_Id from Bill_Of_Material_Family where BOM_Family_Id=@Id
 	  	 set @bomid=0
 	  	 while @bomid is not null
 	  	 begin
 	  	  	 set @bomid=null
 	  	  	 select top 1 @bomid=BOM_Id from Bill_Of_Material where BOM_Family_Id=@Id
 	  	  	 if @bomid is not null exec @err=dbo.spEM_BOMSave null,null,null,null,'',@bomid
 	  	  	 if @err<>0 return @err
 	  	 end
 	  	 delete from Bill_Of_Material_Family where BOM_Family_Id=@Id
 	  	 delete from Comments where Comment_Id=@commentid
 	 end
 	 else if @Id is null
 	 begin
 	  	 insert into Bill_Of_Material_Family (Group_Id,Comment_Id,BOM_Family_Desc) values (@Group,@Comment,@Desc)
 	  	 set @Id=scope_identity()
 	 end
 	 else
 	  	 update Bill_Of_Material_Family set Group_Id=@Group,Comment_Id=@Comment,BOM_Family_Desc=@Desc where BOM_Family_Id=@Id
