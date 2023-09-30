--  spEM_BOMFormulationItemCopy 12
CREATE PROCEDURE dbo.spEM_BOMDeriveFormulation
@form int,
@newname nvarchar(50),
@newkey int out
AS
declare @comment int
declare @table int
set nocount on
--basic stuff
insert into Bill_Of_Material_Formulation
 	 (Effective_Date,Expiration_Date,Standard_Quantity,Eng_Unit_Id,Master_BOM_Formulation_Id,BOM_Id,BOM_Formulation_Desc,Quantity_Precision)
select 
 	 Effective_Date,Expiration_Date,Standard_Quantity,Eng_Unit_Id,@form,BOM_Id,@newname,Quantity_Precision
from 
 	 Bill_Of_Material_Formulation
where 
 	 BOM_Formulation_Id=@form
set @newkey=scope_identity()
insert into Comments
 	 (Modified_On,Entry_On,TopOfChain_Id,NextComment_Id,User_Id,CS_Id,Comment,Comment_Text,ShouldDelete,Extended_Info)
select
 	 Modified_On,Entry_On,TopOfChain_Id,NextComment_Id,User_Id,CS_Id,Comment,Comment_Text,ShouldDelete,Extended_Info
from Comments where Comment_Id=(
select Comment_Id
from 
 	 Bill_Of_Material_Formulation
where 
 	 BOM_Formulation_Id=@form
)
set @comment=scope_identity()
update Bill_Of_Material_Formulation set Comment_Id=@comment where BOM_Formulation_Id=@newkey
--products
insert into Bill_Of_Material_Product (Prod_Id,BOM_Formulation_Id) select Prod_Id,@newkey from Bill_Of_Material_Product where BOM_Formulation_Id=@form
select @table=TableId from Tables where TableName='Bill_Of_Material_Formulation'
--extendedattributes
insert into Table_Fields_Values (KeyId,TableId,Table_Field_Id,[Value])
select 
 	 @newkey,@table,Table_Field_Id,[Value]
from 
 	 Table_Fields_Values 
where 
 	 KeyId=@form
 	 and TableId=@table
--xref
insert into Data_Source_XRef (Actual_Id,DS_Id,Table_Id,Actual_Text,Foreign_Key,Subscription_Id,XML_Header)
select
 	 @newkey,DS_Id,@table,Actual_Text,Foreign_Key,Subscription_Id,XML_Header
from 
 	 Data_Source_XRef 
where 
 	 Actual_Id=@form
 	 and Table_Id=@table
--copy items
declare c cursor for
select BOM_Formulation_Item_Id from Bill_Of_Material_Formulation_Item where BOM_Formulation_Id=@form
open c
fetch next from c into @form
while @@fetch_status=0
begin
 	 exec spEM_BOMFormulationItemCopy @newkey,@form
 	 fetch next from c into @form
end
close c
deallocate c
