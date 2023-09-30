--  spEM_BOMFormulationPopulateDialogs 12
CREATE PROCEDURE dbo.spEM_BOMFormulationItemPopulateDialogs
@key int
AS
--basic stuff
select 
 	 bomfi.Lower_Tolerance,pu.PU_Id,pu.PU_Desc,ul.Location_Id,ul.Location_Code,c.Comment,bomfi.Upper_Tolerance,bomfi.Use_Event_Components,bomfi.LTolerance_Precision,bomfi.Quantity_Precision,bomfi.UTolerance_Precision
from 
 	 Bill_Of_Material_Formulation_Item bomfi
 	 left join Prod_Units pu on bomfi.PU_Id=pu.PU_Id
 	 left join Unit_Locations ul on bomfi.Location_Id=ul.Location_Id
 	 left join Comments c on bomfi.Comment_Id=c.Comment_Id
where bomfi.BOM_Formulation_Item_Id=@key
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
 	 and tb.TableName='Bill_Of_Material_Formulation_Item'
--xref
select
 	 xr.DS_XRef_Id, 
 	 ds.DS_Desc,
 	 xr.Foreign_Key
from 
 	 Data_Source_XRef xr
 	 inner join Tables tb on xr.Table_Id=tb.TableId
 	 inner join Data_Source ds on xr.DS_Id=ds.DS_Id 	 
where 
 	 xr.Actual_Id=@key
 	 and tb.TableName='Bill_Of_Material_Formulation_Item'
--subst
select 
 	 p.Prod_Code,p.Prod_Id,boms.Conversion_Factor,eu.Eng_Unit_Desc,eu.Eng_Unit_Id,boms.BOM_Substitution_Id
from
 	 Bill_Of_Material_Substitution boms
 	 inner join Engineering_Unit eu on boms.Eng_Unit_Id=eu.Eng_Unit_Id
 	 inner join Products p on boms.Prod_Id=p.Prod_Id
where
 	 boms.BOM_Formulation_Item_Id=@key
order by
 	 boms.BOM_Substitution_Order
