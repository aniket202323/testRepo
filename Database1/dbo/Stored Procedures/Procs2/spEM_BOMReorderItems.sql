CREATE PROCEDURE dbo.spEM_BOMReorderItems
@idlist varchar(8000)
AS
 	 Declare @items table (id int,ord int)
 	 declare @i int
 	 set @i=1
 	 if @idlist is not null
 	 begin
 	  	 WHILE CHARINDEX(' ',@idlist)>0
 	  	 BEGIN
 	  	  	 WHILE CHARINDEX(' ',@idlist)=1 SET @idlist=SUBSTRING(@idlist,2,8000)
 	  	  	 IF LEN(@idlist)>0 AND CHARINDEX(' ',@idlist)>0
 	  	  	 BEGIN
 	  	  	  	 INSERT INTO @items VALUES (CAST(LEFT(@idlist,CHARINDEX(' ',@idlist)-1) as int),@i)
 	  	  	  	 SET @idlist=SUBSTRING(@idlist,CHARINDEX(' ',@idlist)+1,8000)
 	  	  	 END
 	  	  	 set @i=@i+1
 	  	 END
 	  	 IF LEN(@idlist)>0 INSERT INTO @items VALUES (CAST(@idlist as int),@i)
 	 end
 	 update bomfi set BOM_Formulation_Order=-i.ord from Bill_Of_Material_Formulation_Item bomfi inner join @Items i on bomfi.BOM_Formulation_Item_Id=i.id
 	 update bomfi set BOM_Formulation_Order=i.ord from Bill_Of_Material_Formulation_Item bomfi inner join @Items i on bomfi.BOM_Formulation_Item_Id=i.id
