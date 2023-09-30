--  spEM_BOMFormulationItemCopy 12
CREATE PROCEDURE dbo.spEM_BOMFormulationItemCopy
@form int,
@key int
AS
declare @newkey int
declare @comment int
declare @table int
--basic stuff
insert into Bill_Of_Material_Formulation_Item 
 	 (Alias,Use_Event_Components,Scrap_Factor,Quantity,Lower_Tolerance,Upper_Tolerance,BOM_Formulation_Order,Eng_Unit_Id,PU_Id,Location_Id,BOM_Formulation_Id,Prod_Id,Lot_Desc,LTolerance_Precision,Quantity_Precision,UTolerance_Precision)
select 
 	 Alias,Use_Event_Components,Scrap_Factor,Quantity,Lower_Tolerance,Upper_Tolerance,BOM_Formulation_Order,Eng_Unit_Id,PU_Id,Location_Id,@form,Prod_Id,Lot_Desc,LTolerance_Precision,Quantity_Precision,UTolerance_Precision
from 
 	 Bill_Of_Material_Formulation_Item 
where 
 	 BOM_Formulation_Item_Id=@key
set @newkey=scope_identity()
insert into Comments
 	 (Modified_On,Entry_On,TopOfChain_Id,NextComment_Id,User_Id,CS_Id,Comment,Comment_Text,ShouldDelete,Extended_Info)
select
 	 Modified_On,Entry_On,TopOfChain_Id,NextComment_Id,User_Id,CS_Id,Comment,Comment_Text,ShouldDelete,Extended_Info
from Comments where Comment_Id=(
select Comment_Id
from 
 	 Bill_Of_Material_Formulation_Item 
where 
 	 BOM_Formulation_Item_Id=@key
)
set @comment=scope_identity()
update Bill_Of_Material_Formulation_Item set Comment_Id=@comment where BOM_Formulation_Item_Id=@newkey
select @table=TableId from Tables where TableName='Bill_Of_Material_Formulation_Item'
--extendedattributes
insert into Table_Fields_Values (KeyId,TableId,Table_Field_Id,[Value])
select 
 	 @newkey,@table,Table_Field_Id,[Value]
from 
 	 Table_Fields_Values 
where 
 	 KeyId=@key
 	 and TableId=@table
--xref
insert into Data_Source_XRef (Actual_Id,DS_Id,Table_Id,Actual_Text,Foreign_Key,Subscription_Id,XML_Header)
select
 	 @newkey,DS_Id,@table,Actual_Text,Foreign_Key,Subscription_Id,XML_Header
from 
 	 Data_Source_XRef 
where 
 	 Actual_Id=@key
 	 and Table_Id=@table
--substitutions
insert into Bill_Of_Material_Substitution (BOM_Formulation_Item_Id,Prod_Id,Eng_Unit_Id,Conversion_Factor,BOM_Substitution_Order) 
select 
 	 @newkey,Prod_Id,Eng_Unit_Id,Conversion_Factor,BOM_Substitution_Order
from
 	 Bill_Of_Material_Substitution 
where
 	 BOM_Formulation_Item_Id=@key
