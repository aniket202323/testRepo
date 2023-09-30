--  spEM_BOMPopulateDialogs 12
CREATE PROCEDURE dbo.spEM_BOMPopulateDialogs
@key int
AS
--products
select 
 	 p.Prod_Id,p.Prod_Code,p.Prod_Desc
from 
 	 Bill_Of_Material_Formulation bomf
 	 inner join Bill_Of_Material_Product bomp on bomf.BOM_Formulation_Id=bomp.BOM_Formulation_Id
 	 inner join Products p on bomp.Prod_Id=p.Prod_Id 
where bomf.BOM_Formulation_Id=@key
--extendedattributes
select 
 	 tf.Table_Field_Desc,
 	 tfv.[Value]
from 
 	 Table_Fields_Values tfv 
 	 inner join Tables tb on tfv.TableId=tb.TableId
 	 inner join Table_Fields tf on tfv.Table_Field_Id=tf.Table_Field_Id
where 
 	 tfv.KeyId=@key
 	 and tb.TableName='Bill_Of_Material_Formulation'
--xref
select 
 	 ds.DS_Desc,
 	 xr.Foreign_Key
from 
 	 Data_Source_XRef xr
 	 inner join Tables tb on xr.Table_Id=tb.TableId
 	 inner join Data_Source ds on xr.DS_Id=ds.DS_Id 	 
where 
 	 xr.Actual_Id=@key
 	 and tb.TableName='Bill_Of_Material_Formulation'
--items
select
 	 bomfi.BOM_Formulation_Item_Id,
 	 p.Prod_Code,
 	 bomfi.Quantity,
 	 eu.Eng_Unit_Desc,
 	 bomfi.Scrap_Factor
from
 	 Bill_Of_Material_Formulation_Item bomfi
 	 inner join Engineering_Unit eu on eu.Eng_Unit_Id = bomfi.Eng_Unit_Id
 	 inner join Products p on bomfi.Prod_Id=p.Prod_Id
where
 	 bomfi.BOM_Formulation_Id=@key
order by
 	 bomfi.BOM_Formulation_Order
