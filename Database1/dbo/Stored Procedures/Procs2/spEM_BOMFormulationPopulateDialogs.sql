--  spEM_BOMFormulationPopulateDialogs 12
CREATE PROCEDURE dbo.spEM_BOMFormulationPopulateDialogs
@key int
AS
--base info
Select
 	 BOM_Formulation_Id,BOM_Id,BOM_Formulation_Desc,Effective_Date,Expiration_Date,Standard_Quantity,Eng_Unit_Desc,Comments.Comment,bomf.Quantity_Precision
From 
 	 Bill_Of_Material_Formulation bomf
 	 Join Engineering_Unit eu on eu.Eng_Unit_Id = bomf.Eng_Unit_Id
 	 left join Comments on bomf.Comment_Id=Comments.Comment_Id
where bomf.BOM_Formulation_Id=@key
Order by BOM_Formulation_Desc
--products
select 
 	 p.Prod_Id,p.Prod_Code,p.Prod_Desc,bomp.PU_Id,pu.PU_Desc
from 
 	 Bill_Of_Material_Formulation bomf
 	 inner join Bill_Of_Material_Product bomp on bomf.BOM_Formulation_Id=bomp.BOM_Formulation_Id
 	 inner join Products p on bomp.Prod_Id=p.Prod_Id 
 	 left join Prod_Units pu on bomp.PU_Id=pu.PU_Id
where bomf.BOM_Formulation_Id=@key 
order by p.Prod_Code,bomp.PU_Id
--paths
select 
 	 pp.PP_Id,p.Path_Code,pp.Process_Order
from 
 	 Production_Plan pp 
 	 inner join Prdexec_Paths p on pp.Path_Id=p.Path_Id
where 
 	 pp.BOM_Formulation_Id=@key
--extendedattributes
select 
 	 tf.Table_Field_Id,
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
 	 xr.DS_XRef_Id,
 	 ds.DS_Desc,
 	 xr.Foreign_Key,
 	 xr.Actual_Text
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
 	 bomfi.Scrap_Factor,
 	 bomfi.Lot_Desc,
 	 bomfi.PU_Id,
 	 bomfi.Location_Id,
 	 bomfi.Alias,
 	 pu.PU_Desc,
 	 ul.Location_Code
from
 	 Bill_Of_Material_Formulation_Item bomfi
 	 inner join Engineering_Unit eu on eu.Eng_Unit_Id = bomfi.Eng_Unit_Id
 	 inner join Products p on bomfi.Prod_Id=p.Prod_Id
 	 left join Prod_Units pu on bomfi.PU_Id=pu.PU_Id
 	 left join Unit_Locations ul on bomfi.Location_Id=ul.Location_Id
where
 	 bomfi.BOM_Formulation_Id=@key
order by
 	 bomfi.BOM_Formulation_Order
